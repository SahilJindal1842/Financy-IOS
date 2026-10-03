with open("src/controllers/userController.ts", "r") as f:
    text = f.read()

import re

# Find the budget query
old_query = """    const budgets = await db("budgets")
      .where({ user_id: userId })
      .whereNull("deleted_at")
      .whereRaw("to_char(month, 'YYYY-MM') = ?", [currentMonthStr]);"""

new_query = """    // Get the latest budget for each category for this user
    const budgets = await db("budgets")
      .where({ user_id: userId })
      .whereNull("deleted_at")
      .distinctOn("category_id")
      .orderBy("category_id")
      .orderBy("month", "desc");"""

text = text.replace(old_query, new_query)

with open("src/controllers/userController.ts", "w") as f:
    f.write(text)
