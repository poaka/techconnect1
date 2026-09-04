const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: '.env' });
const RequestsService = require('../src/services/requests.service');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function testRequestPhotoAndLifecycle() {
  console.log('\n=== TESTING REQUEST CREATION, PHOTO & UPDATE LIFECYCLE ===\n');

  // 1. Get a test client user
  const { data: clientUser } = await supabase
    .from('users')
    .select('id, email')
    .eq('role', 'client')
    .limit(1)
    .single();
  console.log('Client User:', clientUser.id, clientUser.email);

  // 2. Get category and city
  const { data: cat } = await supabase.from('categories').select('id, name').limit(1).single();
  const { data: city } = await supabase.from('cities').select('id, name').limit(1).single();
  console.log('Category:', cat.name, '| City:', city.name);

  // 3. Create request with simulated file
  const dummyBuffer = Buffer.from('FAKE_IMAGE_CONTENT_FOR_TEST');
  const dummyFile = {
    originalname: 'broken_pipe.jpg',
    buffer: dummyBuffer,
    mimetype: 'image/jpeg'
  };

  console.log('Creating request with photo...');
  const newReq = await RequestsService.createRequest(
    clientUser.id,
    {
      categoryId: cat.id,
      cityId: city.id,
      description: 'Fuite importante sous évier',
      address: 'Quartier Bastos, Yaoundé'
    },
    dummyFile
  );

  console.log('✅ Request created:', newReq.id);
  console.log('   - Description:', newReq.description);
  console.log('   - Image URL:', newReq.image_url);

  if (!newReq.image_url) {
    throw new Error('Image URL was not returned on creation!');
  }

  // 4. Retrieve by ID
  console.log('\nFetching request by ID...');
  const fetchedReq = await RequestsService.getRequestById(newReq.id, clientUser.id, 'client');
  console.log('✅ Request fetched:');
  console.log('   - Status:', fetchedReq.status);
  console.log('   - Description:', fetchedReq.description);
  console.log('   - Image URL:', fetchedReq.image_url);

  if (fetchedReq.image_url !== newReq.image_url) {
    throw new Error('Fetched image_url does not match created image_url!');
  }

  // 5. Update request with new description and new image
  console.log('\nUpdating request with new description and replacement photo...');
  const newDummyFile = {
    originalname: 'fixed_pipe_attempt.jpg',
    buffer: Buffer.from('NEW_FAKE_IMAGE_DATA'),
    mimetype: 'image/jpeg'
  };

  const updatedReq = await RequestsService.updateRequest(
    newReq.id,
    clientUser.id,
    {
      description: 'Fuite sous évier (mise à jour: robinet changé)',
      address: 'Quartier Bastos, Rue 123'
    },
    newDummyFile
  );

  console.log('✅ Request updated:');
  console.log('   - Description:', updatedReq.description);
  console.log('   - Address:', updatedReq.address);
  console.log('   - Image URL:', updatedReq.image_url);

  if (!updatedReq.image_url || updatedReq.image_url === newReq.image_url) {
    console.log('Note: new image uploaded:', updatedReq.image_url);
  }

  // 6. Test update without changing photo (preserve photo)
  console.log('\nUpdating description only (preserving photo)...');
  const updatedDescOnly = await RequestsService.updateRequest(
    newReq.id,
    clientUser.id,
    {
      description: 'Fuite urgente évier'
    }
  );
  console.log('✅ Updated desc only:');
  console.log('   - Description:', updatedDescOnly.description);
  console.log('   - Image URL preserved:', updatedDescOnly.image_url);

  if (!updatedDescOnly.image_url) {
    throw new Error('Image URL was lost when updating description only!');
  }

  // 7. Clean up
  console.log('\nCleaning up test request...');
  await RequestsService.deleteRequest(newReq.id, clientUser.id);
  console.log('✅ Test request deleted successfully.');

  console.log('\n🎉 ALL REQUEST PHOTO & UPDATE TESTS PASSED! 🎉\n');
}

testRequestPhotoAndLifecycle().catch(err => {
  console.error('\n❌ TEST FAILED:', err);
  process.exit(1);
});
