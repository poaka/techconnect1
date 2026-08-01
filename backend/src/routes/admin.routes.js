const express = require('express');
const { body, validationResult } = require('express-validator');
const AdminController = require('../controllers/admin.controller');
const { requireAuth, requireRole } = require('../middleware/auth');
const { ApiError } = require('../middleware/errorHandler');

const router = express.Router();

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return next(ApiError.badRequest('Données de formulaire invalides', errors.array()));
  }
  next();
};

// All admin routes require auth + admin role
router.use(requireAuth);
router.use(requireRole('admin'));

// ── Platform Stats ────────────────────────────────────────────────────────
router.get('/stats', AdminController.getPlatformStats);

// ── Verifications ─────────────────────────────────────────────────────────
router.get('/verifications', AdminController.getPendingVerifications);
router.get('/verifications/rejected', AdminController.getRejectedVerifications);
router.patch(
  '/verifications/:documentId',
  [
    body('status').isIn(['approved', 'rejected']).withMessage('Statut de décision invalide'),
    body('rejectionReason').optional().trim(),
    validate
  ],
  AdminController.reviewDocument
);

// ── Users ─────────────────────────────────────────────────────────────────
router.get('/users', AdminController.getUsers);
router.delete('/users/:userId', AdminController.deleteUser);

// ── Technicians ───────────────────────────────────────────────────────────
router.get('/technicians', AdminController.getTechnicians);

// ── Service Requests ──────────────────────────────────────────────────────
router.get('/requests', AdminController.getServiceRequests);

// ── Categories ────────────────────────────────────────────────────────────
router.get('/categories', AdminController.getCategories);
router.post(
  '/categories',
  [
    body('name').trim().notEmpty().withMessage('Le nom est requis'),
    body('icon').optional().trim(),
    body('description').optional().trim(),
    validate
  ],
  AdminController.createCategory
);
router.put(
  '/categories/:categoryId',
  [
    body('name').optional().trim().notEmpty().withMessage('Le nom ne peut pas être vide'),
    body('icon').optional().trim(),
    body('description').optional().trim(),
    validate
  ],
  AdminController.updateCategory
);
router.delete('/categories/:categoryId', AdminController.deleteCategory);

// ── Regions & Cities ──────────────────────────────────────────────────────
router.get('/regions', AdminController.getRegions);

router.post(
  '/regions',
  [
    body('name').trim().notEmpty().withMessage('Le nom est requis'),
    validate
  ],
  AdminController.createRegion
);
router.put(
  '/regions/:regionId',
  [
    body('name').trim().notEmpty().withMessage('Le nom est requis'),
    validate
  ],
  AdminController.updateRegion
);
router.delete('/regions/:regionId', AdminController.deleteRegion);

router.post(
  '/cities',
  [
    body('name').trim().notEmpty().withMessage('Le nom est requis'),
    body('regionId').notEmpty().withMessage('L\'ID de la région est requis'),
    validate
  ],
  AdminController.createCity
);
router.put(
  '/cities/:cityId',
  [
    body('name').optional().trim().notEmpty().withMessage('Le nom ne peut pas être vide'),
    body('regionId').optional().notEmpty().withMessage('L\'ID de la région ne peut pas être vide'),
    validate
  ],
  AdminController.updateCity
);
router.delete('/cities/:cityId', AdminController.deleteCity);

module.exports = router;
