const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });
const RequestsService = require('../src/services/requests.service');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function testTechnicianGetRequest() {
  console.log('\n=== TESTING TECHNICIAN GET REQUEST BY ID ===\n');

  // 1. Find a technician user and their profile
  const { data: techUser } = await supabase
    .from('users')
    .select('id, email')
    .eq('role', 'technician')
    .limit(1)
    .single();

  const { data: techProfile } = await supabase
    .from('technician_profiles')
    .select('id, user_id')
    .eq('user_id', techUser.id)
    .single();

  console.log('Tech User ID:', techUser.id);
  console.log('Tech Profile ID:', techProfile.id);

  // 2. Find a client and create a request
  const { data: clientUser } = await supabase
    .from('users')
    .select('id, email')
    .eq('role', 'client')
    .limit(1)
    .single();

  const { data: cat } = await supabase.from('categories').select('id').limit(1).single();
  const { data: city } = await supabase.from('cities').select('id').limit(1).single();

  const newReq = await RequestsService.createRequest(clientUser.id, {
    categoryId: cat.id,
    cityId: city.id,
    description: 'Test incoming request for tech'
  });

  console.log('Created request:', newReq.id);

  // 3. Ensure a job_offer exists for this technician
  const { data: offers } = await supabase
    .from('job_offers')
    .select('*')
    .eq('service_request_id', newReq.id);

  console.log('Offers created for request:', offers.length);
  offers.forEach(o => console.log('  Offer:', o.id, 'tech_id:', o.technician_id, 'status:', o.status));

  // 4. Now test RequestsService.getRequestById as TECHNICIAN
  console.log('\nCalling RequestsService.getRequestById(newReq.id, techUser.id, "technician")...');
  try {
    const fetched = await RequestsService.getRequestById(newReq.id, techUser.id, 'technician');
    console.log('✅ Tech successfully fetched request details:');
    console.log('   - ID:', fetched.id);
    console.log('   - Status:', fetched.status);
    console.log('   - Client:', fetched.client?.full_name);
  } catch (err) {
    console.error('❌ Failed to fetch as technician:', err.status, err.message);
  }

  // 5. Cleanup
  await supabase.from('job_offers').delete().eq('service_request_id', newReq.id);
  await supabase.from('service_requests').delete().eq('id', newReq.id);
  console.log('Cleaned up test data.');
}

testTechnicianGetRequest().catch(console.error);
