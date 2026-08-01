const supabase = require('../src/config/supabase');

async function inspect() {
  try {
    const { data: users } = await supabase.from('users').select('id, full_name, email, role');
    const { data: profiles } = await supabase.from('technician_profiles').select('id, user_id, verified');

    console.log('--- ALL USERS IN DB ---');
    console.table(users);

    console.log('--- ALL TECHNICIAN PROFILES IN DB ---');
    console.table(profiles);

    const userIds = new Set(users.map(u => u.id));
    const orphanProfiles = profiles.filter(p => !userIds.has(p.user_id));

    if (orphanProfiles.length > 0) {
      console.log('⚠️ FOUND ORPHAN TECHNICIAN PROFILES (profiles whose user was deleted before cascade fix):');
      console.table(orphanProfiles);
    } else {
      console.log('✅ No orphan technician profiles found!');
    }

    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

inspect();
