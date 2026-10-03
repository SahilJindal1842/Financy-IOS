with open("src/controllers/recurringController.ts", "r") as f:
    text = f.read()

# createRecurringTransaction
old_create = """    const { type, amount, category_id, account_id, frequency, next_due_date } = req.body;
    const [transaction] = await db("recurring_transactions").insert({
      user_id: req.user?.id,
      type,
      amount,
      category_id,
      account_id,
      frequency,
      next_due_date
    }).returning("*");"""

new_create = """    const { type, amount, category_id, account_id, frequency, next_due_date, merchant, start_date, end_date, notes, reminder_days, auto_create, status, variable_amount } = req.body;
    const [transaction] = await db("recurring_transactions").insert({
      user_id: req.user?.id,
      type,
      amount,
      category_id,
      account_id,
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
    }).returning("*");"""
text = text.replace(old_create, new_create)

# updateRecurringTransaction
old_update = """    const { type, amount, category_id, account_id, frequency, next_due_date } = req.body;
    const [transaction] = await db("recurring_transactions")
      .where({ id, user_id: req.user?.id })
      .update({ type, amount, category_id, account_id, frequency, next_due_date, updated_at: db.fn.now() })"""

new_update = """    const { type, amount, category_id, account_id, frequency, next_due_date, merchant, start_date, end_date, notes, reminder_days, auto_create, status, variable_amount } = req.body;
    const [transaction] = await db("recurring_transactions")
      .where({ id, user_id: req.user?.id })
      .update({ type, amount, category_id, account_id, frequency, next_due_date, merchant, start_date, end_date, notes, reminder_days, auto_create, status, variable_amount, updated_at: db.fn.now() })"""
text = text.replace(old_update, new_update)

with open("src/controllers/recurringController.ts", "w") as f:
    f.write(text)
