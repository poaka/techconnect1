const FavoritesService = require('../services/favorites.service');

class FavoritesController {
  static async addFavorite(req, res, next) {
    try {
      const favorite = await FavoritesService.addFavorite(req.user.id, req.params.technicianId);
      res.status(201).json({ data: favorite });
    } catch (error) {
      next(error);
    }
  }

  static async removeFavorite(req, res, next) {
    try {
      const result = await FavoritesService.removeFavorite(req.user.id, req.params.technicianId);
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  }

  static async getFavorites(req, res, next) {
    try {
      const favorites = await FavoritesService.getFavorites(req.user.id);
      res.status(200).json({ data: favorites });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = FavoritesController;
