const AdminService = require('../services/admin.service');

class AdminController {
  // Verifications
  static async getPendingVerifications(req, res, next) {
    try {
      const verifications = await AdminService.getPendingVerifications();
      res.status(200).json({ data: verifications });
    } catch (error) { next(error); }
  }

  static async reviewDocument(req, res, next) {
    try {
      const { status, rejectionReason } = req.body;
      const result = await AdminService.reviewDocument(req.params.documentId, status, rejectionReason);
      res.status(200).json({ data: result });
    } catch (error) { next(error); }
  }

  // Platform Stats
  static async getPlatformStats(req, res, next) {
    try {
      const stats = await AdminService.getPlatformStats();
      res.status(200).json({ data: stats });
    } catch (error) { next(error); }
  }

  // Users
  static async getUsers(req, res, next) {
    try {
      const { search, role } = req.query;
      const users = await AdminService.getUsers({ search, role });
      res.status(200).json({ data: users });
    } catch (error) { next(error); }
  }

  static async deleteUser(req, res, next) {
    try {
      const result = await AdminService.deleteUser(req.params.userId);
      res.status(200).json({ data: result });
    } catch (error) { next(error); }
  }

  // Technicians
  static async getTechnicians(req, res, next) {
    try {
      const technicians = await AdminService.getTechnicians();
      res.status(200).json({ data: technicians });
    } catch (error) { next(error); }
  }

  // Categories
  static async getCategories(req, res, next) {
    try {
      const categories = await AdminService.getCategories();
      res.status(200).json({ data: categories });
    } catch (error) { next(error); }
  }

  static async createCategory(req, res, next) {
    try {
      const category = await AdminService.createCategory(req.body);
      res.status(201).json({ data: category });
    } catch (error) { next(error); }
  }

  static async updateCategory(req, res, next) {
    try {
      const category = await AdminService.updateCategory(req.params.categoryId, req.body);
      res.status(200).json({ data: category });
    } catch (error) { next(error); }
  }

  static async deleteCategory(req, res, next) {
    try {
      const result = await AdminService.deleteCategory(req.params.categoryId);
      res.status(200).json({ data: result });
    } catch (error) { next(error); }
  }

  // Regions
  static async getRegions(req, res, next) {
    try {
      const regions = await AdminService.getRegions();
      res.status(200).json({ data: regions });
    } catch (error) { next(error); }
  }
}

module.exports = AdminController;
