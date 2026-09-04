
const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');

class DispatchService {
  /**
   * Find the most suitable, verified, and available technicians for a given request.
   *
   * Strategy:
   *   - Since technician_profiles.category_id can be null for real users (set only during seeding),
   *     we match by city_id first (mandatory), then filter by category_id when it's set.
   *     This ensures the engine always finds candidates even when category isn't saved.
   *   - Primary sort: active_job_count ASC (load balancing)
   *   - Tie-breaker 1: rating_avg DESC
   *   - Tie-breaker 2: created_at ASC (oldest/most experienced first)
   *
   * @param {Object} params
   * @param {string} params.categoryId - UUID of the requested category
   * @param {string} params.cityId - UUID of the requested city
   * @param {number} [params.limit=5] - Maximum number of technicians to return
   * @returns {Promise<Array>} List of suitable technician profiles
   */
  static async findAvailableTechnicians({ categoryId, cityId, targetTechnicianId = null, limit = 5 }) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    try {
      const selectFields = `
        id,
        user_id,
        bio,
        price_min,
        price_max,
        rating_avg,
        rating_count,
        active_job_count,
        category_id,
        verified,
        city_id,
        users (
          full_name,
          avatar_url,
          phone
        )
      `;

      // If targeted to a specific technician, check if they exist
      if (targetTechnicianId) {
        const { data: targetTech } = await supabase
          .from('technician_profiles')
          .select(selectFields)
          .eq('id', targetTechnicianId)
          .single();

        if (targetTech) {
          console.log(`[DispatchService] Direct target technician specified: ${targetTechnicianId}`);
          return [targetTech];
        }
      }

      // Step 1: Strict match — verified = true, available, same city AND same category
      if (categoryId && cityId) {
        const { data: strictMatches, error } = await supabase
          .from('technician_profiles')
          .select(selectFields)
          .eq('verified', true)
          .eq('availability', 'available')
          .eq('city_id', cityId)
          .eq('category_id', categoryId)
          .order('active_job_count', { ascending: true })
          .order('rating_avg', { ascending: false })
          .limit(limit);

        if (!error && strictMatches && strictMatches.length > 0) {
          console.log(`[DispatchService] Found ${strictMatches.length} verified technician(s) matching city + category.`);
          return strictMatches;
        }
      }

      // Step 2: Available matching city + category (including newly registered technicians)
      if (categoryId && cityId) {
        const { data: catCityMatches, error } = await supabase
          .from('technician_profiles')
          .select(selectFields)
          .eq('availability', 'available')
          .eq('city_id', cityId)
          .eq('category_id', categoryId)
          .order('verified', { ascending: false })
          .order('active_job_count', { ascending: true })
          .order('rating_avg', { ascending: false })
          .limit(limit);

        if (!error && catCityMatches && catCityMatches.length > 0) {
          console.log(`[DispatchService] Found ${catCityMatches.length} available technician(s) matching city + category.`);
          return catCityMatches;
        }
      }

      // Step 3: Available in same city
      if (cityId) {
        const { data: cityMatches, error } = await supabase
          .from('technician_profiles')
          .select(selectFields)
          .eq('availability', 'available')
          .eq('city_id', cityId)
          .order('verified', { ascending: false })
          .order('active_job_count', { ascending: true })
          .order('rating_avg', { ascending: false })
          .limit(limit);

        if (!error && cityMatches && cityMatches.length > 0) {
          console.log(`[DispatchService] Found ${cityMatches.length} available technician(s) in city.`);
          return cityMatches;
        }
      }

      // Step 4: Available matching category (any city)
      if (categoryId) {
        const { data: catMatches, error } = await supabase
          .from('technician_profiles')
          .select(selectFields)
          .eq('availability', 'available')
          .eq('category_id', categoryId)
          .order('verified', { ascending: false })
          .order('active_job_count', { ascending: true })
          .order('rating_avg', { ascending: false })
          .limit(limit);

        if (!error && catMatches && catMatches.length > 0) {
          console.log(`[DispatchService] Found ${catMatches.length} available technician(s) matching category.`);
          return catMatches;
        }
      }

      // Step 5: Global fallback — any available technician
      const { data: allAvailable, error } = await supabase
        .from('technician_profiles')
        .select(selectFields)
        .eq('availability', 'available')
        .order('verified', { ascending: false })
        .order('active_job_count', { ascending: true })
        .limit(limit);

      if (!error && allAvailable && allAvailable.length > 0) {
        console.log(`[DispatchService] Fallback found ${allAvailable.length} technician(s).`);
        return allAvailable;
      }

      return [];
    } catch (err) {
      if (err instanceof ApiError) throw err;
      console.error('[DispatchService.findAvailableTechnicians] Error:', err);
      throw ApiError.internal('Erreur inattendue du service de dispatch');
    }
  }
}

module.exports = DispatchService;
