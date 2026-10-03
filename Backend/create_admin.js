const { Client } = require('pg');
const bcrypt = require('bcrypt');

const client = new Client('postgres://postgres:admin%40123@localhost:5432/finpilot');

async function main() {
  await client.connect();
  const hash = await bcrypt.hash('Admin@123', 10);
  const existing = await client.query("SELECT * FROM users WHERE email = 'admin@financy.app'");
  if (existing.rows.length === 0) {
    await client.query(
      "INSERT INTO users (email, name, password_hash, role, status, email_verified) VALUES ($1, $2, $3, $4, $5, $6)",
      ['admin@financy.app', 'System Admin', hash, 'ADMIN', 'ACTIVE', true]
    );
    console.log('Created admin@financy.app');
  } else {
    await client.query(
      "UPDATE users SET role = 'ADMIN', status = 'ACTIVE', password_hash = $1 WHERE email = 'admin@financy.app'",
      [hash]
    );
    console.log('Updated admin@financy.app');
  }
  await client.end();
}

main().catch(err => { console.error(err); process.exit(1); });
