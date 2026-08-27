const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');
const DispatchService = require('./dispatch.service');

class RequestsService {
  /**
   * Phase 6: Create request using Dispatch Engine
   */
  static async createRequest(clientId, { categoryId, cityId, description, address, latitude, longitude }) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    // 1. Insert unassigned request
    const { data: newRequest, error: createErr } = await supabase
      .from('service_requests')
      .insert([
        {
          client_id: clientId,
          category_id: categoryId,
          city_id: cityId,
          description,
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
      return newRequest; // Request created, but unassigned. Client waits.
    }

    // 3. Create Job Offers
    const offers = technicians.map(tech => ({
      request_id: newRequest.id,
      technician_id: tech.id,
      status: 'pending'
    }));

    const { error: offersErr } = await supabase.from('job_offers').insert(offers);
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

    return newRequest;
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

    return data || [];
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

    // Access control check
    if (role === 'client' && request.client_id !== userId) {
      throw ApiError.forbidden('Vous n\'avez pas l\'autorisation d\'accéder à cette demande');
    }
    if (role === 'technician') {
      // Tech can view if they are assigned, OR if they have a pending offer for it
      if (request.assigned_technician?.user_id !== userId) {
        // Check if they have an offer
        const { data: offer } = await supabase
          .from('job_offers')
          .select('id')
          .eq('request_id', requestId)
          .eq('technician_id', (await this.getTechId(userId)))
          .single();
        if (!offer) {
           throw ApiError.forbidden('Vous n\'avez pas l\'autorisation d\'accéder à cette demande');
        }
      }
    }

    return request;
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

    // Invalidate any pending offers
    await supabase.from('job_offers').update({ status: 'expired' }).eq('request_id', requestId).eq('status', 'pending');

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

    return data;
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

    return data;
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
