const http = require('http');
const loginData = JSON.stringify({ email: 'john@example.com', password: 'password123' });
const loginReq = http.request({
  hostname: '127.0.0.1', port: 3000, path: '/api/auth/login', method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Content-Length': loginData.length }
}, (res) => {
  let data = ''; res.on('data', d => data += d);
  res.on('end', () => {
    const token = JSON.parse(data).token;
    if (!token) return console.log("Login failed");
    const dashReq = http.request({
      hostname: '127.0.0.1', port: 3000, path: '/api/users/dashboard', method: 'GET',
      headers: { 'Authorization': `Bearer ${token}` }
    }, (dRes) => {
      let rData = ''; dRes.on('data', d => rData += d);
      dRes.on('end', () => console.log("DASHBOARD DATA:", rData));
    });
    dashReq.end();
  });
});
loginReq.write(loginData); loginReq.end();
