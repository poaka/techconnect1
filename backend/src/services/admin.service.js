const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');

class AdminService {
  // ── Verifications ────────────────────────────────────────────────────────
  static async getPendingVerifications() {
    if (!supabase) return [];

    const { data, error } = await supabase
      .from('technician_documents')
      .select(`
        id, document_type, file_url, status, rejection_reason, uploaded_at, reviewed_at,
        technician:technician_profiles!technician_id(
          id, verified, years_experience, price_min, price_max, bio,
          user:users!user_id(id, full_name, email, phone, avatar_url),
          city:cities!city_id(id, name, region:regions!region_id(id, name)),
          category:categories!category_id(id, name, icon)
        )
      `)
      .eq('status', 'pending')
      .order('uploaded_at', { ascending: false });

    if (error) {
      console.error('[AdminService.getPendingVerifications error]', error);
      throw ApiError.internal('Erreur lors de la récupération des documents de vérification');
    }

    if (!data || data.length === 0) return [];

    return await Promise.all(
      data.map(async (doc) => {
        if (!doc.file_url || doc.file_url.startsWith('http')) return doc;
        const { data: signed } = await supabase.storage
          .from('documents')
          .createSignedUrl(doc.file_url, 60 * 60 * 24 * 365);
        if (signed) doc.file_url = signed.signedUrl;
        return doc;
      })
    );
  }

  static async getRejectedVerifications() {
    if (!supabase) return [];

    const { data, error } = await supabase
      .from('technician_documents')
      .select(`
        id, document_type, file_url, status, rejection_reason, uploaded_at, reviewed_at,
        technician:technician_profiles!technician_id(
          id, verified, years_experience, price_min, price_max, bio,
          user:users!user_id(id, full_name, email, phone, avatar_url),
          city:cities!city_id(id, name, region:regions!region_id(id, name)),
          category:categories!category_id(id, name, icon)
        )
      `)
      .eq('status', 'rejected')
      .order('reviewed_at', { ascending: false });

    if (error) {
      console.error('[AdminService.getRejectedVerifications error]', error);
      throw ApiError.internal('Erreur lors de la récupération des documents rejetés');
    }

    if (!data || data.length === 0) return [];

    return await Promise.all(
      data.map(async (doc) => {
        if (!doc.file_url || doc.file_url.startsWith('http')) return doc;
        const { data: signed } = await supabase.storage
          .from('documents')
          .createSignedUrl(doc.file_url, 60 * 60 * 24 * 365);
        if (signed) doc.file_url = signed.signedUrl;
        return doc;
      })
    );
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

    if (fetchErr || !doc) throw ApiError.notFound('Document non trouvé');

    const { data: updatedDoc, error: updateErr } = await supabase
      .from('technician_documents')
      .update({
        status,
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

    const { data: techProfile } = await supabase
      .from('technician_profiles')
      .select('id, user_id')
      .eq('id', doc.technician_id)
      .single();

    if (techProfile) {
      if (status === 'approved') {
        await supabase
          .from('technician_profiles')
          .update({ verified: true })
          .eq('id', techProfile.id);
      }

      const title = status === 'approved'
        ? 'Document de vérification approuvé'
        : 'Document de vérification rejeté';
      const message = status === 'approved'
        ? `Votre document (${doc.document_type}) a été approuvé. Votre profil est désormais vérifié.`
        : `Votre document (${doc.document_type}) a été rejeté. Motif : ${rejectionReason || 'Non conforme'}.`;

      await supabase.from('notifications').insert([{
        user_id: techProfile.user_id,
        type: 'verification_update',
        title,
        message,
        metadata: { documentId, status }
      }]);
    }

    return updatedDoc;
  }

  // ── Platform Stats ────────────────────────────────────────────────────────
  static async getPlatformStats() {
    if (!supabase) {
      return { usersCount: 0, techniciansCount: 0, verifiedTechniciansCount: 0, serviceRequestsCount: 0, completedRequestsCount: 0, reviewsCount: 0, pendingVerificationsCount: 0, rejectedVerificationsCount: 0, reportsCount: 0, pendingReportsCount: 0 };
    }

    const [
      { count: usersCount },
      { count: techCount },
      { count: verifiedTechCount },
      { count: requestsCount },
      { count: completedCount },
      { count: reviewsCount },
      { count: pendingVerifCount },
      { count: rejectedVerifCount },
      { count: reportsCount },
      { count: pendingReportsCount }
    ] = await Promise.all([
      supabase.from('users').select('*', { count: 'exact', head: true }),
      supabase.from('users').select('*', { count: 'exact', head: true }).eq('role', 'technician'),
      supabase.from('technician_profiles').select('*', { count: 'exact', head: true }).eq('verified', true),
      supabase.from('service_requests').select('*', { count: 'exact', head: true }),
      supabase.from('service_requests').select('*', { count: 'exact', head: true }).eq('status', 'completed'),
      supabase.from('reviews').select('*', { count: 'exact', head: true }),
      supabase.from('technician_documents').select('*', { count: 'exact', head: true }).eq('status', 'pending'),
      supabase.from('technician_documents').select('*', { count: 'exact', head: true }).eq('status', 'rejected'),
      supabase.from('reports').select('*', { count: 'exact', head: true }),
      supabase.from('reports').select('*', { count: 'exact', head: true }).eq('status', 'pending')
    ]);

    return {
      usersCount: usersCount || 0,
      techniciansCount: techCount || 0,
      verifiedTechniciansCount: verifiedTechCount || 0,
      serviceRequestsCount: requestsCount || 0,
      completedRequestsCount: completedCount || 0,
      reviewsCount: reviewsCount || 0,
      pendingVerificationsCount: pendingVerifCount || 0,
      rejectedVerificationsCount: rejectedVerifCount || 0,
      reportsCount: reportsCount || 0,
      pendingReportsCount: pendingReportsCount || 0
    };
  }

  // ── Users ─────────────────────────────────────────────────────────────────
  static async getUsers({ search = '', role = '' } = {}) {
    if (!supabase) return [];

    let query = supabase
      .from('users')
      .select('id, full_name, email, phone, role, avatar_url, created_at, updated_at')
      .order('created_at', { ascending: false });

    if (role) query = query.eq('role', role);
    if (search) query = query.or(`full_name.ilike.%${search}%,email.ilike.%${search}%`);

    const { data, error } = await query;
    if (error) {
      console.error('[AdminService.getUsers error]', error);
      throw ApiError.internal('Erreur lors de la récupération des utilisateurs');
    }
    return data || [];
  }

  static async deleteUser(userId) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    const { data: user } = await supabase.from('users').select('id, role').eq('id', userId).single();
    if (!user) throw ApiError.notFound('Utilisateur non trouvé');
    if (user.role === 'admin') throw ApiError.forbidden('Impossible de supprimer un compte administrateur');

    console.log(`[AdminService.deleteUser] Deleting user ${userId} (role: ${user.role})...`);

    // Clean up dependent technician records if user is a technician
    const { data: techProfile } = await supabase
      .from('technician_profiles')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();

    if (techProfile) {
      console.log(`[AdminService.deleteUser] Deleting technician_profile ${techProfile.id} and child tables...`);
      await supabase.from('technician_documents').delete().eq('technician_id', techProfile.id);
      await supabase.from('reviews').delete().eq('technician_id', techProfile.id);
      await supabase.from('favorites').delete().eq('technician_id', techProfile.id);
      await supabase.from('service_requests').delete().eq('technician_id', techProfile.id);
      await supabase.from('technician_profiles').delete().eq('id', techProfile.id);
    }

    // Clean up dependent client records
    await supabase.from('notifications').delete().eq('user_id', userId);
    await supabase.from('favorites').delete().eq('client_id', userId);
    await supabase.from('reviews').delete().eq('client_id', userId);
    await supabase.from('service_requests').delete().eq('client_id', userId);

    // Delete user row
    const { error } = await supabase.from('users').delete().eq('id', userId);
    if (error) {
      console.error('[AdminService.deleteUser error]', error);
      throw ApiError.internal('Erreur lors de la suppression de l\'utilisateur');
    }

    console.log(`[AdminService.deleteUser] User ${userId} deleted successfully.`);
    return { success: true };
  }

  // ── Technicians ───────────────────────────────────────────────────────────
  static async getTechnicians() {
    if (!supabase) return [];

    const { data, error } = await supabase
      .from('technician_profiles')
      .select(`
        id, bio, years_experience, price_min, price_max, whatsapp, verified, availability, rating_avg, rating_count, created_at,
        user:users!user_id(id, full_name, email, phone, avatar_url, created_at),
        city:cities!city_id(id, name, region:regions!region_id(id, name)),
        category:categories!category_id(id, name, icon)
      `)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[AdminService.getTechnicians error]', error);
      throw ApiError.internal('Erreur lors de la récupération des techniciens');
    }
    return data || [];
  }

  // ── Service Requests ──────────────────────────────────────────────────────
  static async getServiceRequests({ status = '' } = {}) {
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

    if (status) {
      query = query.eq('status', status);
    }

    const { data, error } = await query;
    if (error) {
      console.error('[AdminService.getServiceRequests error]', error);
      throw ApiError.internal('Erreur lors de la récupération des demandes de service');
    }
    return data || [];
  }

  // ── Categories ────────────────────────────────────────────────────────────
  static async getCategories() {
    if (!supabase) return [];

    const { data, error } = await supabase
      .from('categories')
      .select('id, name, icon, description, created_at')
      .order('name');

    if (error) throw ApiError.internal('Erreur lors de la récupération des catégories');
    return data || [];
  }

  static async createCategory({ name, icon = null, description = null }) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');
    if (!name || !name.trim()) throw ApiError.badRequest('Le nom de la catégorie est requis');

    const { data, error } = await supabase
      .from('categories')
      .insert([{ name: name.trim(), icon: icon || null, description: description || null }])
      .select()
      .single();

    if (error) {
      if (error.code === '23505') throw ApiError.conflict('Une catégorie avec ce nom existe déjà');
      throw ApiError.internal('Erreur lors de la création de la catégorie');
    }
    return data;
  }

  static async updateCategory(categoryId, { name, icon, description }) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    const updates = {};
    if (name !== undefined) updates.name = name.trim();
    if (icon !== undefined) updates.icon = icon;
    if (description !== undefined) updates.description = description;

    const { data, error } = await supabase
      .from('categories')
      .update(updates)
      .eq('id', categoryId)
      .select()
      .single();

    if (error) {
      if (error.code === '23505') throw ApiError.conflict('Une catégorie avec ce nom existe déjà');
      throw ApiError.internal('Erreur lors de la mise à jour de la catégorie');
    }
    if (!data) throw ApiError.notFound('Catégorie non trouvée');
    return data;
  }

  static async deleteCategory(categoryId) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    const { error } = await supabase.from('categories').delete().eq('id', categoryId);
    if (error) throw ApiError.internal('Erreur lors de la suppression de la catégorie');
    return { success: true };
  }

  // ── Regions & Cities ──────────────────────────────────────────────────────
  static async getRegions() {
    if (!supabase) return [];

    const { data, error } = await supabase
      .from('regions')
      .select('id, name, cities(id, name)')
      .order('name');

    if (error) throw ApiError.internal('Erreur lors de la récupération des régions');
    return data || [];
  }

  static async createRegion({ name }) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');
    if (!name || !name.trim()) throw ApiError.badRequest('Le nom de la région est requis');

    const { data, error } = await supabase
      .from('regions')
      .insert([{ name: name.trim() }])
      .select()
      .single();

    if (error) {
      if (error.code === '23505') throw ApiError.conflict('Une région avec ce nom existe déjà');
      throw ApiError.internal('Erreur lors de la création de la région');
    }
    return data;
  }

  static async updateRegion(regionId, { name }) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');
    if (!name || !name.trim()) throw ApiError.badRequest('Le nom de la région est requis');

    const { data, error } = await supabase
      .from('regions')
      .update({ name: name.trim() })
      .eq('id', regionId)
      .select()
      .single();

    if (error) {
      if (error.code === '23505') throw ApiError.conflict('Une région avec ce nom existe déjà');
      throw ApiError.internal('Erreur lors de la mise à jour de la région');
    }
    if (!data) throw ApiError.notFound('Région non trouvée');
    return data;
  }

  static async deleteRegion(regionId) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');
    const { error } = await supabase.from('regions').delete().eq('id', regionId);
    if (error) throw ApiError.internal('Erreur lors de la suppression de la région');
    return { success: true };
  }

  // ── Cities ────────────────────────────────────────────────────────────────
  static async createCity({ name, regionId }) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');
    if (!name || !name.trim()) throw ApiError.badRequest('Le nom de la ville est requis');
    if (!regionId) throw ApiError.badRequest('L\'ID de la région est requis');

    const { data, error } = await supabase
      .from('cities')
      .insert([{ name: name.trim(), region_id: regionId }])
      .select()
      .single();

    if (error) {
      if (error.code === '23505') throw ApiError.conflict('Cette ville existe déjà dans cette région');
      throw ApiError.internal('Erreur lors de la création de la ville');
    }
    return data;
  }

  static async updateCity(cityId, { name, regionId }) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');
    
    const updates = {};
    if (name !== undefined) updates.name = name.trim();
    if (regionId !== undefined) updates.region_id = regionId;

    const { data, error } = await supabase
      .from('cities')
      .update(updates)
      .eq('id', cityId)
      .select()
      .single();

    if (error) {
      if (error.code === '23505') throw ApiError.conflict('Cette ville existe déjà dans cette région');
      throw ApiError.internal('Erreur lors de la mise à jour de la ville');
    }
    if (!data) throw ApiError.notFound('Ville non trouvée');
    return data;
  }

  static async deleteCity(cityId) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');
    const { error } = await supabase.from('cities').delete().eq('id', cityId);
    if (error) throw ApiError.internal('Erreur lors de la suppression de la ville');
    return { success: true };
  }
}

module.exports = AdminService;
