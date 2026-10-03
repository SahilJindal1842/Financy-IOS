const { Client } = require('pg');
const jwt = require('jsonwebtoken');
const http = require('http');

const client = new Client({ user: 'postgres', password: 'password', host: 'localhost', database: 'finpilot' });
client.connect();
client.query('SELECT * FROM users LIMIT 1', (err, res) => {
  const user = res.rows[0];
  const token = jwt.sign({ id: user.id, email: user.email }, 'supersecretjwt', { expiresIn: '1d' });
  
  const dashReq = http.request({
    hostname: '127.0.0.1', port: 3000, path: '/api/users/dashboard', method: 'GET',
    headers: { 'Authorization': `Bearer ${token}` }
  }, (dRes) => {
    let rData = ''; dRes.on('data', d => rData += d);
    dRes.on('end', () => {
      console.log("DASHBOARD DATA:", rData);
      client.end();
    });
  });
  dashReq.end();
});
