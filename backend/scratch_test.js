require('dotenv').config();
const RequestsService = require('./src/services/requests.service');
const supabase = require('./src/config/supabase');

async function testFullCreateRequest() {
  console.log('Testing RequestsService.createRequest...');
  
  // Get client
  const { data: users } = await supabase.from('users').select('id').eq('role', 'client').limit(1);
  const clientId = users[0].id;

  // Get category & city
  const { data: categories } = await supabase.from('categories').select('id').limit(1);
  const { data: cities } = await supabase.from('cities').select('id').limit(1);

  try {
    const res = await RequestsService.createRequest(clientId, {
      categoryId: categories[0].id,
      cityId: cities[0].id,
      description: 'Test request full flow',
      address: 'Douala, Cameroun'
    });
    console.log('FULL CREATE REQUEST SUCCESSFUL!', res);
    
    // Clean up created request and offers
    await supabase.from('job_offers').delete().eq('request_id', res.id);
    await supabase.from('service_requests').delete().eq('id', res.id);
    console.log('Cleaned up successfully');
  } catch (err) {
    console.error('FULL CREATE REQUEST ERROR:', err);
  }
}

testFullCreateRequest();
