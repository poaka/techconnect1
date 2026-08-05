const AuthService = require('../services/auth.service');

class AuthController {
  static async register(req, res, next) {
    try {
      const { fullName, email, phone, password, role } = req.body;
      const result = await AuthService.register({ fullName, email, phone, password, role });
      res.status(201).json({
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  static async login(req, res, next) {
    try {
      const { email, password } = req.body;
      const result = await AuthService.login({ email, password });
      res.status(200).json({
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  static async me(req, res, next) {
    try {
      const user = await AuthService.getMe(req.user.id);
      res.status(200).json({
        data: user
      });
    } catch (error) {
      next(error);
    }
  }

  static async updateMe(req, res, next) {
    try {
      const { fullName, phone } = req.body;
      const user = await AuthService.updateMe(req.user.id, { fullName, phone });
      res.status(200).json({
        data: user
      });
    } catch (error) {
      next(error);
    }
  }

  static async changePassword(req, res, next) {
    try {
      const { oldPassword, newPassword } = req.body;
      await AuthService.changePassword(req.user.id, oldPassword, newPassword);
      res.status(200).json({
        data: { success: true, message: 'Mot de passe modifié avec succès' }
      });
    } catch (error) {
      next(error);
    }
  }

  static async uploadAvatar(req, res, next) {
    try {
      const baseUrl = `${req.protocol}://${req.get('host')}`;
      const result = await AuthService.uploadAvatar(req.user.id, req.file, baseUrl);
      res.status(200).json({
        data: result
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = AuthController;
