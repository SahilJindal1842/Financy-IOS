with open("src/controllers/userController.ts", "r") as f:
    text = f.read()

import re

old_fallback = """    let totalBudget = 0;
    for (const b of budgets) {
        totalBudget += Number(b.amount || 0);
    }
    
    // Fallback if no budget set
    if (totalBudget === 0) totalBudget = totalIncome > 0 ? totalIncome : 1000;"""

new_fallback = """    let totalBudget = 0;
    for (const b of budgets) {
        totalBudget += Number(b.amount || 0);
    }
    """

text = text.replace(old_fallback, new_fallback)

with open("src/controllers/userController.ts", "w") as f:
    f.write(text)
