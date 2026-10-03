with open("src/index.ts", "r") as f:
    text = f.read()

import_statement = 'import { startRecurringJob } from "./jobs/recurringJob";\n'
if import_statement not in text:
    text = text.replace('import dotenv from "dotenv";', 'import dotenv from "dotenv";\n' + import_statement)

start_statement = 'startRecurringJob();\n'
if start_statement not in text:
    text = text.replace('app.listen(port,', start_statement + 'app.listen(port,')

with open("src/index.ts", "w") as f:
    f.write(text)
