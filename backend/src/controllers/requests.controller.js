const RequestsService = require('../services/requests.service');

class RequestsController {
  static async createRequest(req, res, next) {
    try {
      const request = await RequestsService.createRequest(req.user.id, req.body, req.file);
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

  static async cancelRequest(req, res, next) {
    try {
      const updated = await RequestsService.cancelRequest(req.params.id, req.user.id);
      res.status(200).json({ data: updated });
    } catch (error) {
      next(error);
    }
  }

  static async completeRequest(req, res, next) {
    try {
      const updated = await RequestsService.completeRequest(req.params.id, req.user.id);
      res.status(200).json({ data: updated });
    } catch (error) {
      next(error);
    }
  }
  static async updateLocation(req, res, next) {
    try {
      const { latitude, longitude } = req.body;
      const updated = await RequestsService.updateLocation(req.params.id, req.user.id, latitude, longitude);
      res.status(200).json({ data: updated });
    } catch (error) {
      next(error);
    }
  }

  static async getLocation(req, res, next) {
    try {
      const location = await RequestsService.getLocation(req.params.id, req.user.id, req.user.role);
      res.status(200).json({ data: location });
    } catch (error) {
      next(error);
  }

  static async updateRequest(req, res, next) {
    try {
      const updated = await RequestsService.updateRequest(req.params.id, req.user.id, req.body);
      res.status(200).json({ data: updated });
    } catch (error) {
      next(error);
    }
  }

  static async deleteRequest(req, res, next) {
    try {
      const result = await RequestsService.deleteRequest(req.params.id, req.user.id);
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = RequestsController;
