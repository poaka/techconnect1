/**
 * Local Verification Script for Phase 0 Backend API
 */

const app = require('../src/index');
const http = require('http');

let server;

function startServer() {
  return new Promise((resolve) => {
    server = app.listen(5001, () => {
      console.log('[Test Server] Launched on port 5001');
      resolve();
    });
  });
}

function makeRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 5001,
      path,
      method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

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

async function runTests() {
  await startServer();

  console.log('\n--- Running Phase 0 Backend Tests ---\n');

  try {
    // 1. Health check
    const health = await makeRequest('GET', '/health');
    console.log('1. GET /health:', health.status === 200 ? '✅ PASSED' : '❌ FAILED', health.body);

    // 2. Auth Register Client
    const regClient = await makeRequest('POST', '/api/auth/register', {
      fullName: 'Test Client',
      email: `client_${Date.now()}@test.cm`,
      password: 'Password123!',
      role: 'client'
    });
    console.log('2. POST /api/auth/register (Client):', regClient.status === 201 ? '✅ PASSED' : '❌ FAILED', regClient.body);

    // 3. Auth Register Technician
    const regTech = await makeRequest('POST', '/api/auth/register', {
      fullName: 'Test Tech',
      email: `tech_${Date.now()}@test.cm`,
      password: 'Password123!',
      role: 'technician'
    });
    console.log('3. POST /api/auth/register (Technician):', regTech.status === 201 ? '✅ PASSED' : '❌ FAILED', regTech.body);

    // 4. Categories list
    const categories = await makeRequest('GET', '/api/technicians/categories');
    console.log('4. GET /api/technicians/categories:', categories.status === 200 ? '✅ PASSED' : '❌ FAILED', `Found ${categories.body?.data?.length || 0} categories`);

    // 5. Regions list
    const regions = await makeRequest('GET', '/api/technicians/regions');
    console.log('5. GET /api/technicians/regions:', regions.status === 200 ? '✅ PASSED' : '❌ FAILED', `Found ${regions.body?.data?.length || 0} regions`);

    // 6. Search Technicians
    const search = await makeRequest('GET', '/api/technicians?page=1&limit=5');
    console.log('6. GET /api/technicians:', search.status === 200 ? '✅ PASSED' : '❌ FAILED');

    // 7. Get Me with JWT Token
    if (regClient.body?.data?.token) {
      const me = await makeRequest('GET', '/api/auth/me', null, regClient.body.data.token);
      console.log('7. GET /api/auth/me:', me.status === 200 ? '✅ PASSED' : '❌ FAILED', me.body?.data?.email);
    }

    console.log('\n--- All Automated Smoke Tests Completed ---\n');
  } catch (error) {
    console.error('Test execution error:', error);
  } finally {
    server.close();
    process.exit(0);
  }
}

runTests();
