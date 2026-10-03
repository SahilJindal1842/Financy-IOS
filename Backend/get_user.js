const { Client } = require('pg');
const client = new Client({ user: 'postgres', password: 'password', host: 'localhost', database: 'finpilot' });
client.connect();
client.query("SELECT email FROM users WHERE id = '2ed3b714-bd3a-49b0-9d94-9c3cb9de20b4'", (err, res) => {
  console.log(err ? err.stack : res.rows);
  client.end();
});
