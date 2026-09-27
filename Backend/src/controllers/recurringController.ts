import { Response } from "express";
import db from "../db/db";
import { AuthRequest } from "../middleware/auth";
import { getQueryScope } from "../utils/rbacUtils";

export const getRecurringTransactions = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const transactions = await db("recurring_transactions").where(scope);
    res.json(transactions);
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
};

export const createRecurringTransaction = async (req: AuthRequest, res: Response) => {
  try {
    const { type, amount, category_id, account_id, frequency, next_due_date } = req.body;
    const [transaction] = await db("recurring_transactions").insert({
      user_id: req.user?.id,
      type,
      amount,
      category_id,
      account_id,
      frequency,
      next_due_date
    }).returning("*");
    res.status(201).json(transaction);
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
};

export const updateRecurringTransaction = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { type, amount, category_id, account_id, frequency, next_due_date } = req.body;
    const [transaction] = await db("recurring_transactions")
      .where({ id, user_id: req.user?.id })
      .update({ type, amount, category_id, account_id, frequency, next_due_date, updated_at: db.fn.now() })
      .returning("*");
    
    if (!transaction) return res.status(404).json({ error: "Not found" });
    res.json(transaction);
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
};

export const deleteRecurringTransaction = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const deleted = await db("recurring_transactions").where({ id, user_id: req.user?.id }).del();
    if (!deleted) return res.status(404).json({ error: "Not found" });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
};
