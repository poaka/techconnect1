const express = require('express');
const NotificationsController = require('../controllers/notifications.controller');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);

router.get('/', NotificationsController.getNotifications);
router.patch('/read-all', NotificationsController.markAllAsRead);
router.patch('/:id/read', NotificationsController.markAsRead);

module.exports = router;
