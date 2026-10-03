const { Client } = require('pg');
const client = new Client({ user: 'postgres', password: 'password', host: 'localhost', database: 'finpilot' });

async function clearAll() {
  await client.connect();
  
  // Keep user account, wipe everything else
  const tables = [
    'transactions',
    'recurring_transactions',
    'budgets',
    'savings_goals',
    'categories',
    'accounts',
    'notifications'
  ];
  
  for (const table of tables) {
    try {
      const res = await client.query(`DELETE FROM ${table}`);
      console.log(`✅ Cleared ${table}: ${res.rowCount} rows deleted`);
    } catch (e) {
      console.log(`⚠️  ${table}: ${e.message}`);
    }
  }
  
  // Verify user still exists
  const { rows } = await client.query('SELECT id, name, email FROM users');
  console.log(`\n👤 Users still in DB:`, rows);
  
  await client.end();
  console.log('\n🧹 All data cleared! You can start fresh.');
}

clearAll();
