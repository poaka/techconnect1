const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function test() {
  let query = supabase
    .from('technician_profiles')
    .select(`
      id, bio,
      user:users!user_id(id, full_name)
    `, { count: 'exact' })
    .or(`bio.ilike.%test%,users.full_name.ilike.%test%`);

  const { data, error } = await query;
  if (error) {
    console.error('ERROR:', error);
  } else {
    console.log('SUCCESS, length:', data.length);
  }
}
test();
