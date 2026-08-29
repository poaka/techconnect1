const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function inspectSpecificTech() {
  const { data: tech } = await supabase
    .from('technician_profiles')
    .select('*, users(*)')
    .eq('id', '67ca2321-a2ff-4240-bf7d-e9811b78d13f')
    .single();

  console.log('Assigned tech in request 7cf9cf6a:', tech);
}

inspectSpecificTech().catch(console.error);
