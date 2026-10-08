#!/usr/bin/env python3
"""
Chartered Accountant Verification & Tax Computation Utility
Provides automated verification for ledger balancing, tax liability comparison
(New vs Old Indian Regime AY 2025-26), and financial health ratios.
"""

import sys
import json
from dataclasses import dataclass
from typing import List, Dict, Any, Tuple

@dataclass
class JournalEntry:
    account: str
    debit: float = 0.0
    credit: float = 0.0
    description: str = ""

def verify_trial_balance(entries: List[JournalEntry]) -> Dict[str, Any]:
    """Verifies that total debits equal total credits in a batch of journal entries."""
    total_debits = sum(e.debit for e in entries)
    total_credits = sum(e.credit for e in entries)
    difference = round(total_debits - total_credits, 2)
    is_balanced = abs(difference) < 0.01

    account_balances: Dict[str, float] = {}
    for e in entries:
        account_balances[e.account] = round(account_balances.get(e.account, 0.0) + e.debit - e.credit, 2)

    result = {
        "is_balanced": is_balanced,
        "total_debits": round(total_debits, 2),
        "total_credits": round(total_credits, 2),
        "difference": difference,
        "transposition_suspect": difference != 0 and (round(difference * 100) % 9 == 0),
        "account_balances": account_balances
    }
    return result

def calculate_income_tax_new_regime(gross_income: float, is_salaried: bool = True) -> Dict[str, Any]:
    """
    Computes Income Tax under Section 115BAC (New Tax Regime) for Individuals (AY 2025-26).
    Standard deduction: ₹75,000 for salaried.
    Rebate u/s 87A: Up to ₹7,00,000 taxable income.
    """
    std_deduction = 75000.0 if is_salaried else 0.0
    taxable_income = max(0.0, gross_income - std_deduction)

    slabs = [
        (300000, 0.00),
        (400000, 0.05),  # 3L - 7L (span 4L)
        (300000, 0.10),  # 7L - 10L (span 3L)
        (200000, 0.15),  # 10L - 12L (span 2L)
        (300000, 0.20),  # 12L - 15L (span 3L)
        (float('inf'), 0.30) # Above 15L
    ]

    tax = 0.0
    remaining = taxable_income

    for span, rate in slabs:
        if remaining <= 0:
            break
        taxable_in_slab = min(remaining, span)
        tax += taxable_in_slab * rate
        remaining -= taxable_in_slab

    # Rebate u/s 87A if taxable income <= 7,00,000
    rebate = 0.0
    if taxable_income <= 700000:
        rebate = tax
        tax = 0.0

    cess = tax * 0.04
    total_tax = tax + cess

    return {
        "regime": "New Regime (u/s 115BAC)",
        "gross_income": gross_income,
        "standard_deduction": std_deduction,
        "taxable_income": taxable_income,
        "basic_tax": round(tax, 2),
        "rebate_87a": round(rebate, 2),
        "cess_4_pct": round(cess, 2),
        "total_tax_payable": round(total_tax, 2),
        "effective_rate_pct": round((total_tax / gross_income * 100), 2) if gross_income > 0 else 0.0
    }

def calculate_income_tax_old_regime(
    gross_income: float,
    deductions_80c: float = 0.0,
    deductions_80d: float = 0.0,
    hra_exemption: float = 0.0,
    home_loan_interest_24b: float = 0.0,
    nps_80ccd_1b: float = 0.0,
    is_salaried: bool = True
) -> Dict[str, Any]:
    """Computes Income Tax under the Old Tax Regime with standard deductions & Chapter VI-A."""
    std_deduction = 50000.0 if is_salaried else 0.0
    capped_80c = min(150000.0, max(0.0, deductions_80c))
    capped_80d = min(100000.0, max(0.0, deductions_80d))
    capped_24b = min(200000.0, max(0.0, home_loan_interest_24b))
    capped_nps = min(50000.0, max(0.0, nps_80ccd_1b))

    total_deductions = std_deduction + capped_80c + capped_80d + hra_exemption + capped_24b + capped_nps
    taxable_income = max(0.0, gross_income - total_deductions)

    slabs = [
        (250000, 0.00),
        (250000, 0.05),  # 2.5L - 5L
        (500000, 0.20),  # 5L - 10L
        (float('inf'), 0.30) # Above 10L
    ]

    tax = 0.0
    remaining = taxable_income
    for span, rate in slabs:
        if remaining <= 0:
            break
        taxable_in_slab = min(remaining, span)
        tax += taxable_in_slab * rate
        remaining -= taxable_in_slab

    rebate = 0.0
    if taxable_income <= 500000:
        rebate = min(tax, 12500.0)
        tax = max(0.0, tax - rebate)

    cess = tax * 0.04
    total_tax = tax + cess

    return {
        "regime": "Old Regime",
        "gross_income": gross_income,
        "total_deductions": total_deductions,
        "taxable_income": taxable_income,
        "basic_tax": round(tax, 2),
        "rebate_87a": round(rebate, 2),
        "cess_4_pct": round(cess, 2),
        "total_tax_payable": round(total_tax, 2),
        "effective_rate_pct": round((total_tax / gross_income * 100), 2) if gross_income > 0 else 0.0
    }

def evaluate_financial_health(monthly_income: float, monthly_expenses: float, liquid_savings: float, monthly_emi: float) -> Dict[str, Any]:
    """Calculates key wealth, liquidity, and debt metrics (50/30/20, DTI, Runway)."""
    net_savings = monthly_income - monthly_expenses
    savings_rate_pct = (net_savings / monthly_income * 100) if monthly_income > 0 else 0.0
    dti_pct = (monthly_emi / monthly_income * 100) if monthly_income > 0 else 0.0
    emergency_runway_months = (liquid_savings / monthly_expenses) if monthly_expenses > 0 else 0.0

    return {
        "monthly_income": monthly_income,
        "monthly_expenses": monthly_expenses,
        "net_monthly_savings": net_savings,
        "savings_rate_pct": round(savings_rate_pct, 2),
        "dti_ratio_pct": round(dti_pct, 2),
        "dti_status": "Healthy (<35%)" if dti_pct <= 35 else ("Warning (35-45%)" if dti_pct <= 45 else "Critical (>45%)"),
        "emergency_runway_months": round(emergency_runway_months, 1),
        "emergency_fund_status": "Sufficient (>= 6 mo)" if emergency_runway_months >= 6 else ("Moderate (3-6 mo)" if emergency_runway_months >= 3 else "Insufficient (< 3 mo)"),
        "suggested_50_30_20": {
            "needs_max_50": round(monthly_income * 0.50, 2),
            "wants_max_30": round(monthly_income * 0.30, 2),
            "savings_min_20": round(monthly_income * 0.20, 2)
        }
    }

if __name__ == "__main__":
    print("=== Chartered Accountant Verification Test ===")
    # Quick sanity test
    test_entries = [
        JournalEntry("Bank Account", debit=100000, credit=0, description="Salary Credit"),
        JournalEntry("Salary Income", debit=0, credit=100000, description="Salary Revenue"),
        JournalEntry("Rent Expense", debit=25000, credit=0, description="Office Rent"),
        JournalEntry("Bank Account", debit=0, credit=25000, description="Rent Payment")
    ]
    tb = verify_trial_balance(test_entries)
    print("Trial balance balanced:", tb["is_balanced"], f"(Total: ₹{tb['total_debits']})")

    tax_new = calculate_income_tax_new_regime(1200000, is_salaried=True)
    tax_old = calculate_income_tax_old_regime(1200000, deductions_80c=150000, deductions_80d=25000, is_salaried=True)
    print(f"Tax on ₹12,00,000 Salaried: New Regime = ₹{tax_new['total_tax_payable']} vs Old Regime = ₹{tax_old['total_tax_payable']}")
    health = evaluate_financial_health(150000, 80000, 400000, 25000)
    print("Runway:", health["emergency_runway_months"], "months | DTI:", health["dti_ratio_pct"], "%")
