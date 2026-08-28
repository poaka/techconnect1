const OffersService = require('../services/offers.service');
const supabase = require('../config/supabase');
const { ApiError } = require('../middleware/errorHandler');

class OffersController {
  static async getOffers(req, res, next) {
    try {
      if (!supabase) throw ApiError.internal('Base de données indisponible');
      
      const { data: profile } = await supabase
        .from('technician_profiles')
        .select('id')
        .eq('user_id', req.user.id)
        .single();
        
      if (!profile) return res.status(200).json({ data: [] });

      const { data, error } = await supabase
        .from('job_offers')
        .select(`
          id, status,
          request:service_requests(
            id, description, address, latitude, longitude, created_at,
            city:cities(name),
            category:categories(name, icon),
            client:users!client_id(full_name, avatar_url)
          )
        `)
        .eq('technician_id', profile.id);

      if (error) {
        console.error('Supabase error in getOffers:', error);
        require('fs').writeFileSync('offers_error.log', JSON.stringify(error, null, 2));
        throw ApiError.internal('Erreur lors de la récupération des offres');
      }

      res.status(200).json({ data: data || [] });
    } catch (error) {
      next(error);
    }
  }

  static async acceptOffer(req, res, next) {
    try {
      const { data: profile } = await supabase
        .from('technician_profiles')
        .select('id')
        .eq('user_id', req.user.id)
        .single();
        
      if (!profile) throw ApiError.forbidden('Profil technicien introuvable');

      const result = await OffersService.acceptOffer(req.params.id, profile.id);
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  }

  static async rejectOffer(req, res, next) {
    try {
      const { data: profile } = await supabase
        .from('technician_profiles')
        .select('id')
        .eq('user_id', req.user.id)
        .single();
        
      if (!profile) throw ApiError.forbidden('Profil technicien introuvable');

      const result = await OffersService.rejectOffer(req.params.id, profile.id);
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = OffersController;
