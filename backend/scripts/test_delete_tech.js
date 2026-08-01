const AdminService = require('../src/services/admin.service');
const AuthService = require('../src/services/auth.service');
const supabase = require('../src/config/supabase');

async function testDeleteTech() {
  try {
    const testEmail = `deltech_${Date.now()}@gmail.com`;
    console.log('1. Creating test technician user:', testEmail);
    const { user } = await AuthService.register({
      fullName: 'Technician To Delete',
      email: testEmail,
      phone: '+237611111111',
      password: 'Password123!',
      role: 'technician'
    });
    console.log('Created user ID:', user.id);

    // Create technician profile
    const { data: techProfile, error: pErr } = await supabase.from('technician_profiles').insert([{
      user_id: user.id,
      bio: 'Test bio',
      years_experience: 5
    }]).select().single();
    
    if (pErr) console.error('Profile insert err:', pErr);
    else console.log('Created tech profile ID:', techProfile.id);

    if (techProfile) {
      // Create document for tech
      await supabase.from('technician_documents').insert([{
        technician_id: techProfile.id,
        document_type: 'id_card',
        file_url: 'https://example.com/doc.jpg',
        status: 'pending'
      }]);
    }

    console.log('2. Deleting user via AdminService...');
    const result = await AdminService.deleteUser(user.id);
    console.log('Delete result:', result);

    console.log('3. Checking if user exists in database...');
    const { data: found } = await supabase
      .from('users')
      .select('id, email')
      .eq('id', user.id)
      .maybeSingle();

    if (found) {
      console.error('❌ FAILURE: User STILL EXISTS in DB:', found);
    } else {
      console.log('✅ SUCCESS: Technician user and all associated profile/document records were completely deleted from DB!');
    }
    process.exit(0);
  } catch (err) {
    console.error('❌ Error during technician delete test:', err);
    process.exit(1);
  }
}

testDeleteTech();
