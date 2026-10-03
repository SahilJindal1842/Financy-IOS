with open("src/controllers/recurringController.ts", "r") as f:
    text = f.read()

import re

old_insert = """    const { type, amount, category_id, account_id, frequency, next_due_date, merchant, start_date, end_date, notes, reminder_days, auto_create, status, variable_amount } = req.body;
    const [transaction] = await db("recurring_transactions").insert({"""

new_insert = """    const { type, amount, category_id, account_id, frequency, next_due_date, merchant, start_date, end_date, notes, reminder_days, auto_create, status, variable_amount } = req.body;
    
    // Fallback account logic
    let finalAccountId = account_id;
    const existingAccount = await db("accounts").where({ id: account_id }).first();
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
      account_id: finalAccountId,"""

text = text.replace(old_insert, new_insert)
text = text.replace("account_id,\n      frequency", "frequency")

with open("src/controllers/recurringController.ts", "w") as f:
    f.write(text)
