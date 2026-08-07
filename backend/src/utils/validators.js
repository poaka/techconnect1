/**
 * Utility functions for user registration data validation and sanitization.
 */

/**
 * Validates email format strictly.
 * @param {string} email 
 * @returns {boolean}
 */
function isValidEmail(email) {
  if (!email || typeof email !== 'string') return false;
  const trimmed = email.trim();
  if (trimmed.length < 5 || trimmed.length > 255) return false;

  // RFC 5322 standard regex pattern for email format
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  if (!emailRegex.test(trimmed)) return false;

  // Check domain double dot or invalid hyphens
  const parts = trimmed.split('@');
  if (parts.length !== 2) return false;
  const domain = parts[1];
  if (domain.includes('..') || domain.startsWith('-') || domain.endsWith('-')) return false;

  return true;
}

/**
 * Validates telephone number format strictly (supports E.164 and standard 9-15 digit formats).
 * @param {string} phone 
 * @returns {boolean}
 */
function isValidPhoneNumber(phone) {
  if (!phone || typeof phone !== 'string') return false;
  const cleaned = phone.replace(/[\s\-\(\)\.]/g, '');
  if (cleaned.length === 0) return false;

  // Must match optional leading + followed by 9 to 15 digits
  const phoneRegex = /^\+?[0-9]{9,15}$/;
  return phoneRegex.test(cleaned);
}

/**
 * Sanitizes and normalizes an email address.
 * @param {string} email 
 * @returns {string|null}
 */
function sanitizeEmail(email) {
  if (!email || typeof email !== 'string') return null;
  return email.trim().toLowerCase();
}

/**
 * Sanitizes and normalizes a phone number.
 * @param {string} phone 
 * @returns {string|null}
 */
function sanitizePhone(phone) {
  if (!phone || typeof phone !== 'string') return null;
  const cleaned = phone.replace(/[\s\-\(\)\.]/g, '').trim();
  if (!cleaned) return null;
  return cleaned;
}

module.exports = {
  isValidEmail,
  isValidPhoneNumber,
  sanitizeEmail,
  sanitizePhone
};
