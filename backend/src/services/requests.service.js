const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');

class RequestsService {
  static async createRequest(clientId, { technicianId, categoryId, description, address }) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    // Verify technician exists
    const { data: techProfile, error: techErr } = await supabase
      .from('technician_profiles')
      .select('id, user_id')
      .eq('id', technicianId)
      .single();

    if (techErr || !techProfile) {
      throw ApiError.notFound('Technicien non trouvé');
    }

    const { data: newRequest, error: createErr } = await supabase
      .from('service_requests')
      .insert([
        {
          client_id: clientId,
          technician_id: technicianId,
          category_id: categoryId || null,
          description,
          address: address || null,
          status: 'pending'
        }
      ])
      .select('*')
      .single();

    if (createErr || !newRequest) {
      console.error('[RequestsService.createRequest error]', createErr);
      throw ApiError.internal('Erreur lors de la création de la demande');
    }

    // Fetch client name for notification safely
    const { data: clientUser } = await supabase
      .from('users')
      .select('full_name')
      .eq('id', clientId)
      .maybeSingle();

    // Send notification to technician safely
    try {
      await supabase.from('notifications').insert([
        {
          user_id: techProfile.user_id,
          type: 'request_created',
          title: 'Nouvelle demande de service',
          message: `Vous avez reçu une nouvelle demande de service de ${clientUser?.full_name || 'un client'}.`,
          metadata: { requestId: newRequest.id }
        }
      ]);
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
        id, status, description, address, created_at, updated_at, completed_at,
        category:categories(id, name, icon),
        client:users!client_id(id, full_name, email, phone, avatar_url),
        technician:technician_profiles!technician_id(
          id, user:users!user_id(id, full_name, email, phone, avatar_url),
          city:cities(id, name)
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
      query = query.eq('technician_id', profile.id);
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
        id, status, description, address, created_at, updated_at, completed_at,
        client_id, technician_id,
        category:categories(id, name, icon),
        client:users!client_id(id, full_name, email, phone, avatar_url),
        technician:technician_profiles!technician_id(
          id, user_id, user:users!user_id(id, full_name, email, phone, avatar_url),
          city:cities(id, name)
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
    if (role === 'technician' && request.technician.user_id !== userId) {
      throw ApiError.forbidden('Vous n\'avez pas l\'autorisation d\'accéder à cette demande');
    }

    return request;
  }

  static async updateRequestStatus(requestId, userId, role, newStatus) {
    const validStatuses = ['pending', 'accepted', 'rejected', 'in_progress', 'completed', 'cancelled'];
    if (!validStatuses.includes(newStatus)) {
      throw ApiError.badRequest('Statut de demande invalide');
    }

    const request = await this.getRequestById(requestId, userId, role);
    const currentStatus = request.status;

    // Allowed transition state machine matrix
    const allowedTransitions = {
      pending: ['accepted', 'rejected', 'cancelled'],
      accepted: ['in_progress', 'cancelled'],
      in_progress: ['completed', 'cancelled'],
      completed: [],
      rejected: [],
      cancelled: []
    };

    if (!allowedTransitions[currentStatus].includes(newStatus)) {
      throw ApiError.badRequest(`Transition de statut invalide de '${currentStatus}' vers '${newStatus}'`);
    }

    // Role specific transition rules
    if (newStatus === 'cancelled' && role !== 'client') {
      throw ApiError.forbidden('Seul le client peut annuler la demande');
    }
    if (['accepted', 'rejected', 'in_progress', 'completed'].includes(newStatus) && role !== 'technician') {
      throw ApiError.forbidden('Seul le technicien peut effectuer cette action');
    }

    const updateFields = { status: newStatus };
    if (newStatus === 'completed') {
      updateFields.completed_at = new Date().toISOString();
    }

    const { data: updated, error } = await supabase
      .from('service_requests')
      .update(updateFields)
      .eq('id', requestId)
      .select()
      .single();

    if (error) {
      console.error('[RequestsService.updateRequestStatus error]', error);
      throw ApiError.internal('Erreur lors de la mise à jour de la demande');
    }

    // Notify recipient
    const recipientUserId = role === 'client' ? request.technician.user_id : request.client_id;
    const statusLabels = {
      accepted: 'acceptée',
      rejected: 'refusée',
      in_progress: 'en cours',
      completed: 'terminée',
      cancelled: 'annulée'
    };

    await supabase.from('notifications').insert([
      {
        user_id: recipientUserId,
        type: 'request_status_change',
        title: `Mise à jour de votre demande`,
        message: `La demande de service est désormais ${statusLabels[newStatus] || newStatus}.`,
        metadata: { requestId: request.id, status: newStatus }
      }
    ]);

    return updated;
  }
}

module.exports = RequestsService;
