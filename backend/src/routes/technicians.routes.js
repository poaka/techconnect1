const express = require('express');
const { body, validationResult } = require('express-validator');
const TechniciansController = require('../controllers/technicians.controller');
const { requireAuth, requireRole } = require('../middleware/auth');
const upload = require('../middleware/upload');
const { ApiError } = require('../middleware/errorHandler');

const router = express.Router();

const validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return next(ApiError.badRequest('Données de formulaire invalides', errors.array()));
  }
  next();
};

// ─── Public routes ───────────────────────────────────────────────────────────
router.get('/categories', TechniciansController.getCategories);
router.get('/cities', TechniciansController.getCities);
router.get('/regions', TechniciansController.getRegions);

// ─── Protected /me/* routes (MUST be before /:id to avoid 'me' being an id) ─
router.get(
  '/me/stats',
  requireAuth,
  requireRole('technician'),
  TechniciansController.getMyStats
);

router.put(
  '/me/profile',
  requireAuth,
  requireRole('technician'),
  TechniciansController.updateMyProfile
);

router.put(
  '/me/availability',
  requireAuth,
  requireRole('technician'),
  [
    body('availability').isIn(['available', 'busy', 'offline']).withMessage('Statut de disponibilité invalide'),
    validateRequest
  ],
  TechniciansController.updateAvailability
);

router.post(
  '/me/documents',
  requireAuth,
  requireRole('technician'),
  upload.single('file'),
  TechniciansController.uploadDocument
);

router.get(
  '/me/documents',
  requireAuth,
  requireRole('technician'),
  TechniciansController.getMyDocuments
);

// ─── Public directory routes ──────────────────────────────────────────────────
router.get('/', TechniciansController.searchTechnicians);
router.get('/:id', TechniciansController.getTechnicianById);
router.get('/:id/reviews', TechniciansController.getTechnicianReviews);

module.exports = router;
