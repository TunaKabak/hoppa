const https = require('https');

// Send OTP
const req1 = https.request('https://hoppa-backend.onrender.com/api/auth/request-otp', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  }
}, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log(`[REQUEST-OTP] Status: ${res.statusCode}`);
    console.log(`[REQUEST-OTP] Body: ${data}`);
    
    // Verify OTP with arbitrary code "123456"
    const req2 = https.request('https://hoppa-backend.onrender.com/api/auth/verify-otp', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    }, (res2) => {
      let data2 = '';
      res2.on('data', chunk => data2 += chunk);
      res2.on('end', () => {
        console.log(`[VERIFY-OTP] Status: ${res2.statusCode}`);
        console.log(`[VERIFY-OTP] Body: ${data2}`);
      });
    });

    req2.on('error', (e) => {
      console.error(e);
    });

    req2.write(JSON.stringify({ phoneNumber: "+905551234567", code: "123456" }));
    req2.end();
  });
});

req1.on('error', (e) => {
  console.error(e);
});

req1.write(JSON.stringify({ phoneNumber: "+905551234567" }));
req1.end();
