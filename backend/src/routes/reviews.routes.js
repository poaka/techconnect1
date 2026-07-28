const express = require('express');
const { body, validationResult } = require('express-validator');
const ReviewsController = require('../controllers/reviews.controller');
const { requireAuth, requireRole } = require('../middleware/auth');
const { ApiError } = require('../middleware/errorHandler');

const router = express.Router();

const validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return next(ApiError.badRequest('Données de formulaire invalides', errors.array()));
  }
  next();
};

router.post(
  '/',
  requireAuth,
  requireRole('client'),
  [
    body('requestId').notEmpty().withMessage('L\'identifiant de la demande est requis'),
    body('rating').isInt({ min: 1, max: 5 }).withMessage('La note doit être comprise entre 1 et 5'),
    body('comment').optional().trim(),
    validateRequest
  ],
  ReviewsController.createReview
);

router.get('/technician/:technicianId', ReviewsController.getTechnicianReviews);

module.exports = router;
