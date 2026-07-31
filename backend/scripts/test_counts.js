require('dotenv').config();
const supabase = require('../src/config/supabase');
const AdminService = require('../src/services/admin.service');

async function testCounts() {
  console.log('--- Checking DB Counts ---');
  if (!supabase) return;

  const stats = await AdminService.getPlatformStats();
  console.log('Stats from getPlatformStats:', stats);

  const users = await AdminService.getUsers();
  console.log('Users length:', users.length);
  const techUsers = users.filter(u => u.role === 'technician');
  console.log('Users with role technician:', techUsers.length);

  const technicians = await AdminService.getTechnicians();
  console.log('Technicians length from getTechnicians:', technicians.length);

  console.log('Done.');
}
testCounts();
