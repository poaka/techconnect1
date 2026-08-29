const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');
const DispatchService = require('./dispatch.service');

class RequestsService {
  /**
   * Helper to format request and extract attached image URL if present
   */
  static _formatRequestResponse(req) {
    if (!req) return req;
    let description = req.description || '';
    let imageUrl = null;

    const match = description.match(/\[IMAGE_ATTACHMENT:(.*?)\]/);
    if (match) {
      imageUrl = match[1];
      description = description.replace(/\[IMAGE_ATTACHMENT:.*?\]/, '').trim();
    }

    return {
      ...req,
      description,
      image_url: imageUrl
    };
  }

  /**
   * Phase 6: Create request using Dispatch Engine
   */
  static async createRequest(clientId, { categoryId, cityId, description, address, latitude, longitude }, file = null) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    let imageUrl = null;
    if (file) {
      try {
        const fileExt = file.originalname.split('.').pop();
        const fileName = `${clientId}-${Date.now()}.${fileExt}`;
        
        const { error: uploadError } = await supabase.storage
          .from('requests')
          .upload(fileName, file.buffer, {
            contentType: file.mimetype,
            upsert: false
          });
          
        if (uploadError) {
          console.error('[RequestsService.createRequest] Upload Error:', uploadError);
        } else {
          // Get public URL
          const { data: publicUrlData } = supabase.storage
            .from('requests')
            .getPublicUrl(fileName);
          imageUrl = publicUrlData.publicUrl;
        }
      } catch (err) {
        console.error('[RequestsService.createRequest] File processing error:', err);
      }
    }

    let finalDescription = description || '';
    if (imageUrl) {
      finalDescription = `${finalDescription}\n[IMAGE_ATTACHMENT:${imageUrl}]`;
    }

    // 1. Insert unassigned request
    const { data: newRequest, error: createErr } = await supabase
      .from('service_requests')
      .insert([
        {
          client_id: clientId,
          category_id: categoryId,
          city_id: cityId,
          description: finalDescription,
          address: address || null,
          latitude: latitude || null,
          longitude: longitude || null,
          status: 'unassigned'
        }
      ])
      .select('*')
      .single();

    if (createErr || !newRequest) {
      console.error('[RequestsService.createRequest error]', createErr);
      throw ApiError.internal('Erreur lors de la création de la demande');
    }

    // 2. Dispatch Engine: Find technicians
    const technicians = await DispatchService.findAvailableTechnicians({ categoryId, cityId, limit: 5 });

    if (technicians.length === 0) {
      return this._formatRequestResponse(newRequest); // Request created, but unassigned. Client waits.
    }

    // 3. Create Job Offers (status: 'sent' and rank required by live DB schema)
    const offers = technicians.map((tech, index) => ({
      service_request_id: newRequest.id,
      technician_id: tech.id,
      status: 'sent',
      rank: index + 1  // rank is NOT NULL in live DB; lower = higher priority
    }));

    const { data: insertedOffers, error: offersErr } = await supabase.from('job_offers').insert(offers).select('id');
    console.log(`[RequestsService] Created ${insertedOffers?.length ?? 0} job offers for request ${newRequest.id}`);
    if (offersErr) {
      console.error('[RequestsService job offers insert error]', offersErr);
    }

    // 4. Notify technicians
    try {
      const notifs = technicians.map(tech => ({
        user_id: tech.user_id,
        type: 'request_created',
        title: 'Nouvelle offre de mission !',
        message: 'Une mission correspond à vos critères. Soyez le premier à l\'accepter.',
        metadata: { requestId: newRequest.id }
      }));
      await supabase.from('notifications').insert(notifs);
    } catch (notifErr) {
      console.error('[RequestsService notification insert error]', notifErr);
    }

    return this._formatRequestResponse(newRequest);
  }

  static async getRequests(userId, role, statusFilter = null) {
    if (!supabase) return [];

    let query = supabase
      .from('service_requests')
      .select(`
        id, status, description, address, latitude, longitude, created_at, updated_at, completed_at,
        category:categories(id, name, icon),
        city:cities(id, name),
        client:users!client_id(id, full_name, email, phone, avatar_url),
        assigned_technician:technician_profiles!assigned_technician_id(
          id, user:users!user_id(id, full_name, email, phone, avatar_url)
        ),
        review:reviews(id, rating, comment)
      `)
      .order('created_at', { ascending: false });

    if (role === 'client') {
      query = query.eq('client_id', userId);
    } else if (role === 'technician') {
      const { data: profile } = await supabase
        .from('technician_profiles')
        .select('id')
        .eq('user_id', userId)
        .single();

      if (!profile) return [];
      query = query.eq('assigned_technician_id', profile.id);
    }

    if (statusFilter) {
      query = query.eq('status', statusFilter);
    }

    const { data, error } = await query;

    if (error) {
      console.error('[RequestsService.getRequests error]', error);
      throw ApiError.internal('Erreur lors de la récupération des demandes');
    }

    return (data || []).map(r => this._formatRequestResponse(r));
  }

  static async getRequestById(requestId, userId, role) {
    if (!supabase) throw ApiError.notFound('Demande non trouvée');

    const { data: request, error } = await supabase
      .from('service_requests')
      .select(`
        id, status, description, address, latitude, longitude, created_at, updated_at, completed_at,
        client_id, assigned_technician_id,
        category:categories(id, name, icon),
        city:cities(id, name),
        client:users!client_id(id, full_name, email, phone, avatar_url),
        assigned_technician:technician_profiles!assigned_technician_id(
          id, user_id, user:users!user_id(id, full_name, email, phone, avatar_url)
        ),
        review:reviews(id, rating, comment)
      `)
      .eq('id', requestId)
      .single();

    if (error || !request) {
      throw ApiError.notFound('Demande de service non trouvée');
    }

    // Access control check: clients can only view their own requests
    if (role === 'client' && request.client_id !== userId) {
      throw ApiError.forbidden('Vous n\'avez pas l\'autorisation d\'accéder à cette demande');
    }

    return this._formatRequestResponse(request);
  }

  /**
   * Technician accepts an incoming request (either via existing job offer or directly)
   */
  static async acceptRequest(requestId, technicianUserId) {
    const techId = await this.getTechId(technicianUserId);
    if (!techId) throw ApiError.badRequest('Profil technicien introuvable');

    // 1. Check if there is an existing job offer for this technician
    const { data: offers } = await supabase
      .from('job_offers')
      .select('id, status')
      .eq('service_request_id', requestId)
      .eq('technician_id', techId)
      .limit(1);

    if (offers && offers.length > 0 && offers[0].status === 'sent') {
      const OffersService = require('./offers.service');
      return await OffersService.acceptOffer(offers[0].id, techId);
    }

    // 2. Direct atomic assignment
    const { data: assignedRequest, error: assignErr } = await supabase
      .from('service_requests')
      .update({
        assigned_technician_id: techId,
        status: 'assigned',
        updated_at: new Date().toISOString()
      })
      .eq('id', requestId)
      .is('assigned_technician_id', null)
      .select(`
        id, status, description, address, latitude, longitude, created_at, updated_at,
        category:categories(id, name, icon),
        city:cities(id, name),
        client:users!client_id(id, full_name, email, phone, avatar_url)
      `)
      .single();

    if (assignErr || !assignedRequest) {
      throw ApiError.badRequest('Cette mission a déjà été assignée à un autre technicien ou n\'est plus disponible.');
    }

    // Invalidate competing offers
    await supabase
      .from('job_offers')
      .update({ status: 'expired' })
      .eq('service_request_id', requestId)
      .eq('status', 'sent');

    // Notify client
    try {
      if (assignedRequest.client_id) {
        await supabase.from('notifications').insert([{
          user_id: assignedRequest.client_id,
          type: 'request_status_change',
          title: 'Artisan assigné !',
          message: 'Un artisan qualifié a accepté votre demande.',
          metadata: { requestId }
        }]);
      }
    } catch (notifErr) {
      console.error('[RequestsService.acceptRequest] Notification error:', notifErr);
    }

    return {
      message: 'Mission acceptée avec succès',
      request: this._formatRequestResponse(assignedRequest)
    };
  }

  static async cancelRequest(requestId, clientId) {
    const request = await this.getRequestById(requestId, clientId, 'client');
    
    if (request.status === 'completed' || request.status === 'cancelled') {
      throw ApiError.badRequest('Cette demande ne peut plus être annulée');
    }

    const { data, error } = await supabase
      .from('service_requests')
      .update({ status: 'cancelled', updated_at: new Date().toISOString() })
      .eq('id', requestId)
      .select()
      .single();

    if (error) throw ApiError.internal('Erreur lors de l\'annulation');

    // Invalidate any pending/sent offers
    await supabase.from('job_offers').update({ status: 'expired' }).eq('service_request_id', requestId).eq('status', 'sent');

    // Notify assigned tech if any
    if (request.assigned_technician_id) {
       await supabase.from('notifications').insert([{
         user_id: request.assigned_technician.user_id,
         type: 'request_status_change',
         title: 'Demande annulée',
         message: 'Le client a annulé la demande de service.',
         metadata: { requestId }
       }]);
    }

    return this._formatRequestResponse(data);
  }

  static async updateRequest(requestId, clientId, { categoryId, cityId, description, address }, file = null) {
    const request = await this.getRequestById(requestId, clientId, 'client');

    // Allow edit on 'unassigned' and 'pending' (legacy live DB status = same as unassigned)
    if (request.status !== 'unassigned' && request.status !== 'pending') {
      throw ApiError.badRequest('Vous ne pouvez modifier que les demandes non encore assignées.');
    }

    // Handle image upload if a new image is provided
    let newImageUrl = null;
    if (file) {
      try {
        const fileExt = file.originalname.split('.').pop();
        const fileName = `${clientId}-${Date.now()}.${fileExt}`;
        const { error: uploadError } = await supabase.storage
          .from('requests')
          .upload(fileName, file.buffer, { contentType: file.mimetype, upsert: false });
        if (!uploadError) {
          const { data: publicUrlData } = supabase.storage.from('requests').getPublicUrl(fileName);
          newImageUrl = publicUrlData.publicUrl;
        } else {
          console.error('[RequestsService.updateRequest] Image upload error:', uploadError);
        }
      } catch (err) {
        console.error('[RequestsService.updateRequest] Image processing error:', err);
      }
    }

    // Determine final description with image attachment
    const baseDesc = description !== undefined ? description : request.description;
    const finalImage = newImageUrl || request.image_url;
    let finalDescription = baseDesc;
    if (finalImage) {
      finalDescription = `${baseDesc}\n[IMAGE_ATTACHMENT:${finalImage}]`;
    }

    const updateData = { updated_at: new Date().toISOString() };
    if (categoryId) updateData.category_id = categoryId;
    if (cityId) updateData.city_id = cityId;
    if (description !== undefined || newImageUrl !== null) updateData.description = finalDescription;
    if (address !== undefined) updateData.address = address;

    const { data, error } = await supabase
      .from('service_requests')
      .update(updateData)
      .eq('id', requestId)
      .eq('client_id', clientId)
      .select(`
        id, status, description, address, latitude, longitude, created_at, updated_at,
        category:categories(id, name, icon),
        city:cities(id, name),
        client:users!client_id(id, full_name, email, phone, avatar_url)
      `)
      .single();

    if (error) {
      console.error('[RequestsService.updateRequest error]', error);
      throw ApiError.internal('Erreur lors de la modification de la demande');
    }

    return this._formatRequestResponse(data);
  }

  static async deleteRequest(requestId, clientId) {
    const request = await this.getRequestById(requestId, clientId, 'client');
    
    if (request.status === 'in_progress' || request.status === 'completed') {
      throw ApiError.badRequest('Impossible de supprimer une demande en cours ou terminée.');
    }

    // Delete associated offers first
    await supabase.from('job_offers').delete().eq('service_request_id', requestId);

    // Delete the service request
    const { error } = await supabase
      .from('service_requests')
      .delete()
      .eq('id', requestId)
      .eq('client_id', clientId);

    if (error) throw ApiError.internal('Erreur lors de la suppression de la demande');
    return { success: true, message: 'Demande supprimée avec succès' };
  }

  static async startRequest(requestId, technicianUserId) {
    const request = await this.getRequestById(requestId, technicianUserId, 'technician');

    if (request.status !== 'assigned') {
      throw ApiError.badRequest('La demande doit être assignée avant de pouvoir être démarrée');
    }

    if (request.assigned_technician?.user_id !== technicianUserId) {
      throw ApiError.forbidden('Vous n\'êtes pas le technicien assigné à cette mission');
    }

    const { data, error } = await supabase
      .from('service_requests')
      .update({ status: 'in_progress', updated_at: new Date().toISOString() })
      .eq('id', requestId)
      .select()
      .single();

    if (error) throw ApiError.internal('Erreur lors du démarrage de la mission');

    // Notify client
    try {
      await supabase.from('notifications').insert([{
        user_id: request.client_id,
        type: 'request_status_change',
        title: 'Mission en cours',
        message: 'Le technicien a démarré l\'intervention. Vous pouvez suivre sa position.',
        metadata: { requestId }
      }]);
    } catch (notifErr) {
      console.error('[RequestsService.startRequest] Notification error:', notifErr);
    }

    return this._formatRequestResponse(data);
  }

  static async completeRequest(requestId, technicianUserId) {
    const request = await this.getRequestById(requestId, technicianUserId, 'technician');
    
    if (request.status !== 'in_progress' && request.status !== 'assigned') {
      throw ApiError.badRequest('La demande doit être en cours pour être terminée');
    }

    const { data, error } = await supabase
      .from('service_requests')
      .update({ status: 'completed', completed_at: new Date().toISOString() })
      .eq('id', requestId)
      .select()
      .single();

    if (error) throw ApiError.internal('Erreur lors de la complétion');

    // Notify client
    await supabase.from('notifications').insert([{
      user_id: request.client_id,
      type: 'request_status_change',
      title: 'Mission terminée',
      message: 'Le technicien a marqué la mission comme terminée. Vous pouvez maintenant laisser un avis.',
      metadata: { requestId }
    }]);

    return this._formatRequestResponse(data);
  }

  static async updateLocation(requestId, technicianUserId, latitude, longitude) {
    const request = await this.getRequestById(requestId, technicianUserId, 'technician');
    
    if (request.status !== 'in_progress' && request.status !== 'assigned') {
      throw ApiError.badRequest('La géolocalisation n\'est active que pendant la mission');
    }

    if (request.assigned_technician?.user_id !== technicianUserId) {
      throw ApiError.forbidden('Vous n\'êtes pas le technicien assigné à cette mission');
    }

    const { data, error } = await supabase
      .from('location_updates')
      .upsert({
        request_id: requestId,
        technician_id: request.assigned_technician_id,
        latitude,
        longitude,
        updated_at: new Date().toISOString()
      }, { onConflict: 'request_id' })
      .select()
      .single();

    if (error) {
      console.error('[RequestsService updateLocation error]', error);
      throw ApiError.internal('Erreur lors de la mise à jour de la position');
    }

    return data;
  }

  static async getLocation(requestId, userId, role) {
    // getRequestById already verifies access control (Client must be owner, Tech must be assigned/have offer)
    await this.getRequestById(requestId, userId, role);

    const { data, error } = await supabase
      .from('location_updates')
      .select('latitude, longitude, updated_at')
      .eq('request_id', requestId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') return null; // Not found, which is fine if tech hasn't started sending location
      throw ApiError.internal('Erreur lors de la récupération de la position');
    }

    return data;
  }

  static async getTechId(userId) {
    const { data } = await supabase.from('technician_profiles').select('id').eq('user_id', userId).single();
    return data ? data.id : null;
  }
}

module.exports = RequestsService;
