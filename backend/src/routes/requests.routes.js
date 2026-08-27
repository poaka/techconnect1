const express = require('express');
const { body, validationResult } = require('express-validator');
const RequestsController = require('../controllers/requests.controller');
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

router.use(requireAuth);

router.post(
  '/',
  requireRole('client'),
  [
    body('categoryId').notEmpty().withMessage('La catégorie est requise'),
    body('cityId').notEmpty().withMessage('La ville est requise'),
    body('description').trim().notEmpty().withMessage('La description de la demande est requise'),
    body('latitude').optional().isNumeric(),
    body('longitude').optional().isNumeric(),
    validateRequest
  ],
  RequestsController.createRequest
);

router.get('/', RequestsController.getRequests);
router.get('/:id', RequestsController.getRequestById);

// Lifecycle Endpoints
router.post('/:id/cancel', requireRole('client'), RequestsController.cancelRequest);
router.post('/:id/complete', requireRole('technician'), RequestsController.completeRequest);

module.exports = router;
