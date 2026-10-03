const { Client } = require('pg');
const jwt = require('jsonwebtoken');
const http = require('http');

const DB_CONFIG = { user: 'postgres', password: 'password', host: 'localhost', database: 'finpilot' };
const JWT_SECRET = 'supersecretjwt';

function apiRequest(method, path, token, body = null) {
  return new Promise((resolve, reject) => {
    const headers = { 'Authorization': `Bearer ${token}` };
    if (body) headers['Content-Type'] = 'application/json';
    const bodyStr = body ? JSON.stringify(body) : null;
    if (bodyStr) headers['Content-Length'] = Buffer.byteLength(bodyStr);
    
    const req = http.request({
      hostname: '127.0.0.1', port: 3000, path: `/api${path}`, method, headers
    }, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, data: JSON.parse(data) }); }
        catch (e) { resolve({ status: res.statusCode, data: data }); }
      });
    });
    req.on('error', reject);
    if (bodyStr) req.write(bodyStr);
    req.end();
  });
}

async function runTests() {
  const client = new Client(DB_CONFIG);
  await client.connect();
  
  // Get user
  const { rows: users } = await client.query("SELECT * FROM users WHERE email = 'sahil@yopmail.com'");
  if (!users.length) { console.log("❌ No user found"); await client.end(); return; }
  const user = users[0];
  const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '1d' });
  console.log(`✅ User found: ${user.name} (${user.email})\n`);
  
  let passed = 0, failed = 0, issues = [];
  
  function check(name, condition, detail = '') {
    if (condition) { console.log(`  ✅ ${name}`); passed++; }
    else { console.log(`  ❌ ${name} ${detail}`); failed++; issues.push({ name, detail }); }
  }
  
  // ===== 1. DASHBOARD =====
  console.log("📊 DASHBOARD");
  const dash = await apiRequest('GET', '/users/dashboard', token);
  check("Dashboard loads", dash.status === 200);
  check("Has userName", !!dash.data.userName);
  check("Has currency", !!dash.data.currency);
  check("Budget > 0", dash.data.budget > 0, `got ${dash.data.budget}`);
  check("remainingBudget is number", typeof dash.data.remainingBudget === 'number', `got ${typeof dash.data.remainingBudget}`);
  check("budgetUsedPercentage is number", typeof dash.data.budgetUsedPercentage === 'number');
  check("transactions is array", Array.isArray(dash.data.transactions));
  check("upcomingBills is array", Array.isArray(dash.data.upcomingBills));
  console.log(`  Budget: ${dash.data.budget}, Remaining: ${dash.data.remainingBudget}, Used: ${dash.data.budgetUsedPercentage}%\n`);
  
  // ===== 2. CATEGORIES =====
  console.log("🏷️  CATEGORIES");
  const cats = await apiRequest('GET', '/categories', token);
  check("Categories load", cats.status === 200);
  check("Categories is array", Array.isArray(cats.data));
  if (cats.data.length > 0) {
    check("Category has id", !!cats.data[0].id);
    check("Category has name", !!cats.data[0].name);
    check("Category has color", !!cats.data[0].color);
    check("Category has type field", cats.data[0].type !== undefined, `type=${cats.data[0].type}`);
  }
  
  // Test create category
  const newCat = await apiRequest('POST', '/categories', token, {
    name: 'Test Category', icon: 'star.fill', color: '#ff5733', type: 'expense'
  });
  check("Create category", newCat.status === 200 || newCat.status === 201, `status=${newCat.status} ${JSON.stringify(newCat.data)}`);
  
  if (newCat.data && newCat.data.id) {
    // Test update
    const updCat = await apiRequest('PUT', `/categories/${newCat.data.id}`, token, {
      name: 'Updated Test', icon: 'star.fill', color: '#33ff57', type: 'income'
    });
    check("Update category", updCat.status === 200, `status=${updCat.status}`);
    check("Updated type persisted", updCat.data?.type === 'income', `type=${updCat.data?.type}`);
    
    // Test delete
    const delCat = await apiRequest('DELETE', `/categories/${newCat.data.id}`, token);
    check("Delete category", delCat.status === 200, `status=${delCat.status}`);
  }
  console.log();
  
  // ===== 3. ACCOUNTS =====
  console.log("🏦 ACCOUNTS");
  const accs = await apiRequest('GET', '/accounts', token);
  check("Accounts load", accs.status === 200);
  check("Accounts is array", Array.isArray(accs.data));
  if (accs.data.length > 0) {
    check("Account has id", !!accs.data[0].id);
    check("Account has name", !!accs.data[0].name);
    console.log(`  Found ${accs.data.length} account(s): ${accs.data.map(a => a.name).join(', ')}`);
  } else {
    check("Has at least 1 account", false, "No accounts found - this will break recurring saves");
  }
  console.log();
  
  // ===== 4. TRANSACTIONS =====
  console.log("💸 TRANSACTIONS");
  const txns = await apiRequest('GET', '/transactions', token);
  check("Transactions load", txns.status === 200);
  check("Transactions is array", Array.isArray(txns.data));
  if (txns.data.length > 0) {
    const t = txns.data[0];
    check("Transaction has id", !!t.id);
    check("Transaction amount is number", typeof t.amount === 'number', `type=${typeof t.amount}`);
    check("Transaction has type", !!t.type);
    check("Transaction has date", !!t.date);
  }
  
  // Test create transaction
  const accountId = accs.data.length > 0 ? accs.data[0].id : null;
  const categoryId = cats.data.length > 0 ? cats.data[0].id : null;
  if (accountId) {
    const newTx = await apiRequest('POST', '/transactions', token, {
      account_id: accountId,
      category_id: categoryId,
      amount: 100,
      type: 'EXPENSE',
      date: new Date().toISOString(),
      description: 'Test transaction',
      notes: 'Automated test'
    });
    check("Create transaction", newTx.status === 200 || newTx.status === 201, `status=${newTx.status} ${JSON.stringify(newTx.data).substring(0, 200)}`);
    
    if (newTx.data && newTx.data.id) {
      const delTx = await apiRequest('DELETE', `/transactions/${newTx.data.id}`, token);
      check("Delete transaction", delTx.status === 200, `status=${delTx.status}`);
    }
  }
  console.log();
  
  // ===== 5. RECURRING TRANSACTIONS =====
  console.log("🔄 RECURRING TRANSACTIONS");
  const recs = await apiRequest('GET', '/recurring', token);
  check("Recurring load", recs.status === 200);
  check("Recurring is array", Array.isArray(recs.data));
  if (recs.data.length > 0) {
    const r = recs.data[0];
    check("Recurring has id", !!r.id);
    check("Recurring amount is number", typeof r.amount === 'number', `type=${typeof r.amount}, val=${r.amount}`);
    check("Recurring has frequency", !!r.frequency);
    check("Recurring has next_due_date", !!r.next_due_date);
    check("Recurring has status", !!r.status);
    check("Recurring has merchant", r.merchant !== undefined);
    check("Recurring auto_create is boolean", typeof r.auto_create === 'boolean', `type=${typeof r.auto_create}`);
  }
  
  // Test create recurring
  if (accountId) {
    const newRec = await apiRequest('POST', '/recurring', token, {
      type: 'expense',
      amount: 299,
      category_id: categoryId,
      account_id: accountId,
      frequency: 'monthly',
      next_due_date: new Date(Date.now() + 7 * 86400000).toISOString(),
      merchant: 'Test Subscription',
      reminder_days: 3,
      auto_create: true,
      status: 'active',
      variable_amount: false
    });
    check("Create recurring", newRec.status === 200 || newRec.status === 201, `status=${newRec.status} ${JSON.stringify(newRec.data).substring(0, 200)}`);
    
    if (newRec.data && newRec.data.id) {
      // Test update
      const updRec = await apiRequest('PUT', `/recurring/${newRec.data.id}`, token, {
        type: 'expense', amount: 399, frequency: 'monthly',
        next_due_date: new Date(Date.now() + 14 * 86400000).toISOString(),
        merchant: 'Updated Sub', status: 'active', auto_create: false
      });
      check("Update recurring", updRec.status === 200, `status=${updRec.status}`);
      
      // Test delete
      const delRec = await apiRequest('DELETE', `/recurring/${newRec.data.id}`, token);
      check("Delete recurring", delRec.status === 200, `status=${delRec.status}`);
    }
  }
  console.log();
  
  // ===== 6. BUDGETS =====
  console.log("📈 BUDGETS");
  const budgets = await apiRequest('GET', '/budgets', token);
  check("Budgets load", budgets.status === 200);
  check("Budgets is array", Array.isArray(budgets.data));
  if (budgets.data.length > 0) {
    const b = budgets.data[0];
    check("Budget has id", !!b.id);
    check("Budget has amount", b.amount !== undefined);
    check("Budget amount is number", typeof Number(b.amount) === 'number' && !isNaN(Number(b.amount)));
  }
  console.log();
  
  // ===== 7. SAVINGS GOALS =====
  console.log("🎯 SAVINGS GOALS");
  const goals = await apiRequest('GET', '/savings-goals', token);
  check("Savings goals load", goals.status === 200);
  check("Savings goals is array", Array.isArray(goals.data));
  console.log();
  
  // ===== 8. USER PROFILE =====
  console.log("👤 USER PROFILE");
  const profile = await apiRequest('GET', '/users/profile', token);
  check("Profile loads", profile.status === 200);
  check("Profile has name", !!profile.data.name);
  check("Profile has email", !!profile.data.email);
  console.log();
  
  // ===== SUMMARY =====
  console.log("═══════════════════════════════════");
  console.log(`📋 RESULTS: ${passed} passed, ${failed} failed`);
  if (issues.length > 0) {
    console.log("\n🔧 ISSUES TO FIX:");
    issues.forEach((iss, i) => console.log(`  ${i+1}. ${iss.name}: ${iss.detail}`));
  } else {
    console.log("🎉 All tests passed!");
  }
  console.log("═══════════════════════════════════");
  
  await client.end();
}

runTests().catch(console.error);
