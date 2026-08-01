const fs = require('fs');
const path = require('path');
const TechniciansService = require('../src/services/technicians.service');

async function testFileUpload() {
  try {
    const uploadsDir = path.join(__dirname, '../uploads');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    console.log('1. Creating test dummy file buffer...');
    const dummyBuffer = Buffer.from('Fake Image Data for verification test');
    const file = {
      originalname: 'test_id_card.png',
      buffer: dummyBuffer,
      mimetype: 'image/png'
    };

    console.log('2. Running TechniciansService.uploadDocument...');
    // We pass a dummy user ID or real user ID
    const doc = await TechniciansService.uploadDocument('30000000-0000-0000-0000-000000000003', 'id_card', file);
    console.log('Document saved:', doc);

    const savedPath = path.join(__dirname, '..', doc.file_url);
    console.log('Checking if file exists on disk at:', savedPath);
    if (fs.existsSync(savedPath)) {
      console.log('✅ SUCCESS: File physically exists on disk and is ready to be served statically via Express!');
    } else {
      console.error('❌ FAILURE: File was NOT found on disk at', savedPath);
    }
    process.exit(0);
  } catch (err) {
    console.error('Error during file upload test:', err);
    process.exit(1);
  }
}

testFileUpload();
