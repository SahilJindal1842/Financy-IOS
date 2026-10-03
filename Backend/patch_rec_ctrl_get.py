with open("src/controllers/recurringController.ts", "r") as f:
    text = f.read()

import re

old_get = """export const getRecurringTransactions = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const transactions = await db("recurring_transactions").where(scope);
    res.json(transactions);
  } catch (error) {
    console.error(error); res.status(500).json({ error: "Internal server error" });
  }
};"""

new_get = """export const getRecurringTransactions = async (req: AuthRequest, res: Response) => {
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
};"""
text = text.replace(old_get, new_get)

with open("src/controllers/recurringController.ts", "w") as f:
    f.write(text)
