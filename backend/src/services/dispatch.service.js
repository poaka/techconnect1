
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
  static async findAvailableTechnicians({ categoryId, cityId, limit = 5 }) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    try {
      // Step 1: Try strict match — verified, available, same city AND same category
      let query = supabase
        .from('technician_profiles')
        .select(`
          id,
          user_id,
          bio,
          price_min,
          price_max,
          rating_avg,
          rating_count,
          active_job_count,
          category_id,
          users (
            full_name,
            avatar_url,
            phone
          )
        `)
        .eq('verified', true)
        .eq('availability', 'available')
        .eq('city_id', cityId)
        .order('active_job_count', { ascending: true })
        .order('rating_avg', { ascending: false })
        .order('created_at', { ascending: true })
        .limit(limit);

      // Only filter by category if it's present on the profile (strict match)
      if (categoryId) {
        query = query.eq('category_id', categoryId);
      }

      const { data: strictMatches, error } = await query;

      if (error) {
        console.error('[DispatchService.findAvailableTechnicians] Supabase error:', error);
        throw ApiError.internal('Erreur lors de la recherche des techniciens');
      }

      if (strictMatches && strictMatches.length > 0) {
        console.log(`[DispatchService] Found ${strictMatches.length} technician(s) with strict match (city + category).`);
        return strictMatches;
      }

      // Step 2: Fallback — same city, verified, available (ignore category — category may not be set on profile)
      console.log(`[DispatchService] No strict match found for city=${cityId} + category=${categoryId}. Falling back to city-only match.`);
      const { data: cityMatches, error: cityErr } = await supabase
        .from('technician_profiles')
        .select(`
          id,
          user_id,
          bio,
          price_min,
          price_max,
          rating_avg,
          rating_count,
          active_job_count,
          category_id,
          users (
            full_name,
            avatar_url,
            phone
          )
        `)
        .eq('verified', true)
        .eq('availability', 'available')
        .eq('city_id', cityId)
        .order('active_job_count', { ascending: true })
        .order('rating_avg', { ascending: false })
        .order('created_at', { ascending: true })
        .limit(limit);

      if (cityErr) {
        console.error('[DispatchService.findAvailableTechnicians] Fallback error:', cityErr);
        throw ApiError.internal('Erreur lors de la recherche des techniciens');
      }

      console.log(`[DispatchService] Fallback found ${cityMatches?.length ?? 0} technician(s) in city.`);
      return cityMatches || [];
    } catch (err) {
      if (err instanceof ApiError) throw err;
      console.error('[DispatchService.findAvailableTechnicians] Error:', err);
      throw ApiError.internal('Erreur inattendue du service de dispatch');
    }
  }
}

module.exports = DispatchService;
