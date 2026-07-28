const express = require('express');
const FavoritesController = require('../controllers/favorites.controller');
const { requireAuth, requireRole } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);
router.use(requireRole('client'));

router.post('/:technicianId', FavoritesController.addFavorite);
router.delete('/:technicianId', FavoritesController.removeFavorite);
router.get('/', FavoritesController.getFavorites);

module.exports = router;
