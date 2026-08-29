const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function testInsertJobOffer() {
  // Get an existing service_request and technician_profile
  const { data: req } = await supabase.from('service_requests').select('id').limit(1).single();
  const { data: tech } = await supabase.from('technician_profiles').select('id').limit(1).single();

  console.log('Testing insert into job_offers with req:', req?.id, 'tech:', tech?.id);

  const { data, error } = await supabase.from('job_offers').insert({
    service_request_id: req.id,
    technician_id: tech.id,
    status: 'sent',
    rank: 1
  }).select('*').single();

  console.log('Insert result:', data);
  console.log('Insert error:', error);

  if (data) {
    console.log('Inserted columns:', Object.keys(data));
    // Clean up
    await supabase.from('job_offers').delete().eq('id', data.id);
  }
}

testInsertJobOffer().catch(console.error);
