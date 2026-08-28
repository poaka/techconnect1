const express = require('express');
const { body, validationResult } = require('express-validator');
const RequestsController = require('../controllers/requests.controller');
const { requireAuth, requireRole } = require('../middleware/auth');
const { ApiError } = require('../middleware/errorHandler');
const upload = require('../middleware/upload');

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
  upload.single('image'),
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
router.put('/:id', requireRole('client'), RequestsController.updateRequest);
router.delete('/:id', requireRole('client'), RequestsController.deleteRequest);
router.post('/:id/cancel', requireRole('client'), RequestsController.cancelRequest);
router.post('/:id/complete', requireRole('technician'), RequestsController.completeRequest);

// GPS Endpoints (Phase 7)
router.post(
  '/:id/location',
  requireRole('technician'),
  [
    body('latitude').isNumeric().withMessage('Latitude valide requise'),
    body('longitude').isNumeric().withMessage('Longitude valide requise'),
    validateRequest
  ],
  RequestsController.updateLocation
);
router.get('/:id/location', RequestsController.getLocation);

module.exports = router;
