/**
 * Verification Test Suite for User Registration Email & Phone Format Verification & Validation.
 */

const assert = require('assert');
const http = require('http');
const app = require('../src/index');
const { isValidEmail, isValidPhoneNumber, sanitizeEmail, sanitizePhone } = require('../src/utils/validators');

let server;
const PORT = 5002;

function startServer() {
  return new Promise((resolve) => {
    server = app.listen(PORT, () => {
      console.log(`[Test Server] Running on http://localhost:${PORT}`);
      resolve();
    });
  });
}

function makeRequest(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: PORT,
      path,
      method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, body: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function runVerificationTests() {
  console.log('\n======================================================');
  console.log('--- STARTING REGISTRATION VERIFICATION TEST SUITE ---');
  console.log('======================================================\n');

  // Step 1: Unit tests for validators.js
  console.log('--- Step 1: Unit Testing Validators Utility ---');
  
  // Email validation unit tests
  assert.strictEqual(isValidEmail('test@domain.cm'), true, 'Valid email should pass');
  assert.strictEqual(isValidEmail('user.name+tag@sub.domain.com'), true, 'Complex valid email should pass');
  assert.strictEqual(isValidEmail('invalid-email'), false, 'Email without @ should fail');
  assert.strictEqual(isValidEmail('user@domain'), false, 'Email without TLD should fail');
  assert.strictEqual(isValidEmail('user@..com'), false, 'Email with double dot domain should fail');
  assert.strictEqual(isValidEmail(''), false, 'Empty string should fail');
  console.log('✅ Unit tests for isValidEmail passed.');

  // Phone validation unit tests
  assert.strictEqual(isValidPhoneNumber('+237690000000'), true, 'Valid Cameroonian E.164 phone should pass');
  assert.strictEqual(isValidPhoneNumber('690000000'), true, '9 digit phone without plus should pass');
  assert.strictEqual(isValidPhoneNumber('+237 690-00-00-00'), true, 'Phone with spaces/dashes should pass');
  assert.strictEqual(isValidPhoneNumber('12345'), false, 'Phone with less than 9 digits should fail');
  assert.strictEqual(isValidPhoneNumber('abc123456789'), false, 'Phone with letters should fail');
  assert.strictEqual(isValidPhoneNumber(''), false, 'Empty phone should fail');
  console.log('✅ Unit tests for isValidPhoneNumber passed.');

  // Sanitization unit tests
  assert.strictEqual(sanitizeEmail('  USER@Domain.COM '), 'user@domain.com');
  assert.strictEqual(sanitizePhone('+237 (690) 00-00-00'), '+237690000000');
  console.log('✅ Unit tests for email and phone sanitization passed.\n');

  // Step 2: API Integration tests
  await startServer();
  console.log('--- Step 2: API Integration Tests ---');

  try {
    // Test 2.1: Invalid Email Format on POST /api/auth/register
    const resBadEmail = await makeRequest('POST', '/api/auth/register', {
      fullName: 'Test User',
      email: 'invalid_email_format',
      phone: '+237699999999',
      password: 'Password123!',
      role: 'client'
    });
    console.log('2.1 Rejects invalid email format:', resBadEmail.status === 400 ? '✅ PASSED' : '❌ FAILED', `(Status: ${resBadEmail.status})`);
    assert.strictEqual(resBadEmail.status, 400, 'Should return 400 Bad Request for invalid email format');

    // Test 2.2: Invalid Phone Format on POST /api/auth/register
    const resBadPhone = await makeRequest('POST', '/api/auth/register', {
      fullName: 'Test User',
      email: 'valid_user@test.cm',
      phone: '12345', // Too short (5 digits)
      password: 'Password123!',
      role: 'client'
    });
    console.log('2.2 Rejects invalid phone format:', resBadPhone.status === 400 ? '✅ PASSED' : '❌ FAILED', `(Status: ${resBadPhone.status})`);
    assert.strictEqual(resBadPhone.status, 400, 'Should return 400 Bad Request for invalid phone format');

    // Test 2.3: Successful Registration with valid format
    const testEmail = `verified_${Date.now()}@test.cm`;
    const testPhone = `+2376${Math.floor(10000000 + Math.random() * 90000000)}`;

    const resSuccess = await makeRequest('POST', '/api/auth/register', {
      fullName: 'Valid User Verification',
      email: testEmail,
      phone: testPhone,
      password: 'Password123!',
      role: 'client'
    });
    console.log('2.3 Accepts valid format registration:', resSuccess.status === 201 ? '✅ PASSED' : '❌ FAILED', `(User ID: ${resSuccess.body?.data?.user?.id || 'N/A'})`);
    assert.strictEqual(resSuccess.status, 201, 'Should return 201 Created for valid registration');
    assert.strictEqual(resSuccess.body?.data?.user?.email, testEmail.toLowerCase());

    // Test 2.4: Reject Duplicate Phone Number
    const resDupPhone = await makeRequest('POST', '/api/auth/register', {
      fullName: 'Another User',
      email: `another_${Date.now()}@test.cm`,
      phone: testPhone, // Same phone number as previous registration
      password: 'Password123!',
      role: 'client'
    });
    console.log('2.4 Rejects duplicate phone number:', resDupPhone.status === 409 ? '✅ PASSED' : '❌ FAILED', `(Status: ${resDupPhone.status})`);
    assert.strictEqual(resDupPhone.status, 409, 'Should return 409 Conflict for duplicate phone number');

    console.log('\n======================================================');
    console.log('🎉 ALL VERIFICATION AND VALIDATION TESTS PASSED!');
    console.log('======================================================\n');
  } catch (error) {
    console.error('❌ Test failed with error:', error);
    process.exitCode = 1;
  } finally {
    server.close();
    process.exit();
  }
}

runVerificationTests();
