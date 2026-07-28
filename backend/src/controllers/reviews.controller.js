const ReviewsService = require('../services/reviews.service');

class ReviewsController {
  static async createReview(req, res, next) {
    try {
      const review = await ReviewsService.createReview(req.user.id, req.body);
      res.status(201).json({ data: review });
    } catch (error) {
      next(error);
    }
  }

  static async getTechnicianReviews(req, res, next) {
    try {
      const reviews = await ReviewsService.getTechnicianReviews(req.params.technicianId);
      res.status(200).json({ data: reviews });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = ReviewsController;
