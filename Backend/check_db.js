const { Client } = require('pg');
const client = new Client({
  user: 'postgres',
  password: 'password',
  host: 'localhost',
  database: 'finpilot'
});
client.connect();
client.query('SELECT * FROM recurring_transactions', (err, res) => {
  console.log(err ? err.stack : JSON.stringify(res.rows, null, 2));
  client.end();
});
