import { Response } from "express";
import db from "../db/db";
import { AuthRequest } from "../middleware/auth";
import { getQueryScope } from "../utils/rbacUtils";

export const getBudgetSummary = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const userId = scope.user_id;

    let monthStr = req.query.month as string;
    if (!monthStr || !/^\d{4}-\d{2}$/.test(monthStr)) {
      const now = new Date();
      monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    }

    const startDate = `${monthStr}-01`;
    // Create an end date for the query (first day of next month)
    const [year, month] = monthStr.split("-").map(Number);
    const nextMonth = month === 12 ? 1 : month + 1;
    const nextYear = month === 12 ? year + 1 : year;
    const endDate = `${nextYear}-${String(nextMonth).padStart(2, "0")}-01`;

    // Fetch budgets for the user for this month
    const budgets = await db("budgets")
      .where(scope)
      .andWhere("month", startDate)
      .whereNull("deleted_at");

    // Fetch all categories to build the hierarchy
    const categories = await db("categories")
      .where(function() {
        this.where(scope).orWhereNull("user_id")
      })
      .whereNull("deleted_at")
      .whereNull("deleted_at");

    // Fetch expenses for the month
    const expenses = await db("transactions")
      .where(scope)
      .andWhere("type", "EXPENSE")
      .andWhere("date", ">=", startDate)
      .andWhere("date", "<", endDate)
      .whereNull("deleted_at");

    // Group expenses by category_id
    const expensesByCategory: Record<string, number> = {};
    for (const exp of expenses) {
      if (exp.category_id) {
        expensesByCategory[exp.category_id] = (expensesByCategory[exp.category_id] || 0) + Math.abs(Number(exp.amount));
      }
    }

    // Build subcategories map: parent_id -> array of child ids
    const childCategories: Record<string, string[]> = {};
    for (const cat of categories) {
      if (cat.parent_id) {
        if (!childCategories[cat.parent_id]) {
          childCategories[cat.parent_id] = [];
        }
        childCategories[cat.parent_id].push(cat.id);
      }
    }

    const prevMonth = month === 1 ? 12 : month - 1;
    const prevYear = month === 1 ? year - 1 : year;
    const prevStartDate = `${prevYear}-${String(prevMonth).padStart(2, "0")}-01`;

    const prevBudgets = await db("budgets")
      .where(scope)
      .andWhere("month", prevStartDate)
      .andWhere("rollover_enabled", true)
      .whereNull("deleted_at");

    const prevExpenses = await db("transactions")
      .where(scope)
      .andWhere("type", "EXPENSE")
      .andWhere("date", ">=", prevStartDate)
      .andWhere("date", "<", startDate)
      .whereNull("deleted_at");

    const prevExpensesByCategory: Record<string, number> = {};
    for (const exp of prevExpenses) {
      if (exp.category_id) {
        prevExpensesByCategory[exp.category_id] = (prevExpensesByCategory[exp.category_id] || 0) + Math.abs(Number(exp.amount));
      }
    }

    const summary = budgets.map(budget => {
      let spent = expensesByCategory[budget.category_id] || 0;
      let prevSpent = prevExpensesByCategory[budget.category_id] || 0;
      
      // Add expenses from subcategories
      const children = childCategories[budget.category_id] || [];
      for (const childId of children) {
        spent += (expensesByCategory[childId] || 0);
        prevSpent += (prevExpensesByCategory[childId] || 0);
      }

      let amount = Number(budget.amount);

      if (budget.rollover_enabled) {
        const prevBudget = prevBudgets.find(b => b.category_id === budget.category_id);
        if (prevBudget) {
          const prevRemaining = Number(prevBudget.amount) - prevSpent;
          if (prevRemaining > 0) {
            amount += prevRemaining;
          }
        }
      }

      const remaining = amount - spent;
      const usagePercentage = amount > 0 ? (spent / amount) * 100 : 0;

      // Find category details for enrichment
      const category = categories.find(c => c.id === budget.category_id);

      return {
        id: budget.id,
        categoryId: budget.category_id,
        categoryName: category ? category.name : "Unknown",
        amount,
        spent,
        remaining,
        usagePercentage,
        month: budget.month,
        rolloverEnabled: budget.rollover_enabled
      };
    });

    const totalBudget = summary.reduce((acc, curr) => acc + curr.amount, 0);
    const totalSpent = summary.reduce((acc, curr) => acc + curr.spent, 0);
    const remainingBudget = totalBudget - totalSpent;
    const overallUsagePercentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

    const settledMonthRecord = await db("monthly_savings")
      .where(scope)
      .andWhere("month", monthStr)
      .first();
    const isSettled = !!settledMonthRecord;

    res.json({
      totalBudget,
      totalSpent,
      remainingBudget,
      overallUsagePercentage,
      budgets: summary,
      isSettled
    });
  } catch (error) {
    console.error("Error fetching budget summary:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const setBudget = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const userId = scope.user_id;
    if (!userId && !req.user?.role) return res.status(401).json({ error: "Unauthorized" });

    const { category_id, amount, apply_to_year, apply_to_upcoming_months, year } = req.body;
    let monthStr = req.body.month as string;

    if (!category_id || amount === undefined) {
      return res.status(400).json({ error: "category_id and amount are required" });
    }

    if (!monthStr || !/^\d{4}-\d{2}$/.test(monthStr)) {
      const now = new Date();
      monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    }

    const [strYear, strMonth] = monthStr.split("-").map(Number);
    const targetYear = year ? Number(year) : strYear;

    // Fetch all settled months for this user
    const settledRecords = await db("monthly_savings").where({ user_id: userId }).select("month");
    const settledMonthSet = new Set(settledRecords.map(r => r.month));

    if (!apply_to_year && !apply_to_upcoming_months) {
      if (settledMonthSet.has(monthStr)) {
        return res.status(400).json({
          error: `Month ${monthStr} has already been settled and locked. Budgets cannot be set or updated for a settled month.`
        });
      }
    }

    if (apply_to_year || apply_to_upcoming_months) {
      const startM = apply_to_upcoming_months ? strMonth : 1;
      let updatedCount = 0;

      await db.transaction(async (trx) => {
        for (let m = startM; m <= 12; m++) {
          const mKey = `${targetYear}-${String(m).padStart(2, "0")}`;
          // Skip settled months
          if (settledMonthSet.has(mKey)) continue;

          const mStr = `${mKey}-01`;
          const existing = await trx("budgets")
            .where({ user_id: userId, category_id, month: mStr })
            .first();

          if (existing) {
            await trx("budgets")
              .where({ id: existing.id })
              .update({ amount: Number(amount) });
          } else {
            await trx("budgets")
              .insert({ user_id: userId, category_id, amount: Number(amount), month: mStr });
          }
          updatedCount++;
        }

        // Activity notification
        await trx("notifications").insert({
          user_id: userId,
          type: "budget",
          title: "Budget Updated",
          message: `Budget of ₹${Number(amount).toFixed(2)} applied across ${updatedCount} month(s) of ${targetYear}.`
        });
      });

      return res.json({
        success: true,
        message: apply_to_upcoming_months
          ? `Budget applied to upcoming months of ${targetYear} (${updatedCount} months active)`
          : `Budget set monthly for all active months of ${targetYear} (${updatedCount} months)`
      });
    }

    const monthDate = `${monthStr}-01`;

    // Check if budget exists
    const existing = await db("budgets")
      .where({ user_id: userId, category_id, month: monthDate })
      .first();

    let result;
    if (existing) {
      result = await db("budgets")
        .where({ id: existing.id })
        .update({ amount: Number(amount) })
        .returning("*");
    } else {
      result = await db("budgets")
        .insert({ user_id: userId, category_id, amount: Number(amount), month: monthDate })
        .returning("*");
    }

    // Insert activity notification
    await db("notifications").insert({
      user_id: userId,
      type: "budget",
      title: "Budget Updated",
      message: `Budget of ₹${Number(amount).toFixed(2)} set for ${monthStr}.`
    });

    res.json(result[0]);
  } catch (error) {
    console.error("Error setting budget:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const setBulkBudgets = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const userId = scope.user_id;
    if (!userId && !req.user?.role) return res.status(401).json({ error: "Unauthorized" });

    const { budgets, apply_to_year, apply_to_upcoming_months, year } = req.body;
    let monthStr = req.body.month as string;

    if (!Array.isArray(budgets)) {
      return res.status(400).json({ error: "budgets array is required" });
    }

    if (!monthStr || !/^\d{4}-\d{2}$/.test(monthStr)) {
      const now = new Date();
      monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    }

    const [strYear, strMonth] = monthStr.split("-").map(Number);
    const targetYear = year ? Number(year) : strYear;

    // Settled month set
    const settledRecords = await db("monthly_savings").where({ user_id: userId }).select("month");
    const settledMonthSet = new Set(settledRecords.map(r => r.month));

    if (!apply_to_year && !apply_to_upcoming_months) {
      if (settledMonthSet.has(monthStr)) {
        return res.status(400).json({
          error: `Month ${monthStr} has already been settled and locked. Cannot modify budget.`
        });
      }
    }

    await db.transaction(async (trx) => {
      let monthDates: string[] = [];

      if (apply_to_year) {
        monthDates = Array.from({ length: 12 }, (_, i) => `${targetYear}-${String(i + 1).padStart(2, "0")}-01`);
      } else if (apply_to_upcoming_months) {
        monthDates = Array.from({ length: 12 - strMonth + 1 }, (_, i) => `${targetYear}-${String(strMonth + i).padStart(2, "0")}-01`);
      } else {
        monthDates = [`${monthStr}-01`];
      }

      for (const mDate of monthDates) {
        const mKey = mDate.substring(0, 7);
        if (settledMonthSet.has(mKey)) continue;

        for (const b of budgets) {
          const existing = await trx("budgets")
            .where({ user_id: userId, category_id: b.category_id, month: mDate })
            .first();

          if (existing) {
            await trx("budgets")
              .where({ id: existing.id })
              .update({ amount: Number(b.amount) });
          } else {
            await trx("budgets")
              .insert({ user_id: userId, category_id: b.category_id, amount: Number(b.amount), month: mDate });
          }
        }
      }

      await trx("notifications").insert({
        user_id: userId,
        type: "budget",
        title: "Bulk Budgets Updated",
        message: `Budgets successfully updated for ${monthDates.length} month(s).`
      });
    });

    res.json({
      success: true,
      message: apply_to_year
        ? `Bulk budgets set monthly for all months of ${targetYear}`
        : (apply_to_upcoming_months
          ? `Bulk budgets set for upcoming months of ${targetYear}`
          : `Bulk budgets set for ${monthStr}`)
    });
  } catch (error) {
    console.error("Error setting bulk budgets:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
