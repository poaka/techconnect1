/**
 * Centralized Error Handler Middleware
 * Guarantees every API error strictly matches the error shape:
 * { error: { code, message, details? } }
 */

class ApiError extends Error {
  constructor(statusCode, code, message, details = null) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
  }

  static badRequest(message, details = null) {
    return new ApiError(400, 'BAD_REQUEST', message, details);
  }

  static unauthorized(message = 'Authentification requise', details = null) {
    return new ApiError(401, 'UNAUTHORIZED', message, details);
  }

  static forbidden(message = 'Accès interdit', details = null) {
    return new ApiError(403, 'FORBIDDEN', message, details);
  }

  static notFound(message = 'Ressource non trouvée', details = null) {
    return new ApiError(404, 'NOT_FOUND', message, details);
  }

  static conflict(message = 'Conflit de données', details = null) {
    return new ApiError(409, 'CONFLICT', message, details);
  }

  static internal(message = 'Erreur interne du serveur', details = null) {
    return new ApiError(500, 'INTERNAL_SERVER_ERROR', message, details);
  }
}

const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const code = err.code || 'INTERNAL_SERVER_ERROR';
  const message = err.message || 'Erreur interne du serveur';

  const response = {
    error: {
      code,
      message,
      ...(err.details && { details: err.details })
    }
  };

  if (process.env.NODE_ENV !== 'test' && statusCode >= 500) {
    console.error(`[API Error ${statusCode}] ${code}:`, err);
  }

  res.status(statusCode).json(response);
};

module.exports = {
  ApiError,
  errorHandler
};
