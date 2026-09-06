const http = require('http');
const app = require('../src/index');

async function runComprehensiveTests() {
  console.log('--- Starting FixerPro Full Stack (Backend + Admin) Test Suite ---');
  
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(5002, resolve));
  console.log('[Test Server] Listening on port 5002');
  
  const baseUrl = 'http://localhost:5002';
  
  let clientToken = '';
  let clientUser = null;
  let techToken = '';
  let techUser = null;
  let adminToken = '';
  let requestId = '';
  let offerId = '';
  let cityId = '';
  let categoryId = '';
  let techProfileId = '';
  
  let passedCount = 0;
  let failedCount = 0;
  
  async function apiCall(method, path, body = null, token = null) {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;
    
    const options = {
      method,
      headers
    };
    
    return new Promise((resolve, reject) => {
      const req = http.request(`${baseUrl}${path}`, options, (res) => {
        let raw = '';
        res.on('data', chunk => raw += chunk);
        res.on('end', () => {
          let json = {};
          try {
            json = JSON.parse(raw);
          } catch(e) {
            json = { raw };
          }
          resolve({ status: res.statusCode, body: json });
        });
      });
      req.on('error', reject);
      if (body) req.write(JSON.stringify(body));
      req.end();
    });
  }

  function assertTest(name, condition, details = '') {
    if (condition) {
      console.log(`✅ [PASS] ${name}`);
      passedCount++;
    } else {
      console.error(`❌ [FAIL] ${name} ${details}`);
      failedCount++;
    }
  }

  try {
    // 1. Health check
    const healthRes = await apiCall('GET', '/health');
    assertTest('GET /health', healthRes.status === 200 && healthRes.body.status === 'ok');

    // 2. Auth: Register Client
    const time = Date.now();
    const clientEmail = `client_${time}@test.com`;
    const regClientRes = await apiCall('POST', '/api/auth/register', {
      email: clientEmail,
      password: 'password123',
      fullName: 'Test Client',
      role: 'client',
      phone: `+2376${time.toString().slice(-8)}`
    });
    assertTest('POST /api/auth/register (Client)', regClientRes.status === 201 && regClientRes.body.data?.token, JSON.stringify(regClientRes.body));
    clientToken = regClientRes.body.data?.token;
    clientUser = regClientRes.body.data?.user;

    // 3. Auth: Register Tech
    const techEmail = `tech_${time}@test.com`;
    const regTechRes = await apiCall('POST', '/api/auth/register', {
      email: techEmail,
      password: 'password123',
      fullName: 'Test Technician',
      role: 'technician',
      phone: `+2376${(time + 1).toString().slice(-8)}`
    });
    assertTest('POST /api/auth/register (Tech)', regTechRes.status === 201 && regTechRes.body.data?.token, JSON.stringify(regTechRes.body));
    techToken = regTechRes.body.data?.token;
    techUser = regTechRes.body.data?.user;

    // 4. Auth: Login Client
    const loginRes = await apiCall('POST', '/api/auth/login', {
      email: clientEmail,
      password: 'password123'
    });
    assertTest('POST /api/auth/login (Client)', loginRes.status === 200 && loginRes.body.data?.token, JSON.stringify(loginRes.body));

    // 5. Auth: Me Endpoint
    const meRes = await apiCall('GET', '/api/auth/me', null, clientToken);
    assertTest('GET /api/auth/me', meRes.status === 200 && meRes.body.data?.email === clientEmail);

    // 6. Categories, Regions, Cities
    const catRes = await apiCall('GET', '/api/technicians/categories');
    assertTest('GET /api/technicians/categories', catRes.status === 200 && Array.isArray(catRes.body.data));
    categoryId = catRes.body.data?.[0]?.id;

    const citiesRes = await apiCall('GET', '/api/technicians/cities');
    assertTest('GET /api/technicians/cities', citiesRes.status === 200 && Array.isArray(citiesRes.body.data));
    cityId = citiesRes.body.data?.[0]?.id;

    // 7. Technicians: Setup Tech Profile
    const updateProfileRes = await apiCall('PUT', '/api/technicians/me/profile', {
      bio: 'Expert certified technician',
      yearsExperience: 5,
      priceMin: 5000,
      priceMax: 25000,
      cityId: cityId,
      categoryIds: [categoryId]
    }, techToken);
    assertTest('PUT /api/technicians/me/profile', updateProfileRes.status === 200 && updateProfileRes.body.data?.id, JSON.stringify(updateProfileRes.body));
    techProfileId = updateProfileRes.body.data?.id;

    // 8. Technicians List
    const techListRes = await apiCall('GET', '/api/technicians');
    assertTest('GET /api/technicians', techListRes.status === 200);

    // 9. Service Requests: Create Request (Client)
    const createReqRes = await apiCall('POST', '/api/requests', {
      title: 'Plumbing Repair Test',
      description: 'Fixing a leak under the sink',
      categoryId: categoryId,
      cityId: cityId,
      addressText: 'Douala Akwa',
      urgencyLevel: 'high'
    }, clientToken);
    assertTest('POST /api/requests', createReqRes.status === 201 && createReqRes.body.data?.id, JSON.stringify(createReqRes.body));
    requestId = createReqRes.body.data?.id;

    // 10. Service Requests: List All Requests (Client)
    const clientReqsRes = await apiCall('GET', '/api/requests', null, clientToken);
    assertTest('GET /api/requests (Client)', clientReqsRes.status === 200 && Array.isArray(clientReqsRes.body.data));

    // 11. Offers: Tech Views Offers
    const techOffersRes = await apiCall('GET', '/api/offers', null, techToken);
    assertTest('GET /api/offers (Tech)', techOffersRes.status === 200 && Array.isArray(techOffersRes.body.data));
    if (techOffersRes.body.data?.length > 0) {
      offerId = techOffersRes.body.data[0].id;
    }

    // 12. Tech Stats
    const statsRes = await apiCall('GET', '/api/technicians/me/stats', null, techToken);
    assertTest('GET /api/technicians/me/stats (Tech)', statsRes.status === 200, JSON.stringify(statsRes.body));

    // 13. Notifications
    const notifRes = await apiCall('GET', '/api/notifications', null, techToken);
    assertTest('GET /api/notifications', notifRes.status === 200 && notifRes.body.data?.notifications !== undefined);

    // 14. Accept Offer
    if (offerId) {
      const acceptRes = await apiCall('POST', `/api/offers/${offerId}/accept`, null, techToken);
      assertTest('POST /api/offers/:id/accept (Tech)', acceptRes.status === 200, JSON.stringify(acceptRes.body));
    }

    // 15. Favorites API
    if (techProfileId) {
      const addFavRes = await apiCall('POST', `/api/favorites/${techProfileId}`, null, clientToken);
      assertTest('POST /api/favorites/:techProfileId', addFavRes.status === 200 || addFavRes.status === 201, JSON.stringify(addFavRes.body));

      const getFavsRes = await apiCall('GET', '/api/favorites', null, clientToken);
      assertTest('GET /api/favorites', getFavsRes.status === 200 && Array.isArray(getFavsRes.body.data));

      const removeFavRes = await apiCall('DELETE', `/api/favorites/${techProfileId}`, null, clientToken);
      assertTest('DELETE /api/favorites/:techProfileId', removeFavRes.status === 200, JSON.stringify(removeFavRes.body));
    }

    // ── 16-22. Admin Suite Testing ──
    const adminLoginRes = await apiCall('POST', '/api/auth/login', {
      email: 'admin@fixerpro237.cm',
      password: 'Password123!'
    });
    assertTest('POST /api/auth/login (Admin)', adminLoginRes.status === 200 && adminLoginRes.body.data?.token, JSON.stringify(adminLoginRes.body));
    adminToken = adminLoginRes.body.data?.token;

    if (adminToken) {
      const adminStatsRes = await apiCall('GET', '/api/admin/stats', null, adminToken);
      assertTest('GET /api/admin/stats', adminStatsRes.status === 200 && adminStatsRes.body.data?.usersCount !== undefined);

      const adminUsersRes = await apiCall('GET', '/api/admin/users', null, adminToken);
      assertTest('GET /api/admin/users', adminUsersRes.status === 200 && Array.isArray(adminUsersRes.body.data));

      const adminTechsRes = await apiCall('GET', '/api/admin/technicians', null, adminToken);
      assertTest('GET /api/admin/technicians', adminTechsRes.status === 200 && Array.isArray(adminTechsRes.body.data));

      const adminReqsRes = await apiCall('GET', '/api/admin/requests', null, adminToken);
      assertTest('GET /api/admin/requests', adminReqsRes.status === 200 && Array.isArray(adminReqsRes.body.data));

      const adminVerifsRes = await apiCall('GET', '/api/admin/verifications', null, adminToken);
      assertTest('GET /api/admin/verifications', adminVerifsRes.status === 200 && Array.isArray(adminVerifsRes.body.data));

      const adminCatsRes = await apiCall('GET', '/api/admin/categories', null, adminToken);
      assertTest('GET /api/admin/categories', adminCatsRes.status === 200 && Array.isArray(adminCatsRes.body.data));
    }

  } catch (err) {
    console.error('Unexpected test suite error:', err);
  } finally {
    server.close();
    console.log(`\n--- Test Results Summary ---`);
    console.log(`Passed: ${passedCount}`);
    console.log(`Failed: ${failedCount}`);
    process.exit(failedCount > 0 ? 1 : 0);
  }
}

runComprehensiveTests();
