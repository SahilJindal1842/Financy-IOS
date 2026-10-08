# FinPilotAI / Financy Financial Audit & Data Integrity Runbook

This guide contains specific auditing queries and data reconciliation procedures for the FinPilotAI PostgreSQL database.

---

## 1. Schema Overview & Audit Invariants

### Relevant Tables:
- `users`: `id`, `email`, `name`, `currency`
- `accounts`: `id`, `user_id`, `name`, `type` (`CHECKING`, `SAVINGS`, `CREDIT_CARD`, `CASH`, `INVESTMENT`), `balance`, `currency`
- `categories`: `id`, `user_id`, `name`, `type` (`INCOME`, `EXPENSE`, `TRANSFER`), `is_system`
- `transactions`: `id`, `user_id`, `account_id`, `category_id`, `amount`, `type` (`INCOME`, `EXPENSE`, `TRANSFER`), `date`, `note`
- `budgets`: `id`, `user_id`, `category_id`, `amount`, `spent`, `month` (YYYY-MM), `period`
- `monthly_savings`: `id`, `user_id`, `month` (YYYY-MM), `total_income`, `total_expenses`, `savings_amount`

---

## 2. Core Audit Invariants to Enforce

1. **Account Balance Reconciliation**:
   $$\text{account.balance} = \text{initial\_balance} + \sum \text{INCOME} - \sum \text{EXPENSE} \pm \sum \text{TRANSFER}$$
2. **Monthly Savings Integrity**:
   $$\text{monthly\_savings.savings\_amount} \equiv \text{monthly\_savings.total\_income} - \text{monthly\_savings.total\_expenses}$$
3. **Budget Spent Reconciliation**:
   $$\text{budget.spent} \equiv \sum_{t \in \text{transactions}} t.\text{amount} \quad (\text{matching user, category, and month})$$
4. **Transfer Conservatism**:
   Internal transfers between user accounts must not modify the user's aggregate Net Worth.
5. **No Negative Cash / Overdrawn Savings**:
   Unless an account is explicitly of type `CREDIT_CARD` or `LOAN`, non-credit accounts should flag an alert if `balance < 0`.

---

## 3. SQL Diagnostic Audit Queries

### A. Detect Discrepancy between Account Balance and Recorded Transactions
```sql
SELECT 
    a.id AS account_id,
    a.name AS account_name,
    a.balance AS recorded_balance,
    COALESCE(SUM(CASE WHEN t.type = 'INCOME' THEN t.amount ELSE 0 END), 0) AS total_inflow,
    COALESCE(SUM(CASE WHEN t.type = 'EXPENSE' THEN t.amount ELSE 0 END), 0) AS total_outflow,
    (COALESCE(SUM(CASE WHEN t.type = 'INCOME' THEN t.amount ELSE 0 END), 0) - 
     COALESCE(SUM(CASE WHEN t.type = 'EXPENSE' THEN t.amount ELSE 0 END), 0)) AS net_transaction_sum,
    ABS(a.balance - (COALESCE(SUM(CASE WHEN t.type = 'INCOME' THEN t.amount ELSE 0 END), 0) - 
                     COALESCE(SUM(CASE WHEN t.type = 'EXPENSE' THEN t.amount ELSE 0 END), 0))) AS variance
FROM accounts a
LEFT JOIN transactions t ON a.id = t.account_id
GROUP BY a.id, a.name, a.balance
ORDER BY variance DESC;
```

### B. Find Duplicate Transactions (Same User, Amount, Date/Time within 60 Seconds)
```sql
SELECT 
    t1.id AS tx1_id,
    t2.id AS tx2_id,
    t1.user_id,
    t1.amount,
    t1.category_id,
    t1.date AS tx1_time,
    t2.date AS tx2_time,
    ABS(EXTRACT(EPOCH FROM (t1.date - t2.date))) AS seconds_apart
FROM transactions t1
JOIN transactions t2 ON t1.user_id = t2.user_id 
                    AND t1.id < t2.id 
                    AND t1.amount = t2.amount 
                    AND t1.category_id = t2.category_id
WHERE ABS(EXTRACT(EPOCH FROM (t1.date - t2.date))) <= 60
ORDER BY t1.date DESC;
```

### C. Verify Monthly Savings Calculation
```sql
WITH computed_savings AS (
    SELECT 
        user_id,
        TO_CHAR(date, 'YYYY-MM') AS month_str,
        COALESCE(SUM(CASE WHEN type = 'INCOME' THEN amount ELSE 0 END), 0) AS calc_income,
        COALESCE(SUM(CASE WHEN type = 'EXPENSE' THEN amount ELSE 0 END), 0) AS calc_expense,
        COALESCE(SUM(CASE WHEN type = 'INCOME' THEN amount ELSE 0 END), 0) - 
        COALESCE(SUM(CASE WHEN type = 'EXPENSE' THEN amount ELSE 0 END), 0) AS calc_savings
    FROM transactions
    GROUP BY user_id, TO_CHAR(date, 'YYYY-MM')
)
SELECT 
    ms.user_id,
    ms.month,
    ms.total_income AS recorded_income,
    cs.calc_income,
    ms.total_expenses AS recorded_expenses,
    cs.calc_expense,
    ms.savings_amount AS recorded_savings,
    cs.calc_savings,
    ABS(ms.savings_amount - cs.calc_savings) AS discrepancy
FROM monthly_savings ms
JOIN computed_savings cs ON ms.user_id = cs.user_id AND ms.month = cs.month_str
WHERE ABS(ms.savings_amount - cs.calc_savings) > 0.01;
```

### D. Identify Over-Budget Categories & Burn Rate
```sql
SELECT 
    b.id AS budget_id,
    u.name AS user_name,
    c.name AS category_name,
    b.month,
    b.amount AS budget_limit,
    b.spent AS actual_spent,
    (b.spent - b.amount) AS overspend_amount,
    ROUND((b.spent / NULLIF(b.amount, 0) * 100)::numeric, 2) AS utilization_pct
FROM budgets b
JOIN users u ON b.user_id = u.id
JOIN categories c ON b.category_id = c.id
WHERE b.spent > b.amount
ORDER BY utilization_pct DESC;
```

---

## 4. Anomaly Spotting & Forensic Checklist

1. **Spike Detection**: Any single transaction greater than $3\times$ the user's 90-day standard deviation for that category.
2. **Round Number Anomaly**: Unusual clustering of round sums (e.g., ₹10,000, ₹50,000) in cash accounts without invoice notes.
3. **Orphan Records**: Transactions pointing to non-existent `account_id` or `category_id`.
4. **Time Inconsistencies**: Transactions with timestamps in the future or pre-dating account creation.
