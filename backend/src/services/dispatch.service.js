const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');

class DispatchService {
  /**
   * Find the most suitable, verified, and available technicians for a given request.
   * Uses active_job_count to balance load, with deterministic tie-breakers (rating, then created_at).
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
      const { data, error } = await supabase
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
          users (
            full_name,
            avatar_url,
            phone
          )
        `)
        .eq('verified', true)
        .eq('availability', 'available')
        .eq('category_id', categoryId)
        .eq('city_id', cityId)
        .order('active_job_count', { ascending: true }) // Primary: Load balancing
        .order('rating_avg', { ascending: false }) // Tie-breaker 1: Highest rating first
        .order('created_at', { ascending: true }) // Tie-breaker 2: Oldest joined first (deterministic)
        .limit(limit);

      if (error) {
        console.error('[DispatchService.findAvailableTechnicians] Supabase error:', error);
        throw ApiError.internal('Erreur lors de la recherche des techniciens');
      }

      return data || [];
    } catch (err) {
      if (err instanceof ApiError) throw err;
      console.error('[DispatchService.findAvailableTechnicians] Error:', err);
      throw ApiError.internal('Erreur inattendue du service de dispatch');
    }
  }
}

module.exports = DispatchService;
