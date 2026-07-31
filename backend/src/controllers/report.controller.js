const ReportService = require('../services/report.service');
const { ApiError } = require('../middleware/errorHandler');

class ReportController {
  static async createReport(req, res, next) {
    try {
      const { technician_id, reason, details } = req.body;
      const client_id = req.user.id;
      
      if (!technician_id || !reason) {
        throw ApiError.badRequest('technician_id and reason are required');
      }

      const report = await ReportService.createReport({ client_id, technician_id, reason, details });
      res.status(201).json({ success: true, data: report });
    } catch (error) {
      next(error);
    }
  }

  static async getReports(req, res, next) {
    try {
      const { status } = req.query;
      const reports = await ReportService.getReports(status);
      res.json({ success: true, data: reports });
    } catch (error) {
      next(error);
    }
  }

  static async resolveReport(req, res, next) {
    try {
      const { id } = req.params;
      const { action_taken } = req.body;
      const report = await ReportService.resolveReport(id, action_taken);
      res.json({ success: true, data: report });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = ReportController;
