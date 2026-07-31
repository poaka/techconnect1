const express = require('express');
const { body, validationResult } = require('express-validator');
const AuthController = require('../controllers/auth.controller');
const { requireAuth } = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimit');
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
  '/register',
  authLimiter,
  [
    body('fullName').trim().notEmpty().withMessage('Le nom complet est requis'),
    body('email').trim().isEmail().withMessage('Adresse email invalide'),
    body('password').isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères'),
    body('role').optional().isIn(['client', 'technician']).withMessage('Rôle invalide'),
    validateRequest
  ],
  AuthController.register
);

router.post(
  '/login',
  authLimiter,
  [
    body('email').trim().isEmail().withMessage('Adresse email invalide'),
    body('password').notEmpty().withMessage('Le mot de passe est requis'),
    validateRequest
  ],
  AuthController.login
);

router.get('/me', requireAuth, AuthController.me);

router.put(
  '/me',
  requireAuth,
  [
    body('fullName').optional().trim().notEmpty().withMessage('Le nom complet ne peut pas être vide'),
    body('phone').optional().trim(),
    validateRequest
  ],
  AuthController.updateMe
);

router.post(
  '/change-password',
  requireAuth,
  authLimiter,
  [
    body('oldPassword').notEmpty().withMessage('L\'ancien mot de passe est requis'),
    body('newPassword').isLength({ min: 6 }).withMessage('Le nouveau mot de passe doit contenir au moins 6 caractères'),
    validateRequest
  ],
  AuthController.changePassword
);

module.exports = router;
