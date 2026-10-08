# Double-Entry Bookkeeping & Ledger Reconciliation Reference

This guide provides standard accounting schemas, journal entry patterns, and reconciliation algorithms for auditing books of accounts.

---

## 1. The Accounting Mechanics

Every transaction must touch at least two accounts, maintaining equilibrium in:
$$\text{Assets} + \text{Expenses} + \text{Drawings} = \text{Liabilities} + \text{Equity} + \text{Revenue}$$

### Debit and Credit Mapping Table

| Account Classification | Normal Balance | To Increase (+) | To Decrease (-) |
| :--- | :--- | :--- | :--- |
| **Asset** | Debit | Debit | Credit |
| **Liability** | Credit | Credit | Debit |
| **Equity / Capital** | Credit | Credit | Debit |
| **Revenue / Income** | Credit | Credit | Debit |
| **Expense** | Debit | Debit | Credit |

---

## 2. Common Journal Entry Archetypes

### A. Income Inflow (e.g., Salary, Consulting Revenue)
```text
Debit:  Bank Account (Asset +)               ₹1,00,000
Credit: Salary / Consulting Income (Revenue +)           ₹1,00,000
```

### B. Expense Incurred & Paid Immediately
```text
Debit:  Rent / Grocery Expense (Expense +)    ₹25,000
Credit: Bank / Wallet Account (Asset -)                   ₹25,000
```

### C. Expense Incurred on Credit (Accrual Basis)
```text
Debit:  Software Subscription Expense (Expense +) ₹5,000
Credit: Credit Card Payable (Liability +)                  ₹5,000
```

### D. Credit Card Bill Settlement
```text
Debit:  Credit Card Payable (Liability -)    ₹5,000
Credit: Bank Account (Asset -)                             ₹5,000
```

### E. Account-to-Account Transfer (e.g., Bank to Cash/Wallet)
```text
Debit:  Cash Wallet (Asset +)                ₹10,000
Credit: Bank Account (Asset -)                            ₹10,000
(Net impact on Total Assets = ₹0)
```

### F. Investment Purchase (e.g., Mutual Fund, Stocks)
```text
Debit:  Investment Asset: Equity MF (Asset +) ₹20,000
Credit: Bank Account (Asset -)                            ₹20,000
```

---

## 3. Trial Balance & Balancing Tests

A Trial Balance lists all ledger accounts with their closing Debit and Credit balances.
$$\sum \text{Debit Balances} \equiv \sum \text{Credit Balances}$$

### Common Error Types in Ledger Analysis:
1. **Error of Omission**: A transaction was completely omitted from the books (Trial balance remains balanced, but net figures are understated).
2. **Error of Commission**: Correct amount posted to the correct side, but wrong account (e.g., posted to Office Equipment instead of Computer Equipment).
3. **Error of Principle**: Violating accounting standards (e.g., treating capital expenditure as revenue expense, such as expensing a vehicle purchase).
4. **Compensating Errors**: Two separate errors that cancel each other out in magnitude.
5. **Transposition Error**: Reversal of digits (e.g., ₹5,400 written as ₹4,500).
   * *Diagnostic Test*: If the difference between total debits and credits is divisible by 9 ($\Delta / 9 \in \mathbb{Z}$), suspect a transposition error.

---

## 4. Bank Reconciliation Statement (BRS) Procedure

A BRS reconciles the difference between the **Cash Book (Bank Column)** maintained by the entity and the **Passbook / Bank Statement** issued by the bank.

### Reconciliation Table:
| Particulars | Starting from Cash Book (Debit Balance) | Starting from Passbook (Credit Balance) |
| :--- | :--- | :--- |
| **Cheques issued but not yet presented for payment** | **Add (+)** | **Deduct (-)** |
| **Cheques deposited but not yet credited / cleared** | **Deduct (-)** | **Add (+)** |
| **Direct credits into bank (interest, client transfers)** | **Add (+)** | **Deduct (-)** |
| **Direct debits by bank (bank charges, EMI auto-debits)** | **Deduct (-)** | **Add (+)** |
| **Interest allowed/credited by bank** | **Add (+)** | **Deduct (-)** |
| **Wrong credit given by bank** | **Add (+)** | **Deduct (-)** |
| **Wrong debit given by bank** | **Deduct (-)** | **Add (+)** |
| **Target Result** | **= Passbook Balance** | **= Cash Book Balance** |

---

## 5. Depreciation Accounting (Fixed Assets)

### 1. Straight-Line Method (SLM):
$$\text{Annual Depreciation} = \frac{\text{Cost of Asset} - \text{Estimated Residual Value}}{\text{Useful Life (Years)}}$$

### 2. Written Down Value Method (WDV / Reducing Balance):
$$\text{Depreciation for Year } t = \text{Book Value at start of Year } t \times r$$
Where $r$ is the statutory depreciation rate (e.g., Companies Act 2013 / Income Tax Act 1961 depreciation schedule: Computers @ 40%, Furniture @ 10%, Plant & Machinery @ 15%).
