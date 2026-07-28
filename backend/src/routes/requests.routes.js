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
    body('technicianId').notEmpty().withMessage('L\'identifiant du technicien est requis'),
    body('description').trim().notEmpty().withMessage('La description de la demande est requise'),
    validateRequest
  ],
  RequestsController.createRequest
);

router.get('/', RequestsController.getRequests);
router.get('/:id', RequestsController.getRequestById);

router.patch(
  '/:id/status',
  [
    body('status').isIn(['pending', 'accepted', 'rejected', 'in_progress', 'completed', 'cancelled']).withMessage('Statut invalide'),
    validateRequest
  ],
  RequestsController.updateRequestStatus
);

module.exports = router;
