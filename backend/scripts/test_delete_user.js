const AdminService = require('../src/services/admin.service');
const AuthService = require('../src/services/auth.service');
const supabase = require('../src/config/supabase');

async function testDelete() {
  try {
    const testEmail = `deltest_${Date.now()}@gmail.com`;
    console.log('1. Creating test user:', testEmail);
    const { user } = await AuthService.register({
      fullName: 'User To Delete',
      email: testEmail,
      phone: '+237600000000',
      password: 'Password123!',
      role: 'client'
    });
    console.log('Created user ID:', user.id);

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
      console.log('✅ SUCCESS: User is completely gone from DB!');
    }
    process.exit(0);
  } catch (err) {
    console.error('Error during test:', err);
    process.exit(1);
  }
}

testDelete();
