const NotificationsService = require('../services/notifications.service');

class NotificationsController {
  static async getNotifications(req, res, next) {
    try {
      const data = await NotificationsService.getNotifications(req.user.id);
      res.status(200).json({ data });
    } catch (error) {
      next(error);
    }
  }

  static async markAsRead(req, res, next) {
    try {
      const notification = await NotificationsService.markAsRead(req.user.id, req.params.id);
      res.status(200).json({ data: notification });
    } catch (error) {
      next(error);
    }
  }

  static async markAllAsRead(req, res, next) {
    try {
      const result = await NotificationsService.markAllAsRead(req.user.id);
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = NotificationsController;
