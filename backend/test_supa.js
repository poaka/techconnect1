const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function test() {
  let query = supabase
    .from('technician_profiles')
    .select(`
      id, bio,
      categories:technician_categories!inner(category:categories(id, name, icon))
    `, { count: 'exact' })
    .eq('technician_categories.category_id', '20000000-0000-0000-0000-000000000001');

  const { data, error } = await query;
  if (error) {
    console.error('ERROR:', error);
  } else {
    console.log('SUCCESS, length:', data.length);
  }

  let query2 = supabase
    .from('technician_profiles')
    .select(`
      id, bio,
      categories:technician_categories!inner(category:categories(id, name, icon))
    `, { count: 'exact' })
    .eq('categories.category_id', '20000000-0000-0000-0000-000000000001');

  const { data: data2, error: error2 } = await query2;
  if (error2) {
    console.error('ERROR2:', error2);
  } else {
    console.log('SUCCESS2, length:', data2.length);
  }
}
test();
