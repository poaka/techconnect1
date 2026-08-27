const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');

class OffersService {
  /**
   * Atomically accept a job offer.
   * Uses Compare-And-Swap (CAS) to ensure two technicians cannot accept the same request simultaneously.
   *
   * @param {string} offerId - UUID of the job offer
   * @param {string} technicianId - UUID of the technician trying to accept
   */
  static async acceptOffer(offerId, technicianId) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    // 1. Fetch the offer to get the request_id and verify ownership
    const { data: offer, error: offerErr } = await supabase
      .from('job_offers')
      .select('id, request_id, technician_id, status')
      .eq('id', offerId)
      .single();

    if (offerErr || !offer) {
      throw ApiError.notFound('Offre introuvable');
    }

    if (offer.technician_id !== technicianId) {
      throw ApiError.forbidden('Cette offre ne vous est pas destinée');
    }

    if (offer.status !== 'pending') {
      throw ApiError.badRequest(`Cette offre est déjà ${offer.status}`);
    }

    // 2. ATOMIC ASSIGNMENT (Compare-And-Swap)
    // We only update the service_request if assigned_technician_id is STILL null.
    // This entirely prevents race conditions.
    const { data: assignedRequest, error: assignErr } = await supabase
      .from('service_requests')
      .update({
        assigned_technician_id: technicianId,
        status: 'assigned',
        updated_at: new Date().toISOString()
      })
      .eq('id', offer.request_id)
      .is('assigned_technician_id', null) // <-- The Atomic CAS constraint
      .select()
      .single();

    // If assignErr exists or assignedRequest is null, it means no row was updated.
    // This happens if the request was already assigned to someone else, or cancelled.
    if (assignErr || !assignedRequest) {
      // Mark this specific offer as expired since they lost the race
      await supabase
        .from('job_offers')
        .update({ status: 'expired', responded_at: new Date().toISOString() })
        .eq('id', offerId);
        
      throw ApiError.badRequest('Trop tard, cette mission a déjà été assignée à un autre technicien ou a été annulée.');
    }

    // 3. SUCCESS - The technician won the assignment
    // Mark this offer as accepted
    await supabase
      .from('job_offers')
      .update({ status: 'accepted', responded_at: new Date().toISOString() })
      .eq('id', offerId);

    // Invalidate all other competing offers for this same request
    await supabase
      .from('job_offers')
      .update({ status: 'expired' }) // We use 'expired' for those who didn't respond in time
      .eq('request_id', offer.request_id)
      .neq('id', offerId)
      .eq('status', 'pending');

    return {
      message: 'Mission acceptée avec succès',
      request: assignedRequest
    };
  }

  /**
   * Reject a job offer
   */
  static async rejectOffer(offerId, technicianId) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    const { data: offer, error: offerErr } = await supabase
      .from('job_offers')
      .select('id, technician_id, status')
      .eq('id', offerId)
      .single();

    if (offerErr || !offer) throw ApiError.notFound('Offre introuvable');
    if (offer.technician_id !== technicianId) throw ApiError.forbidden('Accès refusé');
    if (offer.status !== 'pending') throw ApiError.badRequest(`Offre déjà ${offer.status}`);

    const { data, error } = await supabase
      .from('job_offers')
      .update({ status: 'rejected', responded_at: new Date().toISOString() })
      .eq('id', offerId)
      .select()
      .single();

    if (error) throw ApiError.internal('Erreur lors du rejet de l\'offre');

    // Here we could trigger a re-dispatch if we wanted to dynamically invite more technicians,
    // but that would typically be handled by a background cron or trigger.
    return data;
  }
}

module.exports = OffersService;
