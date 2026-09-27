const fs = require('fs');
const file = 'src/controllers/budgetController.ts';
let content = fs.readFileSync(file, 'utf8');
content = content.replace(
  '    res.json(summary);',
  `    const totalBudget = summary.reduce((acc, curr) => acc + curr.amount, 0);
    const totalSpent = summary.reduce((acc, curr) => acc + curr.spent, 0);
    const remainingBudget = totalBudget - totalSpent;
    const overallUsagePercentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

    res.json({
      totalBudget,
      totalSpent,
      remainingBudget,
      overallUsagePercentage,
      budgets: summary
    });`
);
fs.writeFileSync(file, content);
