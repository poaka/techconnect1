const supabase = require('../src/config/supabase');

async function clean() {
  try {
    const { data: adminUser } = await supabase
      .from('users')
      .select('id')
      .eq('email', 'admin@techconnect.cm')
      .maybeSingle();

    if (adminUser) {
      console.log('Cleaning orphan technician profile for admin user:', adminUser.id);
      await supabase
        .from('technician_profiles')
        .delete()
        .eq('user_id', adminUser.id);
      console.log('Done cleaning admin profile.');
    }
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

clean();
