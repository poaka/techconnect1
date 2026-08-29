const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });
const RequestsService = require('../src/services/requests.service');
const TechniciansService = require('../src/services/technicians.service');
const ReviewsService = require('../src/services/reviews.service');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function testTechnicianStatsLifecycle() {
  console.log('\n=== TESTING TECHNICIAN DASHBOARD STATS SYNCHRONIZATION ===\n');

  // 1. Get test technician
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

  // Initial stats
  const initialStats = await TechniciansService.getTechnicianStats(techUser.id);
  console.log('📊 Initial Stats:', {
    pending: initialStats.pendingRequestsCount,
    accepted: initialStats.acceptedRequestsCount,
    inProgress: initialStats.inProgressRequestsCount,
    completed: initialStats.completedJobsCount,
    total: initialStats.totalRequestsCount,
    ratingAvg: initialStats.ratingAvg,
    ratingCount: initialStats.ratingCount
  });

  // 2. Client creates a request
  const { data: clientUser } = await supabase
    .from('users')
    .select('id, email')
    .eq('role', 'client')
    .limit(1)
    .single();

  const { data: cat } = await supabase.from('categories').select('id').limit(1).single();
  const { data: city } = await supabase.from('cities').select('id').limit(1).single();

  const req = await RequestsService.createRequest(clientUser.id, {
    categoryId: cat.id,
    cityId: city.id,
    description: 'Test stats synchronization request'
  });

  console.log('\n1️⃣ Request Created:', req.id);

  // 3. Technician accepts request
  await RequestsService.acceptRequest(req.id, techUser.id);
  const acceptedStats = await TechniciansService.getTechnicianStats(techUser.id);
  console.log('2️⃣ After Accept Stats:', {
    pending: acceptedStats.pendingRequestsCount,
    accepted: acceptedStats.acceptedRequestsCount,
    total: acceptedStats.totalRequestsCount
  });

  // 4. Technician starts request
  await RequestsService.startRequest(req.id, techUser.id);
  const startedStats = await TechniciansService.getTechnicianStats(techUser.id);
  console.log('3️⃣ After Start (In-Progress) Stats:', {
    inProgress: startedStats.inProgressRequestsCount,
    total: startedStats.totalRequestsCount
  });

  // 5. Technician completes request
  await RequestsService.completeRequest(req.id, techUser.id);
  const completedStats = await TechniciansService.getTechnicianStats(techUser.id);
  console.log('4️⃣ After Complete Stats:', {
    completed: completedStats.completedJobsCount,
    inProgress: completedStats.inProgressRequestsCount,
    total: completedStats.totalRequestsCount
  });

  if (completedStats.completedJobsCount !== initialStats.completedJobsCount + 1) {
    throw new Error(`Expected completed count to increment by 1. Was ${initialStats.completedJobsCount}, now ${completedStats.completedJobsCount}`);
  }

  // 6. Client submits 5-star review
  await ReviewsService.createReview(clientUser.id, {
    requestId: req.id,
    rating: 5,
    comment: 'Super intervention, très professionnel !'
  });

  const reviewedStats = await TechniciansService.getTechnicianStats(techUser.id);
  console.log('5️⃣ After Review Stats:', {
    ratingAvg: reviewedStats.ratingAvg,
    ratingCount: reviewedStats.ratingCount
  });

  // 7. Cleanup
  console.log('\n🧹 Cleaning up test data...');
  await supabase.from('reviews').delete().eq('request_id', req.id);
  await supabase.from('notifications').delete().eq('metadata->>requestId', req.id);
  await supabase.from('job_offers').delete().eq('service_request_id', req.id);
  await supabase.from('service_requests').delete().eq('id', req.id);

  console.log('✅ All Dashboard Stats synchronization tests PASSED successfully!\n');
}

testTechnicianStatsLifecycle().catch(err => {
  console.error('\n❌ TEST FAILED:', err);
  process.exit(1);
});
