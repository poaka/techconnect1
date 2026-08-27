const express = require('express');
const OffersController = require('../controllers/offers.controller');
const { requireAuth, requireRole } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);
router.use(requireRole('technician'));

router.get('/', OffersController.getOffers);
router.post('/:id/accept', OffersController.acceptOffer);
router.post('/:id/reject', OffersController.rejectOffer);

module.exports = router;
