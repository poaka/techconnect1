const RequestsService = require('../services/requests.service');

class RequestsController {
  static async createRequest(req, res, next) {
    try {
      const request = await RequestsService.createRequest(req.user.id, req.body);
      res.status(201).json({ data: request });
    } catch (error) {
      next(error);
    }
  }

  static async getRequests(req, res, next) {
    try {
      const requests = await RequestsService.getRequests(req.user.id, req.user.role, req.query.status);
      res.status(200).json({ data: requests });
    } catch (error) {
      next(error);
    }
  }

  static async getRequestById(req, res, next) {
    try {
      const request = await RequestsService.getRequestById(req.params.id, req.user.id, req.user.role);
      res.status(200).json({ data: request });
    } catch (error) {
      next(error);
    }
  }

  static async updateRequestStatus(req, res, next) {
    try {
      const { status } = req.body;
      const updated = await RequestsService.updateRequestStatus(req.params.id, req.user.id, req.user.role, status);
      res.status(200).json({ data: updated });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = RequestsController;
