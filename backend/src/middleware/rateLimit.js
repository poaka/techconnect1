const rateLimit = require('express-rate-limit');
const env = require('../config/env');

const authLimiter = rateLimit({
  windowMs: env.authRateLimitWindowMs,
  max: env.authRateLimitMax,
  message: {
    error: {
      code: 'TOO_MANY_REQUESTS',
      message: 'Trop de tentatives. Veuillez réessayer plus tard.'
    }
  },
  standardHeaders: true,
  legacyHeaders: false
});

module.exports = {
  authLimiter
};
