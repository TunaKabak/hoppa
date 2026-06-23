const https = require('https');

const data = JSON.stringify({
  phoneNumber: '+905488600455',
  code: '123456',
  name: 'Test',
  surname: 'User'
});

const options = {
  hostname: 'hoppa-backend.onrender.com',
  port: 443,
  path: '/api/auth/verify-otp',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = https.request(options, (res) => {
  let responseData = '';

  res.on('data', (chunk) => {
    responseData += chunk;
  });

  res.on('end', () => {
    console.log(`Status Code: ${res.statusCode}`);
    console.log(`Response: ${responseData}`);
  });
});

req.on('error', (error) => {
  console.error(error);
});

req.write(data);
req.end();
