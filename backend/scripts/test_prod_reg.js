const https = require('https');

const data = JSON.stringify({
  fullName: "Test Friend",
  email: `friendtest_${Date.now()}@gmail.com`,
  phone: "+237699999999",
  password: "Password123!",
  role: "client"
});

const req = https.request('https://techconnect1-api.onrender.com/api/auth/register', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
}, (res) => {
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    console.log('Status Code:', res.statusCode);
    console.log('Response Body:', body);
  });
});

req.on('error', (e) => console.error(e));
req.write(data);
req.end();
