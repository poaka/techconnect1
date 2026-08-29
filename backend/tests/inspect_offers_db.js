const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function inspectDb() {
  console.log('=== INSPECTING LIVE SUPABASE DATABASE ===\n');

  // 1. Service requests
  const { data: requests, error: reqErr } = await supabase
    .from('service_requests')
    .select('id, client_id, assigned_technician_id, category_id, city_id, status, description, created_at')
    .order('created_at', { ascending: false })
    .limit(10);

  console.log(`Service Requests count (last 10): ${requests?.length || 0}`);
  if (requests && requests.length > 0) {
    requests.forEach((r, i) => {
      console.log(`[${i + 1}] ID: ${r.id} | Status: ${r.status} | Client: ${r.client_id} | AssignedTech: ${r.assigned_technician_id} | City: ${r.city_id} | Cat: ${r.category_id} | Created: ${r.created_at}`);
    });
  }

  // 2. Job Offers
  const { data: offers, error: offErr } = await supabase
    .from('job_offers')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(20);

  console.log(`\nJob Offers count (total in DB): ${offers?.length || 0}`);
  if (offers && offers.length > 0) {
    offers.forEach((o, i) => {
      console.log(`[${i + 1}] ID: ${o.id} | RequestID: ${o.service_request_id} | TechID: ${o.technician_id} | Status: ${o.status} | Rank: ${o.rank}`);
    });
  }

  // 3. Technician Profiles
  const { data: techs, error: techErr } = await supabase
    .from('technician_profiles')
    .select('id, user_id, verified, availability, city_id, category_id, active_job_count')
    .limit(10);

  console.log(`\nTechnician Profiles count: ${techs?.length || 0}`);
  if (techs && techs.length > 0) {
    techs.forEach((t, i) => {
      console.log(`[${i + 1}] ID: ${t.id} | UserID: ${t.user_id} | Verified: ${t.verified} | Avail: ${t.availability} | City: ${t.city_id} | Cat: ${t.category_id} | ActiveJobs: ${t.active_job_count}`);
    });
  }
}

inspectDb().catch(console.error);
