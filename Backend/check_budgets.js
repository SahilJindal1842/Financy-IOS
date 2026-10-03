const { Client } = require('pg');
const client = new Client({ user: 'postgres', password: 'password', host: 'localhost', database: 'finpilot' });
client.connect();
client.query('SELECT * FROM budgets', (err, res) => {
  console.log(err ? err.stack : res.rows);
  client.end();
});
