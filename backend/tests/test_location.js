const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });
const RequestsService = require('../src/services/requests.service');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function testLocationSharing() {
  console.log('\n=== TESTING LOCATION SHARING (UPDATE & GET) ===\n');

  // 1. Get tech and client
  const { data: techUser } = await supabase
    .from('users')
    .select('id, email')
    .eq('role', 'technician')
    .limit(1)
    .single();

  const { data: clientUser } = await supabase
    .from('users')
    .select('id, email')
    .eq('role', 'client')
    .limit(1)
    .single();

  const { data: cat } = await supabase.from('categories').select('id').limit(1).single();
  const { data: city } = await supabase.from('cities').select('id').limit(1).single();

  // 2. Create request
  console.log('Client creating request...');
  const newReq = await RequestsService.createRequest(clientUser.id, {
    categoryId: cat.id,
    cityId: city.id,
    description: 'Test Location Tracking Request',
    address: 'Quartier Bastos, Yaounde'
  });
  console.log('✅ Request created:', newReq.id);

  // 3. Technician accepts & starts
  await RequestsService.acceptRequest(newReq.id, techUser.id);
  await RequestsService.startRequest(newReq.id, techUser.id);
  console.log('✅ Mission accepted & started (in_progress)');

  // 4. Technician updates location (Yaounde coords: 3.8480, 11.5021)
  console.log('\nTechnician sending location update...');
  const updatedLoc = await RequestsService.updateLocation(newReq.id, techUser.id, 3.8480123, 11.5021456);
  console.log('✅ Location updated successfully:', updatedLoc);

  // 5. Client retrieves location
  console.log('\nClient fetching technician location...');
  const clientLoc = await RequestsService.getLocation(newReq.id, clientUser.id, 'client');
  console.log('✅ Client retrieved location:', clientLoc);

  if (!clientLoc || Math.abs(Number(clientLoc.latitude) - 3.8480123) > 0.0001) {
    throw new Error(`Location mismatch: expected lat 3.8480123, got ${clientLoc?.latitude}`);
  }

  // 6. Cleanup
  console.log('\nCleaning up test data...');
  await supabase.from('location_updates').delete().eq('request_id', newReq.id);
  await supabase.from('notifications').delete().eq('metadata->>requestId', newReq.id);
  await supabase.from('job_offers').delete().eq('service_request_id', newReq.id);
  await supabase.from('service_requests').delete().eq('id', newReq.id);
  console.log('✅ Cleanup finished.');

  console.log('\n🎉 LOCATION SHARING BACKEND TEST PASSED! 🎉\n');
}

testLocationSharing().catch(err => {
  console.error('\n❌ TEST FAILED:', err);
  process.exit(1);
});
