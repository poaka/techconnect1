const AdminService = require('../services/admin.service');

class AdminController {
  static async getPendingVerifications(req, res, next) {
    try {
      const verifications = await AdminService.getPendingVerifications();
      res.status(200).json({ data: verifications });
    } catch (error) {
      next(error);
    }
  }

  static async reviewDocument(req, res, next) {
    try {
      const { status, rejectionReason } = req.body;
      const result = await AdminService.reviewDocument(req.params.documentId, status, rejectionReason);
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  }

  static async getPlatformStats(req, res, next) {
    try {
      const stats = await AdminService.getPlatformStats();
      res.status(200).json({ data: stats });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = AdminController;
