const http = require('http');

// Let's first login to get a token.
const loginData = JSON.stringify({ email: 'sahil@example.com', password: 'password123' });
const loginReq = http.request({
  hostname: '127.0.0.1',
  port: 3000,
  path: '/api/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': loginData.length
  }
}, (res) => {
  let data = '';
  res.on('data', d => data += d);
  res.on('end', () => {
    const json = JSON.parse(data);
    const token = json.token;
    
    // Now fetch recurring
    const recReq = http.request({
      hostname: '127.0.0.1',
      port: 3000,
      path: '/api/recurring',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    }, (recRes) => {
      let rData = '';
      recRes.on('data', d => rData += d);
      recRes.on('end', () => {
        console.log("RECURRING DATA:", rData);
      });
    });
    recReq.end();
  });
});
loginReq.write(loginData);
loginReq.end();
