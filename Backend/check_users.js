const { Client } = require('pg');
const client = new Client({ user: 'postgres', password: 'password', host: 'localhost', database: 'finpilot' });
client.connect();
client.query('SELECT email FROM users LIMIT 1', (err, res) => {
  console.log(err ? err.stack : res.rows);
  client.end();
});
