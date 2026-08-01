const supabase = require('../src/config/supabase');
const AdminService = require('../src/services/admin.service');

async function testCounts() {
  try {
    const stats = await AdminService.getPlatformStats();
    console.log('Platform Stats:', stats);

    const users = await AdminService.getUsers();
    console.log('getUsers() returned count:', users.length);
    console.log('User roles breakdown:');
    const rolesCount = {};
    users.forEach(u => {
      rolesCount[u.role] = (rolesCount[u.role] || 0) + 1;
    });
    console.log(rolesCount);

    const techs = await AdminService.getTechnicians();
    console.log('getTechnicians() returned count:', techs.length);

    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

testCounts();
