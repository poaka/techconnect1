const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');

// Seeded fallback data for offline dev / testing
const mockCategories = [
  { id: '20000000-0000-0000-0000-000000000001', name: 'Électricien', icon: 'bolt', description: 'Dépannage, câblage, installation électrique' },
  { id: '20000000-0000-0000-0000-000000000002', name: 'Plombier', icon: 'water_drop', description: 'Réparation de fuites, débouchage' },
  { id: '20000000-0000-0000-0000-000000000003', name: 'Mécanicien', icon: 'build', description: 'Entretien et réparation automobile' },
  { id: '20000000-0000-0000-0000-000000000004', name: 'Menuisier', icon: 'carpenter', description: 'Fabrication de meubles et portes' },
  { id: '20000000-0000-0000-0000-000000000005', name: 'Réparateur Téléphone & Informatique', icon: 'phone_android', description: 'Réparation écrans, PC et smartphones' }
];

const mockRegions = [
  {
    id: '00000000-0000-0000-0000-000000000001',
    name: 'Centre',
    cities: [{ id: '10000000-0000-0000-0000-000000000001', name: 'Yaoundé', region_id: '00000000-0000-0000-0000-000000000001' }]
  },
  {
    id: '00000000-0000-0000-0000-000000000002',
    name: 'Littoral',
    cities: [{ id: '10000000-0000-0000-0000-000000000002', name: 'Douala', region_id: '00000000-0000-0000-0000-000000000002' }]
  }
];

const mockTechnicians = [
  {
    id: '40000000-0000-0000-0000-000000000001',
    user_id: '30000000-0000-0000-0000-000000000003',
    bio: 'Électricien qualifié avec 8 ans d\'expérience à Yaoundé. Spécialiste dépannage rapide et câblage moderne.',
    years_experience: 8,
    price_min: 5000.00,
    price_max: 25000.00,
    whatsapp: '+237692222222',
    verified: true,
    availability: 'available',
    rating_avg: 4.85,
    rating_count: 12,
    created_at: new Date().toISOString(),
    user: { id: '30000000-0000-0000-0000-000000000003', full_name: 'Samuel Électricien', email: 'samuel@techconnect.cm', phone: '+237692222222', avatar_url: null },
    city: { id: '10000000-0000-0000-0000-000000000001', name: 'Yaoundé', region: { id: '00000000-0000-0000-0000-000000000001', name: 'Centre' } },
    categories: [{ category: { id: '20000000-0000-0000-0000-000000000001', name: 'Électricien', icon: 'bolt' } }]
  }
];

class TechniciansService {
  static async getCategories() {
    if (!supabase) return mockCategories;
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .order('name');
    if (error) throw ApiError.internal('Erreur lors de la récupération des catégories');
    return data;
  }

  static async getRegions() {
    if (!supabase) return mockRegions;
    const { data, error } = await supabase
      .from('regions')
      .select('*, cities(*)')
      .order('name');
    if (error) throw ApiError.internal('Erreur lors de la récupération des régions');
    return data;
  }

  static async searchTechnicians(queryParams) {
    if (!supabase) {
      const { page = 1, limit = 10 } = queryParams;
      return {
        technicians: mockTechnicians,
        total: mockTechnicians.length,
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
        totalPages: 1
      };
    }

    const {
      q,
      category,
      city,
      region,
      availability,
      minRating,
      verifiedOnly,
      page = 1,
      limit = 10
    } = queryParams;

    const pageNum = Math.max(1, parseInt(page, 10));
    const limitNum = Math.max(1, Math.min(50, parseInt(limit, 10)));
    const offset = (pageNum - 1) * limitNum;

    let query = supabase
      .from('technician_profiles')
      .select(`
        id, bio, years_experience, price_min, price_max, whatsapp, verified, availability, rating_avg, rating_count, created_at,
        user:users!user_id(id, full_name, email, phone, avatar_url),
        city:cities!city_id(id, name, region:regions(id, name)),
        categories:technician_categories${category ? '!inner' : ''}(category:categories(id, name, icon))
      `, { count: 'exact' });

    if (availability) query = query.eq('availability', availability);
    if (verifiedOnly === 'true' || verifiedOnly === true) query = query.eq('verified', true);
    if (minRating) query = query.gte('rating_avg', parseFloat(minRating));
    if (city) query = query.eq('city_id', city);
    if (category) query = query.eq('technician_categories.category_id', category);

    if (region && !city) {
      // Fetch city IDs for this region first
      const { data: regionCities } = await supabase.from('cities').select('id').eq('region_id', region);
      if (regionCities && regionCities.length > 0) {
        const cityIds = regionCities.map(c => c.id);
        query = query.in('city_id', cityIds);
      } else {
        query = query.in('city_id', []); // empty result
      }
    }

    query = query
      .order('rating_avg', { ascending: false })
      .range(offset, offset + limitNum - 1);

    const { data, count, error } = await query;

    if (error) {
      console.error('[TechniciansService.searchTechnicians error]', error);
      throw ApiError.internal('Erreur lors de la recherche des techniciens');
    }

    let filteredData = data || [];
    if (q) {
      const searchTerm = q.toLowerCase();
      filteredData = filteredData.filter(t => 
        (t.user && t.user.full_name && t.user.full_name.toLowerCase().includes(searchTerm)) ||
        (t.bio && t.bio.toLowerCase().includes(searchTerm))
      );
    }

    return {
      technicians: filteredData,
      total: count || filteredData.length,
      page: pageNum,
      limit: limitNum,
      totalPages: Math.ceil((count || filteredData.length) / limitNum)
    };
  }

  static async getTechnicianById(id) {
    if (!supabase) {
      const tech = mockTechnicians.find(t => t.id === id);
      if (!tech) throw ApiError.notFound('Technicien non trouvé');
      return tech;
    }

    const { data, error } = await supabase
      .from('technician_profiles')
      .select(`
        id, bio, years_experience, price_min, price_max, whatsapp, verified, availability, rating_avg, rating_count, created_at,
        user:users!user_id(id, full_name, email, phone, avatar_url),
        city:cities!city_id(id, name, region:regions(id, name)),
        categories:technician_categories(category:categories(id, name, icon)),
        reviews(id, rating, comment, created_at, client:users!client_id(id, full_name, avatar_url))
      `)
      .eq('id', id)
      .single();

    if (error || !data) {
      throw ApiError.notFound('Profil technicien non trouvé');
    }

    return data;
  }

  static async updateMyProfile(userId, updateData) {
    if (!supabase) {
      const tech = mockTechnicians.find(t => t.user_id === userId);
      if (!tech) throw ApiError.notFound('Profil technicien non trouvé');
      Object.assign(tech, updateData);
      return tech;
    }

    const { data: profile, error: fetchErr } = await supabase
      .from('technician_profiles')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();

    if (fetchErr) {
      throw ApiError.internal('Erreur lors de la recherche du profil');
    }

    const { bio, yearsExperience, priceMin, priceMax, whatsapp, cityId, categoryIds } = updateData;

    const fieldsToUpdate = {};
    if (bio !== undefined) fieldsToUpdate.bio = bio;
    if (yearsExperience !== undefined) fieldsToUpdate.years_experience = yearsExperience;
    if (priceMin !== undefined) fieldsToUpdate.price_min = priceMin;
    if (priceMax !== undefined) fieldsToUpdate.price_max = priceMax;
    if (whatsapp !== undefined) fieldsToUpdate.whatsapp = whatsapp;
    if (cityId !== undefined) fieldsToUpdate.city_id = cityId;

    let profileId;
    if (!profile) {
      fieldsToUpdate.user_id = userId;
      const { data: newProfile, error: insertErr } = await supabase
        .from('technician_profiles')
        .insert([fieldsToUpdate])
        .select('id')
        .single();

      if (insertErr || !newProfile) {
        console.error('[TechniciansService.updateMyProfile insert error]', insertErr);
        throw ApiError.internal('Erreur lors de la création du profil');
      }
      profileId = newProfile.id;
    } else {
      profileId = profile.id;
      const { error: updateErr } = await supabase
        .from('technician_profiles')
        .update(fieldsToUpdate)
        .eq('id', profileId);

      if (updateErr) {
        console.error('[TechniciansService.updateMyProfile update error]', updateErr);
        throw ApiError.internal('Erreur lors de la mise à jour du profil');
      }
    }

    if (Array.isArray(categoryIds)) {
      if (profile) {
        await supabase.from('technician_categories').delete().eq('technician_id', profileId);
      }
      if (categoryIds.length > 0) {
        const categoryInserts = categoryIds.map(catId => ({
          technician_id: profileId,
          category_id: catId
        }));
        await supabase.from('technician_categories').insert(categoryInserts);
      }
    }

    return this.getTechnicianById(profileId);
  }

  static async updateAvailability(userId, availability) {
    if (!['available', 'busy', 'offline'].includes(availability)) {
      throw ApiError.badRequest('Statut de disponibilité invalide');
    }

    if (!supabase) {
      const tech = mockTechnicians.find(t => t.user_id === userId);
      if (!tech) throw ApiError.notFound('Profil technicien non trouvé');
      tech.availability = availability;
      return { id: tech.id, availability };
    }

    const { data, error } = await supabase
      .from('technician_profiles')
      .update({ availability })
      .eq('user_id', userId)
      .select('id, availability')
      .single();

    if (error || !data) {
      throw ApiError.notFound('Profil technicien non trouvé');
    }

    return data;
  }

  static async uploadDocument(userId, documentType, file) {
    if (!['id_card', 'certificate'].includes(documentType)) {
      throw ApiError.badRequest('Type de document invalide');
    }

    if (!file) {
      throw ApiError.badRequest('Fichier manquant');
    }

    const doc = {
      id: `doc-${Date.now()}`,
      technician_id: `tech-${userId}`,
      document_type: documentType,
      file_url: `uploads/${file.originalname}`,
      status: 'pending',
      uploaded_at: new Date().toISOString()
    };

    if (!supabase) return doc;

    const { data: profile } = await supabase
      .from('technician_profiles')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (!profile) throw ApiError.notFound('Profil technicien non trouvé');

    const { data: savedDoc, error } = await supabase
      .from('technician_documents')
      .insert([
        {
          technician_id: profile.id,
          document_type: documentType,
          file_url: doc.file_url,
          status: 'pending'
        }
      ])
      .select()
      .single();

    if (error) throw ApiError.internal('Erreur lors de l\'enregistrement du document');
    return savedDoc;
  }

  static async getMyDocuments(userId) {
    if (!supabase) return [];

    const { data: profile } = await supabase
      .from('technician_profiles')
      .select('id')
      .eq('user_id', userId)
      .single();

    if (!profile) throw ApiError.notFound('Profil technicien non trouvé');

    const { data, error } = await supabase
      .from('technician_documents')
      .select('*')
      .eq('technician_id', profile.id)
      .order('uploaded_at', { ascending: false });

    if (error) throw ApiError.internal('Erreur lors de la récupération des documents');
    return data;
  }

  /**
   * GET /api/technicians/me/stats
   * Returns per-technician aggregated stats for the dashboard.
   */
  static async getTechnicianStats(userId) {
    if (!supabase) {
      return {
        pendingRequestsCount: 2,
        acceptedRequestsCount: 1,
        inProgressRequestsCount: 0,
        completedJobsCount: 5,
        totalRequestsCount: 8,
        ratingAvg: 4.5,
        ratingCount: 4,
        availability: 'available',
        verified: false,
      };
    }

    // Get the technician profile
    const { data: profile, error: profileErr } = await supabase
      .from('technician_profiles')
      .select('id, rating_avg, rating_count, availability, verified')
      .eq('user_id', userId)
      .single();

    if (profileErr || !profile) {
      throw ApiError.notFound('Profil technicien non trouvé');
    }

    // Count requests by status in one call
    const statusCounts = {
      pending: 0,
      accepted: 0,
      in_progress: 0,
      completed: 0,
    };

    const statuses = ['pending', 'accepted', 'in_progress', 'completed'];
    await Promise.all(
      statuses.map(async (status) => {
        const { count } = await supabase
          .from('service_requests')
          .select('*', { count: 'exact', head: true })
          .eq('technician_id', profile.id)
          .eq('status', status);
        statusCounts[status] = count || 0;
      })
    );

    return {
      pendingRequestsCount: statusCounts.pending,
      acceptedRequestsCount: statusCounts.accepted,
      inProgressRequestsCount: statusCounts.in_progress,
      completedJobsCount: statusCounts.completed,
      totalRequestsCount: Object.values(statusCounts).reduce((a, b) => a + b, 0),
      ratingAvg: parseFloat(profile.rating_avg) || 0,
      ratingCount: profile.rating_count || 0,
      availability: profile.availability,
      verified: profile.verified,
    };
  }

  /**
   * GET /api/technicians/:id/reviews
   * Returns paginated reviews for a technician profile (public).
   */
  static async getTechnicianReviewsById(technicianId) {
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
      console.error('[TechniciansService.getTechnicianReviewsById error]', error);
      throw ApiError.internal('Erreur lors de la récupération des avis');
    }

    return data || [];
  }
}

module.exports = TechniciansService;
