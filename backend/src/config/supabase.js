const { createClient } = require('@supabase/supabase-js');
const env = require('./env');

let supabase = null;

const isPlaceholder = !env.supabaseUrl || 
  env.supabaseUrl.includes('your-supabase-project') || 
  !env.supabaseServiceRoleKey || 
  env.supabaseServiceRoleKey.includes('your-supabase-service-role-key');

if (!isPlaceholder) {
  supabase = createClient(env.supabaseUrl, env.supabaseServiceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false
    }
  });
} else {
  console.warn('[Supabase Config Warning] SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is placeholder or missing in .env. Running in local memory/fallback mode.');
}

module.exports = supabase;
