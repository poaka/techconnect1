const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });
const RequestsService = require('../src/services/requests.service');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function testTechnicianRequestLifecycle() {
  console.log('\n=== TESTING TECHNICIAN INCOMING REQUEST ACCEPTANCE & LIFECYCLE ===\n');

  // 1. Get a test technician
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

  console.log('Technician:', techUser.id, '| Profile:', techProfile.id);

  // 2. Get a test client
  const { data: clientUser } = await supabase
    .from('users')
    .select('id, email')
    .eq('role', 'client')
    .limit(1)
    .single();

  const { data: cat } = await supabase.from('categories').select('id').limit(1).single();
  const { data: city } = await supabase.from('cities').select('id').limit(1).single();

  // 3. Create request
  console.log('Client creating request...');
  const newReq = await RequestsService.createRequest(clientUser.id, {
    categoryId: cat.id,
    cityId: city.id,
    description: 'Robinet cassé cuisine - besoin technicien',
    address: 'Quartier Omnisports'
  });

  console.log('✅ Request created:', newReq.id, 'Status:', newReq.status);

  // 4. Technician views request details
  console.log('\nTechnician viewing request details...');
  const viewedReq = await RequestsService.getRequestById(newReq.id, techUser.id, 'technician');
  console.log('✅ Technician viewed request successfully:');
  console.log('   - ID:', viewedReq.id);
  console.log('   - Description:', viewedReq.description);
  console.log('   - Client:', viewedReq.client?.full_name);

  // 5. Technician accepts the request
  console.log('\nTechnician accepting request...');
  const acceptResult = await RequestsService.acceptRequest(newReq.id, techUser.id);
  console.log('✅ Technician accepted request:');
  console.log('   - Message:', acceptResult.message);
  console.log('   - New status:', acceptResult.request.status);
  console.log('   - Assigned Tech ID:', acceptResult.request.assigned_technician_id);

  if (acceptResult.request.status !== 'assigned') {
    throw new Error(`Expected status 'assigned', got '${acceptResult.request.status}'`);
  }

  // 6. Technician starts the request
  console.log('\nTechnician starting mission...');
  const started = await RequestsService.startRequest(newReq.id, techUser.id);
  console.log('✅ Mission started. Status:', started.status);

  // 7. Technician completes the request
  console.log('\nTechnician completing mission...');
  const completed = await RequestsService.completeRequest(newReq.id, techUser.id);
  console.log('✅ Mission completed. Status:', completed.status);

  // 8. Cleanup
  console.log('\nCleaning up test data...');
  await supabase.from('notifications').delete().eq('metadata->>requestId', newReq.id);
  await supabase.from('job_offers').delete().eq('service_request_id', newReq.id);
  await supabase.from('service_requests').delete().eq('id', newReq.id);
  console.log('✅ Cleaned up.');

  console.log('\n🎉 ALL TECHNICIAN INCOMING REQUEST TESTS PASSED! 🎉\n');
}

testTechnicianRequestLifecycle().catch(err => {
  console.error('\n❌ TEST FAILED:', err);
  process.exit(1);
});
