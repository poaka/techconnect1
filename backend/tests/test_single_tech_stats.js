const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });
const TechniciansService = require('../src/services/technicians.service');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function testSingleTechnician() {
  const techProfileId = '67ca2321-a2ff-4240-bf7d-e9811b78d13f';
  const { data: prof } = await supabase
    .from('technician_profiles')
    .select('id, user_id, rating_avg, rating_count, verified, availability')
    .eq('id', techProfileId)
    .single();

  console.log('\nTesting technician:', prof);

  const stats = await TechniciansService.getTechnicianStats(prof.user_id);
  console.log('\ngetTechnicianStats result:');
  console.log(JSON.stringify(stats, null, 2));
}

testSingleTechnician().catch(console.error);
