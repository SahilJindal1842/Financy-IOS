---
name: chartered-accountant
description: >-
  Expert Chartered Accountant (CA), CPA, and financial auditor skill.
  Use when analyzing, reviewing, or calculating financial statements (Balance Sheet, P&L, Cash Flow),
  double-entry bookkeeping, ledger reconciliation, bank reconciliation (BRS), Indian taxation
  (Income Tax, TDS, GST, Capital Gains under latest budget), audit trail verification, budget variance,
  expense categorization, and personal/corporate financial health metrics.
---

# Chartered Accountant (CA) & Financial Auditor Skill

This skill equips Antigravity with the rigorous methodology, standards, and domain expertise of an ICAI Chartered Accountant / CPA. It guides financial data modeling, ledger auditing, tax estimation, reconciliation, and statutory financial compliance for both business systems and personal finance applications (such as FinPilotAI / Financy).

---

## 1. Core Accounting Principles & Frameworks

### The Fundamental Accounting Equation
$$\text{Assets} = \text{Liabilities} + \text{Equity}$$

### Golden Rules of Accounting (Double-Entry)
1. **Real Accounts** (Assets, Cash, Property, Equipment):
   - **Debit what comes in** (+ Asset)
   - **Credit what goes out** (- Asset)
2. **Personal Accounts** (Debtors, Creditors, Banks, Persons):
   - **Debit the receiver** (+ Receivable / - Payable)
   - **Credit the giver** (- Receivable / + Payable)
3. **Nominal Accounts** (Expenses, Losses, Income, Gains):
   - **Debit all expenses and losses** (+ Expense)
   - **Credit all incomes and gains** (+ Revenue)

### Modern Dual-Aspect Classification (DC-ADE / DEALER)
- **Debit Normal Balance (Increases with Debit, Decreases with Credit)**:
  - **D**rawings / Dividends
  - **E**xpenses
  - **A**ssets
- **Credit Normal Balance (Increases with Credit, Decreases with Debit)**:
  - **L**iabilities
  - **E**quity / Capital
  - **R**evenue / Income

---

## 2. Standard Financial Statements & Equations

### A. Statement of Profit & Loss (Income Statement)
$$\text{Gross Profit} = \text{Revenue from Operations} - \text{Cost of Goods Sold (COGS)}$$
$$\text{EBITDA} = \text{Gross Profit} - \text{Operating Expenses (OPEX)}$$
$$\text{EBIT (Operating Income)} = \text{EBITDA} - \text{Depreciation \& Amortization}$$
$$\text{Profit Before Tax (PBT)} = \text{EBIT} - \text{Interest / Finance Costs} + \text{Other Income}$$
$$\text{Profit After Tax (PAT / Net Income)} = \text{PBT} - \text{Tax Expense}$$

### B. Statement of Financial Position (Balance Sheet)
- **Total Assets** = Current Assets (Cash, Bank, Accounts Receivable, Short-term Liquid Investments, Prepaid Expenses) + Non-Current Assets (PP&E, Intangibles, Long-term Investments).
- **Total Liabilities** = Current Liabilities (Accounts Payable, Credit Card balances, Short-term Loans, Outstanding Expenses) + Non-Current Liabilities (Term Loans, Mortgages).
- **Owner's Equity / Net Worth** = Total Assets - Total Liabilities.

### C. Cash Flow Statement (Ind AS 7 / AS 3 / IAS 7)
- **Cash Flow from Operating Activities (CFO)**: Net Income + Non-cash items (Depreciation) $\pm$ Working Capital Changes.
- **Cash Flow from Investing Activities (CFI)**: CapEx purchase/sale of assets, mutual fund investments, equity purchases.
- **Cash Flow from Financing Activities (CFF)**: Debt issuance/repayment, owner draws, equity infusions, dividend disbursements.
$$\Delta \text{Cash} = \text{CFO} + \text{CFI} + \text{CFF}$$

---

## 3. Auditing & Ledger Reconciliation Workflows

Whenever inspecting or writing code for transactions, ledger entries, or account balances:

### Step 1: Verify Transaction Integrity
- **Atomicity**: Transfers between accounts (`Account A -> Account B`) must have balanced debits and credits. Total net worth remains invariant during internal transfers.
- **Sign convention**:
  - `INCOME`: Positive cash inflow to asset/account.
  - `EXPENSE`: Positive expense debit, cash outflow from asset/account.
  - `TRANSFER`: Equal and opposite debit/credit between source and destination accounts.
- **Duplicate Detection**: Check for identical amount + identical category/merchant + timestamp delta $< 60$ seconds.

### Step 2: Bank Reconciliation Statement (BRS)
$$\text{Adjusted Bank Balance} = \text{Bank Statement Balance} + \text{Deposits in Transit} - \text{Outstanding Cheques} \pm \text{Bank Errors}$$
$$\text{Adjusted Book Balance} = \text{Book Balance} + \text{Direct Bank Credits (Interest/Dividends)} - \text{Direct Bank Debits (Charges/Auto-debits)} \pm \text{Book Errors}$$
Ensure:
$$\text{Adjusted Bank Balance} \equiv \text{Adjusted Book Balance}$$

### Step 3: Month-End Close Checklist
1. Reconcile all bank/card statements against logged transactions.
2. Verify all uncleared/pending transactions.
3. Compute monthly net savings:
   $$\text{Monthly Savings} = \sum \text{Income} - \sum \text{Expenses}$$
4. Calculate budget variance:
   $$\text{Variance} = \text{Budgeted Amount} - \text{Actual Expense}$$
   - Favorable ($> 0$): Under budget.
   - Unfavorable ($< 0$): Over budget.
5. Accrue recurring expenses that occurred in the period but remain unbilled.

---

## 4. Indian Taxation Compliance (ICAI Standards & Budget Updates)

Refer to [taxation_in.md](./references/taxation_in.md) for full statutory tax details.

### Income Tax Slabs (New Tax Regime u/s 115BAC - Default Regime)
- ₹0 to ₹3,00,000: **Nil**
- ₹3,00,001 to ₹7,00,000: **5%**
- ₹7,00,001 to ₹10,00,000: **10%**
- ₹10,00,001 to ₹12,00,000: **15%**
- ₹12,00,001 to ₹15,00,000: **20%**
- Above ₹15,00,000: **30%**
- *Rebate u/s 87A*: Nil tax if total taxable income $\le$ ₹7,00,000 (effectively up to ₹7.75L with Standard Deduction).
- *Standard Deduction*: ₹75,000 for salaried employees.
- *Health & Education Cess*: 4% on calculated tax liability.

### Capital Gains Tax (Revised Rates)
- **Listed Equity / Equity Mutual Funds**:
  - **STCG (u/s 111A, held $\le$ 12 months)**: **20%** flat.
  - **LTCG (u/s 112A, held $> 12$ months)**: **12.5%** for gains exceeding annual exemption threshold of ₹1,25,000.
- **Debt Funds / Unlisted Securities**:
  - Taxed at applicable slab rate (STCG) or 12.5% without indexation (LTCG as applicable).

### Tax Deducted at Source (TDS) Common Sections
- **Sec 192**: Salary (based on estimated slab).
- **Sec 194J**: Technical Services (2%), Professional Fees / Royalty (10%).
- **Sec 194C**: Contractors (1% Individual/HUF, 2% Company/Firm).
- **Sec 194I**: Rent (10% on land/building, 2% on plant/machinery).
- **Sec 194A**: Interest other than securities (10% if exceeding ₹40k/₹50k senior citizens).

### Goods and Services Tax (GST)
- **Standard Tax Slabs**: 0%, 5%, 12%, 18%, 28%.
- **Intra-State**: CGST (50%) + SGST (50%).
- **Inter-State**: IGST (100%).
- **Input Tax Credit (ITC)**: Must reconcile inward supply with GSTR-2B before claiming against GSTR-3B output liability.

---

## 5. Personal Finance & Wealth Advisory Metrics

When providing financial analysis, recommendations, or UI dashboards:

1. **50/30/20 Rule**:
   - **Needs (50%)**: Rent, utilities, groceries, EMIs, mandatory insurance.
   - **Wants (30%)**: Dining, entertainment, shopping, vacations.
   - **Savings/Debt Payoff (20%)**: Emergency fund, retirement (PPF/EPF/NPS), investments.
2. **Emergency Fund Health**:
   - Target = $\text{Monthly Fixed Mandatory Expenses} \times 6$ months.
   - Kept in high-liquidity instruments (Savings bank, Liquid Mutual Funds, Auto-sweep FDs).
3. **Debt-to-Income (DTI) Ratio**:
   $$\text{DTI} = \frac{\sum \text{Monthly Debt Repayments (EMIs)}}{\text{Gross Monthly Income}} \times 100$$
   - Healthy: $\le 35\%$. Critical warning: $> 45\%$.
4. **Burn Rate & Runway** (For freelancers, individuals, or startups):
   $$\text{Runway (Months)} = \frac{\text{Total Liquid Reserves}}{\text{Average Net Monthly Deficit}}$$

---

## 6. FinPilot / Financy Database Schema Verification

When auditing data within FinPilotAI:
- Database tables: `users`, `accounts`, `categories`, `transactions`, `budgets`, `recurring_transactions`, `monthly_savings`.
- Audit points:
  1. `accounts.balance` must equal initial balance + sum of income transactions - sum of expense transactions $\pm$ net transfers.
  2. `budgets.spent` must match sum of `transactions.amount` where `category_id` = budget category and `date` within budget month.
  3. `monthly_savings.savings_amount` must equal `total_income - total_expenses`.
  4. Negative account balances should trigger overdraft / insolvency warnings unless the account type is `CREDIT_CARD` or `LOAN`.

---

## 7. Execution Runbook for Financial Queries & Audits

When tasked with financial calculation, tax computation, or ledger auditing:
1. **Clarify Context**: Determine jurisdiction (India vs US/Global), entity type (individual vs corporate), and financial period.
2. **Inspect the Data**: Validate debit/credit consistency, check for missing values or unallocated suspense items.
3. **Apply Statutory Rates**: Apply appropriate tax regimes, standard deductions, and exemptions.
4. **Deliver Structured Analysis**:
   - Executive Summary
   - Itemized Ledger / Statement breakdown
   - Variance & Anomalies identified
   - Recommendations / Tax-saving opportunities
