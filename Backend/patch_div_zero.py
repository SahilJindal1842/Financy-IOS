with open("src/controllers/userController.ts", "r") as f:
    text = f.read()

import re

old_calc = "const budgetUsedPercentage = Math.min(100, Math.round((totalExpenses / totalBudget) * 100));"
new_calc = "const budgetUsedPercentage = totalBudget > 0 ? Math.min(100, Math.round((totalExpenses / totalBudget) * 100)) : 0;"

text = text.replace(old_calc, new_calc)

with open("src/controllers/userController.ts", "w") as f:
    f.write(text)
