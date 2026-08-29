const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');

class ReviewsService {
  static async createReview(clientId, { requestId, rating, comment }) {
    if (rating < 1 || rating > 5) {
      throw ApiError.badRequest('La note doit être comprise entre 1 et 5');
    }

    if (!supabase) throw ApiError.internal('Base de données indisponible');

    // Fetch the request
    const { data: request, error: reqErr } = await supabase
      .from('service_requests')
      .select('id, client_id, assigned_technician_id, status')
      .eq('id', requestId)
      .single();

    if (reqErr || !request) {
      throw ApiError.notFound('Demande de service non trouvée');
    }

    if (request.client_id !== clientId) {
      throw ApiError.forbidden('Vous n\'êtes pas le client associé à cette demande');
    }

    if (request.status !== 'completed') {
      throw ApiError.badRequest('Seules les demandes terminées peuvent faire l\'objet d\'un avis');
    }

    if (!request.assigned_technician_id) {
      throw ApiError.badRequest('Aucun technicien assigné à cette demande');
    }

    // Check existing review
    const { data: existingReview } = await supabase
      .from('reviews')
      .select('id')
      .eq('request_id', requestId)
      .maybeSingle();

    if (existingReview) {
      throw ApiError.conflict('Cette demande a déjà fait l\'objet d\'un avis');
    }

    const { data: newReview, error: insertErr } = await supabase
      .from('reviews')
      .insert([
        {
          request_id: requestId,
          client_id: clientId,
          technician_id: request.assigned_technician_id,
          rating: rating,
          comment: comment || null
        }
      ])
      .select(`
        id, rating, comment, created_at,
        client:users!client_id(id, full_name, avatar_url)
      `)
      .single();

    if (insertErr) {
      console.error('[ReviewsService.createReview error]', insertErr);
      throw ApiError.internal('Erreur lors de l\'enregistrement de l\'avis');
    }

    // Update technician rating_avg and rating_count in background
    try {
      const { data: allReviews } = await supabase
        .from('reviews')
        .select('rating')
        .eq('technician_id', request.assigned_technician_id);

      if (allReviews && allReviews.length > 0) {
        const count = allReviews.length;
        const avg = allReviews.reduce((sum, r) => sum + r.rating, 0) / count;
        await supabase
          .from('technician_profiles')
          .update({
            rating_avg: parseFloat(avg.toFixed(2)),
            rating_count: count
          })
          .eq('id', request.assigned_technician_id);
      }
    } catch (calcErr) {
      console.error('[ReviewsService.createReview] Rating recalculation error:', calcErr);
    }

    return newReview;
  }

  static async getTechnicianReviews(technicianId) {
    if (!supabase) return [];

    const { data, error } = await supabase
      .from('reviews')
      .select(`
        id, rating, comment, created_at,
        client:users!client_id(id, full_name, avatar_url)
      `)
      .eq('technician_id', technicianId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[ReviewsService.getTechnicianReviews error]', error);
      throw ApiError.internal('Erreur lors de la récupération des avis');
    }

    return data || [];
  }
}

module.exports = ReviewsService;
