import { Response } from "express";
import db from "../db/db";
import { AuthRequest } from "../middleware/auth";
import { getQueryScope } from "../utils/rbacUtils";

export const getRecurringTransactions = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const transactions = await db("recurring_transactions").where(scope).whereNull("deleted_at");
    
    const formatted = transactions.map(t => ({
      id: t.id,
      user_id: t.user_id,
      type: t.type,
      amount: Number(t.amount),
      category_id: t.category_id,
      account_id: t.account_id,
      frequency: t.frequency,
      next_due_date: t.next_due_date,
      created_at: t.created_at,
      merchant: t.merchant,
      start_date: t.start_date,
      end_date: t.end_date,
      notes: t.notes,
      reminder_days: t.reminder_days,
      auto_create: t.auto_create,
      status: t.status,
      variable_amount: t.variable_amount
    }));
    
    res.json(formatted);
  } catch (error) {
    console.error(error); res.status(500).json({ error: "Internal server error" });
  }
};

export const createRecurringTransaction = async (req: AuthRequest, res: Response) => {
  try {
    const { type, amount, category_id, account_id, frequency, next_due_date, merchant, start_date, end_date, notes, reminder_days, auto_create, status, variable_amount } = req.body;
    
    // Enforce category ownership
    if (category_id) {
        const cat = await db("categories").where({ id: category_id }).first();
        if (!cat) {
            return res.status(400).json({ error: "Invalid category_id." });
        }
        if (cat.user_id !== null && cat.user_id !== req.user?.id) {
            return res.status(403).json({ error: "Access denied to this category." });
        }
    }

    // Fallback account logic
    let finalAccountId = account_id;
    let existingAccount = null;
    if (account_id) {
        existingAccount = await db("accounts").where({ id: account_id }).first();
    }
    if (!existingAccount) {
        let firstAccount = await db("accounts").where({ user_id: req.user?.id }).first();
        if (!firstAccount) {
            const [newAcc] = await db("accounts").insert({
                user_id: req.user?.id,
                name: "Main Account",
                type: "cash",
                currency_code: "INR"
            }).returning("*");
            firstAccount = newAcc;
        }
        finalAccountId = firstAccount.id;
    }

    const [transaction] = await db("recurring_transactions").insert({
      account_id: finalAccountId,
      user_id: req.user?.id,
      type,
      amount,
      category_id,
      frequency,
      next_due_date,
      merchant,
      start_date,
      end_date,
      notes,
      reminder_days: reminder_days ?? 3,
      auto_create: auto_create ?? true,
      status: status || 'active',
      variable_amount: variable_amount ?? false
    }).returning("*");
    res.status(201).json(transaction);
  } catch (error) {
    console.error(error); res.status(500).json({ error: "Internal server error" });
  }
};

export const updateRecurringTransaction = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { type, amount, category_id, account_id, frequency, next_due_date, merchant, start_date, end_date, notes, reminder_days, auto_create, status, variable_amount } = req.body;
    const [transaction] = await db("recurring_transactions")
      .where({ id, user_id: req.user?.id })
      .update({ type, amount, category_id, account_id, frequency, next_due_date, merchant, start_date, end_date, notes, reminder_days, auto_create, status, variable_amount, updated_at: db.fn.now() })
      .returning("*");
    
    if (!transaction) return res.status(404).json({ error: "Not found" });
    res.json(transaction);
  } catch (error) {
    console.error(error); res.status(500).json({ error: "Internal server error" });
  }
};

export const deleteRecurringTransaction = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const deleted = await db("recurring_transactions").where({ id, user_id: req.user?.id }).update({ deleted_at: db.fn.now() });
    if (!deleted) return res.status(404).json({ error: "Not found" });
    res.json({ success: true });
  } catch (error) {
    console.error(error); res.status(500).json({ error: "Internal server error" });
  }
};
