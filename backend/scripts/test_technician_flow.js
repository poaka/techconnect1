require('dotenv').config();
const supabase = require('../src/config/supabase');
const AdminService = require('../src/services/admin.service');

const crypto = require('crypto');
const userId = crypto.randomUUID();
let techProfileId;
const docId = crypto.randomUUID();

async function testTechnicianFlow() {
  console.log('--- TEST TECHNICIAN FLOW ---');

  if (!supabase) {
    console.error('Supabase client not initialized.');
    return;
  }

  // 1. Create a mock user
  console.log('1. Creating mock user...');
  const { data: user, error: userError } = await supabase
    .from('users')
    .insert([{
      id: userId,
      email: `test_tech_${Date.now()}@example.com`,
      full_name: 'Test Technician',
      role: 'technician',
      password_hash: 'hash'
    }])
    .select()
    .single();
  
  if (userError) {
    console.log('User creation error:', userError.message);
    return;
  }

  // 2. Fetch the auto-created mock technician profile
  console.log('2. Fetching auto-created technician profile...');
  const { data: profile, error: profileError } = await supabase
    .from('technician_profiles')
    .select('id')
    .eq('user_id', userId)
    .single();

  if (profileError) {
    console.log('Profile fetch error:', profileError.message);
    return;
  }
  
  techProfileId = profile.id;

  // 3. Upload a document
  console.log('3. Uploading mock document (pending)...');
  const { data: document, error: docError } = await supabase
    .from('technician_documents')
    .insert([{
      id: docId,
      technician_id: techProfileId,
      document_type: 'id_card',
      file_url: 'http://example.com/id_card.jpg',
      status: 'pending'
    }])
    .select()
    .single();

  if (docError) {
    console.log('Document creation error:', docError.message);
    return;
  } else {
    console.log('Document created with ID:', document.id);
  }

  // 4. Fetch pending verifications
  console.log('4. Fetching pending verifications as Admin...');
  const pending = await AdminService.getPendingVerifications();
  const myDoc = pending.find(d => d.id === docId);
  console.log('Is document pending?', myDoc ? 'Yes' : 'No');

  if (myDoc) {
    // 5. Approve the document
    console.log('5. Approving document...');
    await AdminService.reviewDocument(myDoc.id, 'approved');
    console.log('Document approved successfully.');

    // 6. Verify technician profile
    console.log('6. Checking if technician is verified...');
    const { data: updatedProfile, error: checkError } = await supabase
      .from('technician_profiles')
      .select('verified')
      .eq('id', techProfileId)
      .single();
    
    if (checkError) {
      console.log('Check error:', checkError.message);
    } else {
      console.log('Technician verified status:', updatedProfile.verified);
      if (updatedProfile.verified === true) {
        console.log('✅ TEST PASSED: Technician is verified!');
      } else {
        console.log('❌ TEST FAILED: Technician is NOT verified!');
      }
    }
  }

  // Cleanup
  console.log('7. Cleaning up test data...');
  await supabase.from('technician_documents').delete().eq('id', docId);
  await supabase.from('technician_profiles').delete().eq('id', techProfileId);
  await supabase.from('users').delete().eq('id', userId);
  console.log('Cleanup done.');
}

testTechnicianFlow();
