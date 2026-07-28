const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');

class AdminService {
  static async getPendingVerifications() {
    if (!supabase) return [];

    const { data, error } = await supabase
      .from('technician_documents')
      .select(`
        id, document_type, file_url, status, rejection_reason, uploaded_at,
        technician:technician_profiles!technician_id(
          id, verified, years_experience,
          user:users!user_id(id, full_name, email, phone)
        )
      `)
      .order('uploaded_at', { ascending: false });

    if (error) {
      console.error('[AdminService.getPendingVerifications error]', error);
      throw ApiError.internal('Erreur lors de la récupération des documents de vérification');
    }

    return data || [];
  }

  static async reviewDocument(documentId, status, rejectionReason = null) {
    if (!['approved', 'rejected'].includes(status)) {
      throw ApiError.badRequest('Statut de décision invalide');
    }

    if (!supabase) throw ApiError.internal('Base de données indisponible');

    const { data: doc, error: fetchErr } = await supabase
      .from('technician_documents')
      .select('id, technician_id, document_type, status')
      .eq('id', documentId)
      .single();

    if (fetchErr || !doc) {
      throw ApiError.notFound('Document non trouvé');
    }

    const { data: updatedDoc, error: updateErr } = await supabase
      .from('technician_documents')
      .update({
        status: status,
        rejection_reason: status === 'rejected' ? rejectionReason : null,
        reviewed_at: new Date().toISOString()
      })
      .eq('id', documentId)
      .select()
      .single();

    if (updateErr) {
      console.error('[AdminService.reviewDocument error]', updateErr);
      throw ApiError.internal('Erreur lors de la mise à jour du document');
    }

    // Get technician profile and user
    const { data: techProfile } = await supabase
      .from('technician_profiles')
      .select('id, user_id')
      .eq('id', doc.technician_id)
      .single();

    if (techProfile) {
      // If approved, check if technician now has an approved document
      if (status === 'approved') {
        await supabase
          .from('technician_profiles')
          .update({ verified: true })
          .eq('id', techProfile.id);
      }

      // Notify technician
      const notificationTitle = status === 'approved' 
        ? 'Document de vérification approuvé' 
        : 'Document de vérification rejeté';

      const notificationMsg = status === 'approved'
        ? `Votre document (${doc.document_type}) a été approuvé. Votre profil est désormais vérifié.`
        : `Votre document (${doc.document_type}) a été rejeté. Motif : ${rejectionReason || 'Non conforme'}.`;

      await supabase.from('notifications').insert([
        {
          user_id: techProfile.user_id,
          type: 'verification_update',
          title: notificationTitle,
          message: notificationMsg,
          metadata: { documentId, status }
        }
      ]);
    }

    return updatedDoc;
  }

  static async getPlatformStats() {
    if (!supabase) return { users: 0, technicians: 0, verifiedTechnicians: 0, requests: 0, completedRequests: 0 };

    const { count: usersCount } = await supabase.from('users').select('*', { count: 'exact', head: true });
    const { count: techCount } = await supabase.from('technician_profiles').select('*', { count: 'exact', head: true });
    const { count: verifiedTechCount } = await supabase.from('technician_profiles').select('*', { count: 'exact', head: true }).eq('verified', true);
    const { count: requestsCount } = await supabase.from('service_requests').select('*', { count: 'exact', head: true });
    const { count: completedCount } = await supabase.from('service_requests').select('*', { count: 'exact', head: true }).eq('status', 'completed');

    return {
      usersCount: usersCount || 0,
      techniciansCount: techCount || 0,
      verifiedTechniciansCount: verifiedTechCount || 0,
      serviceRequestsCount: requestsCount || 0,
      completedRequestsCount: completedCount || 0
    };
  }
}

module.exports = AdminService;
