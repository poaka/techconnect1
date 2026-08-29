const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function checkAllRequests() {
  const { data: reqs } = await supabase
    .from('service_requests')
    .select('id, client_id, assigned_technician_id, status, description');

  console.log('\n=== ALL SERVICE REQUESTS IN DB ===');
  console.log(`Total count: ${reqs?.length || 0}`);
  reqs?.forEach(r => {
    console.log(`- Request ${r.id}: status=${r.status}, assigned_technician_id=${r.assigned_technician_id}, desc="${r.description}"`);
  });
}

checkAllRequests().catch(console.error);
