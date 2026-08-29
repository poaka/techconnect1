const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });
const TechniciansService = require('../src/services/technicians.service');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function testTechnicianStats() {
  console.log('\n=== TESTING TECHNICIAN STATS API ===\n');

  // Find all technician profiles
  const { data: profiles } = await supabase
    .from('technician_profiles')
    .select('id, user_id, verified, availability, rating_avg, rating_count');

  console.log(`Found ${profiles.length} technician profile(s):`);

  for (const prof of profiles) {
    console.log(`\nProfile ${prof.id} (user: ${prof.user_id}):`);
    
    // Check requests in DB
    const { data: reqs } = await supabase
      .from('service_requests')
      .select('id, status, assigned_technician_id')
      .eq('assigned_technician_id', prof.id);

    console.log(`  Actual DB service_requests count: ${reqs?.length || 0}`);
    reqs?.forEach(r => console.log(`    - Request ${r.id}: status = ${r.status}`));

    // Check offers in DB
    const { data: offers } = await supabase
      .from('job_offers')
      .select('id, status')
      .eq('technician_id', prof.id);
    console.log(`  Actual DB job_offers count: ${offers?.length || 0}`);
    offers?.forEach(o => console.log(`    - Offer ${o.id}: status = ${o.status}`));

    // Call service
    const stats = await TechniciansService.getTechnicianStats(prof.user_id);
    console.log('  getTechnicianStats output:', stats);
  }
}

testTechnicianStats().catch(console.error);
