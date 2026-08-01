const AdminService = require('../src/services/admin.service');

async function run() {
  try {
    const docs = await AdminService.getPendingVerifications();
    console.log('Pending docs count:', docs.length);
    console.log('Pending docs:', docs);
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

run();
