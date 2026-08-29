const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function inspectJobOffersTable() {
  const { data: cols, error } = await supabase.rpc('get_table_columns', { table_name: 'job_offers' });
  if (error) {
    // If RPC doesn't exist, try selecting one row or inserting a dummy to check schema
    const { data, error: selErr } = await supabase.from('job_offers').select('*').limit(1);
    console.log('Select job_offers error:', selErr);
    console.log('Select job_offers sample:', data);
  } else {
    console.log('Columns of job_offers:', cols);
  }
}

inspectJobOffersTable().catch(console.error);
