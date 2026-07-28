const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');

class FavoritesService {
  static async addFavorite(clientId, technicianId) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    const { data: techProfile, error: techErr } = await supabase
      .from('technician_profiles')
      .select('id')
      .eq('id', technicianId)
      .single();

    if (techErr || !techProfile) {
      throw ApiError.notFound('Technicien non trouvé');
    }

    const { data, error } = await supabase
      .from('favorites')
      .insert([
        {
          client_id: clientId,
          technician_id: technicianId
        }
      ])
      .select()
      .single();

    if (error) {
      if (error.code === '23505') { // Unique constraint violation
        throw ApiError.conflict('Ce technicien est déjà dans vos favoris');
      }
      console.error('[FavoritesService.addFavorite error]', error);
      throw ApiError.internal('Erreur lors de l\'ajout aux favoris');
    }

    return data;
  }

  static async removeFavorite(clientId, technicianId) {
    if (!supabase) throw ApiError.internal('Base de données indisponible');

    const { error } = await supabase
      .from('favorites')
      .delete()
      .eq('client_id', clientId)
      .eq('technician_id', technicianId);

    if (error) {
      console.error('[FavoritesService.removeFavorite error]', error);
      throw ApiError.internal('Erreur lors de la suppression des favoris');
    }

    return { message: 'Technicien retiré des favoris' };
  }

  static async getFavorites(clientId) {
    if (!supabase) return [];

    const { data, error } = await supabase
      .from('favorites')
      .select(`
        id, created_at,
        technician:technician_profiles!technician_id(
          id, bio, years_experience, price_min, price_max, whatsapp, verified, availability, rating_avg, rating_count,
          user:users!user_id(id, full_name, email, phone, avatar_url),
          city:cities!city_id(id, name, region:regions(id, name)),
          categories:technician_categories(category:categories(id, name, icon))
        )
      `)
      .eq('client_id', clientId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[FavoritesService.getFavorites error]', error);
      throw ApiError.internal('Erreur lors de la récupération des favoris');
    }

    return data || [];
  }
}

module.exports = FavoritesService;
