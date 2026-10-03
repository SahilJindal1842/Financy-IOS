with open("src/jobs/recurringJob.ts", "r") as f:
    text = f.read()

text = text.replace('import { calculateBudgetAlertsAndNotify } from "../controllers/transactionController";', '')

with open("src/jobs/recurringJob.ts", "w") as f:
    f.write(text)
