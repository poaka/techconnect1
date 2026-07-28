const express = require('express');
const { body, validationResult } = require('express-validator');
const AdminController = require('../controllers/admin.controller');
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
router.use(requireRole('admin'));

router.get('/verifications', AdminController.getPendingVerifications);
router.patch(
  '/verifications/:documentId',
  [
    body('status').isIn(['approved', 'rejected']).withMessage('Statut de décision invalide'),
    body('rejectionReason').optional().trim(),
    validateRequest
  ],
  AdminController.reviewDocument
);
router.get('/stats', AdminController.getPlatformStats);

module.exports = router;
