const AdminService = require('../src/services/admin.service');

async function testAdminRequests() {
  try {
    console.log('Testing AdminService.getServiceRequests()...');
    const requests = await AdminService.getServiceRequests();
    console.log('Total service requests returned:', requests.length);
    if (requests.length > 0) {
      console.log('Sample request:', JSON.stringify(requests[0], null, 2));
    } else {
      console.log('No service requests currently in DB.');
    }
    process.exit(0);
  } catch (err) {
    console.error('Error during test:', err);
    process.exit(1);
  }
}

testAdminRequests();
