const TechniciansService = require('../services/technicians.service');
const ReviewsService = require('../services/reviews.service');

class TechniciansController {
  static async getCategories(req, res, next) {
    try {
      const categories = await TechniciansService.getCategories();
      res.status(200).json({ data: categories });
    } catch (error) {
      next(error);
    }
  }

  static async getCities(req, res, next) {
    try {
      const cities = await TechniciansService.getCities();
      res.status(200).json({ data: cities });
    } catch (error) {
      next(error);
    }
  }

  static async getRegions(req, res, next) {
    try {
      const regions = await TechniciansService.getRegions();
      res.status(200).json({ data: regions });
    } catch (error) {
      next(error);
    }
  }

  static async searchTechnicians(req, res, next) {
    try {
      const result = await TechniciansService.searchTechnicians(req.query);
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  }

  static async getTechnicianById(req, res, next) {
    try {
      const technician = await TechniciansService.getTechnicianById(req.params.id);
      res.status(200).json({ data: technician });
    } catch (error) {
      next(error);
    }
  }

  static async getTechnicianReviews(req, res, next) {
    try {
      const reviews = await TechniciansService.getTechnicianReviewsById(req.params.id);
      res.status(200).json({ data: reviews });
    } catch (error) {
      next(error);
    }
  }

  static async updateMyProfile(req, res, next) {
    try {
      const updatedProfile = await TechniciansService.updateMyProfile(req.user.id, req.body);
      res.status(200).json({ data: updatedProfile });
    } catch (error) {
      next(error);
    }
  }

  static async updateAvailability(req, res, next) {
    try {
      const { availability } = req.body;
      const result = await TechniciansService.updateAvailability(req.user.id, availability);
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  }

  static async uploadDocument(req, res, next) {
    try {
      const { documentType } = req.body;
      const file = req.file;
      const document = await TechniciansService.uploadDocument(req.user.id, documentType, file);
      res.status(201).json({ data: document });
    } catch (error) {
      next(error);
    }
  }

  static async getMyDocuments(req, res, next) {
    try {
      const documents = await TechniciansService.getMyDocuments(req.user.id);
      res.status(200).json({ data: documents });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/technicians/me/stats
   * Returns aggregated stats for the authenticated technician's dashboard.
   */
  static async getMyStats(req, res, next) {
    try {
      const stats = await TechniciansService.getTechnicianStats(req.user.id);
      res.status(200).json({ data: stats });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = TechniciansController;
