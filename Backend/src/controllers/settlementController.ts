import { Response } from "express";
import db from "../db/db";
import { AuthRequest } from "../middleware/auth";
import { getQueryScope } from "../utils/rbacUtils";

export const getSettlementStatus = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const userId = scope.user_id || req.user?.id;
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const now = new Date();
    let monthStr = req.query.month as string;
    if (!monthStr || !/^\d{4}-\d{2}$/.test(monthStr)) {
      monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    }

    const [year, month] = monthStr.split("-").map(Number);
    const startDate = `${monthStr}-01`;
    const lastDayOfMonth = new Date(year, month, 0).getDate();
    const endOfMonthDateStr = `${year}-${String(month).padStart(2, "0")}-${String(lastDayOfMonth).padStart(2, "0")}`;

    // End of month check: either day >= 25 of this month, or looking at a past month
    const isPastMonth = (now.getFullYear() > year) || (now.getFullYear() === year && (now.getMonth() + 1) > month);
    const isCurrentMonth = (now.getFullYear() === year && (now.getMonth() + 1) === month);
    const isEndOfMonth = isPastMonth || (isCurrentMonth && now.getDate() >= 25);

    // Check if already settled
    const existingSettlement = await db("monthly_savings")
      .where({ user_id: userId, month: monthStr })
      .first();

    // Fetch user profile for monthly income
    const user = await db("users").where({ id: userId }).first();
    const monthlyIncome = Number(user?.monthly_income || 0);

    // Fetch active budgets for this month
    const budgets = await db("budgets")
      .where({ user_id: userId, month: startDate })
      .whereNull("deleted_at");

    const totalBudget = budgets.reduce((sum, b) => sum + Number(b.amount || 0), 0);

    // Fetch active (non-settled) transactions for this month
    const transactions = await db("transactions")
      .where({ user_id: userId })
      .whereRaw("to_char(date, 'YYYY-MM') = ?", [monthStr])
      .where(function() {
        this.whereNull("is_settled").orWhere("is_settled", false);
      })
      .whereNull("deleted_at");

    let totalExpenses = 0;
    let extraIncome = 0;

    for (const t of transactions) {
      const amt = Number(t.amount || 0);
      if (t.type === "EXPENSE") {
        totalExpenses += amt;
      } else if (t.type === "INCOME") {
        extraIncome += amt;
      }
    }

    const totalIncome = monthlyIncome + extraIncome;
    const availableMoney = Math.max(0, totalIncome - totalExpenses);
    const remainingBudget = Math.max(0, totalBudget - totalExpenses);
    const actualSurplus = availableMoney;

    // Total accumulated savings across all settled months
    const allSavings = await db("monthly_savings")
      .where({ user_id: userId })
      .sum("saved_amount as total");
    const totalAccumulatedSavings = Number(allSavings[0]?.total || 0);

    res.json({
      month: monthStr,
      endOfMonthDate: endOfMonthDateStr,
      isEndOfMonth,
      isSettled: !!existingSettlement,
      settlementRecord: existingSettlement || null,
      totalBudget: existingSettlement ? Number(existingSettlement.total_budget) : totalBudget,
      remainingBudget: existingSettlement ? Math.max(0, Number(existingSettlement.total_budget) - Number(existingSettlement.total_expenses)) : remainingBudget,
      totalExpenses: existingSettlement ? Number(existingSettlement.total_expenses) : totalExpenses,
      totalIncome: existingSettlement ? Number(existingSettlement.total_income) : totalIncome,
      availableMoney: existingSettlement ? 0 : availableMoney,
      balance: existingSettlement ? 0 : availableMoney,
      leftoverSavings: existingSettlement ? Number(existingSettlement.saved_amount) : actualSurplus,
      savedAmount: existingSettlement ? Number(existingSettlement.saved_amount) : actualSurplus,
      totalAccumulatedSavings
    });
  } catch (error) {
    console.error("Error fetching settlement status:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const settleMonth = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const userId = req.body?.user_id || scope.user_id || req.user?.id;
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const now = new Date();
    let monthStr = req.body.month as string;
    if (!monthStr || !/^\d{4}-\d{2}$/.test(monthStr)) {
      monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    }

    const startDate = `${monthStr}-01`;

    // Verify not already settled
    const existing = await db("monthly_savings")
      .where({ user_id: userId, month: monthStr })
      .first();

    if (existing) {
      return res.status(400).json({ error: `Month ${monthStr} has already been settled.` });
    }

    // Fetch user profile
    const user = await db("users").where({ id: userId }).first();
    const monthlyIncome = Number(user?.monthly_income || 0);

    // Fetch budgets for this month
    const budgets = await db("budgets")
      .where({ user_id: userId, month: startDate })
      .whereNull("deleted_at");

    const totalBudget = budgets.reduce((sum, b) => sum + Number(b.amount || 0), 0);

    // Fetch active transactions for this month
    const transactions = await db("transactions")
      .where({ user_id: userId })
      .whereRaw("to_char(date, 'YYYY-MM') = ?", [monthStr])
      .where(function() {
        this.whereNull("is_settled").orWhere("is_settled", false);
      })
      .whereNull("deleted_at");

    let totalExpenses = 0;
    let extraIncome = 0;

    for (const t of transactions) {
      const amt = Number(t.amount || 0);
      if (t.type === "EXPENSE") {
        totalExpenses += amt;
      } else if (t.type === "INCOME") {
        extraIncome += amt;
      }
    }

    const totalIncome = monthlyIncome + extraIncome;
    // Correct financial logic:
    // Closing/settling a month must use actual income and actual transactions.
    // Do NOT treat unused budget as money received.
    // Do NOT add budget amounts to user's balance.
    // Unspent earnings from income = max(0, totalIncome - totalExpenses)
    const actualSurplus = Math.max(0, totalIncome - totalExpenses);

    // Execute atomic settlement
    await db.transaction(async (trx) => {
      // 1. Insert into monthly_savings
      await trx("monthly_savings").insert({
        user_id: userId,
        month: monthStr,
        saved_amount: actualSurplus,
        total_budget: totalBudget, // Preserve budget limit record
        total_expenses: totalExpenses,
        total_income: totalIncome,
        settled_at: new Date(),
        notes: req.body.notes || `Month-end financial settlement for ${monthStr}`
      });

      // 2. Mark transactions of this month as settled and flagged for reports
      await trx("transactions")
        .where({ user_id: userId })
        .where(function() {
          this.whereRaw("to_char(date, 'YYYY-MM') = ?", [monthStr])
            .orWhere("settled_month", monthStr);
        })
        .update({
          is_settled: true,
          settled_month: monthStr,
          settled_for_reports: true
        });

      // 3. PRESERVE category budgets!
      // Budgets are planning/limit records and must NOT be zeroed out or deleted.
      // (Do NOT update budgets to 0)

      // 4. Update user's last_settled_month
      await trx("users")
        .where({ id: userId })
        .update({
          last_settled_month: monthStr
        });

      // 5. Insert activity notification
      await trx("notifications").insert({
        user_id: userId,
        type: "settlement",
        title: "Month Settled & Surplus Saved",
        message: `Month ${monthStr} successfully settled. ₹${actualSurplus.toFixed(2)} unspent earnings transferred to savings reserve.`
      });

      // 6. Update or create a Savings Goal to reflect this transferred surplus
      if (actualSurplus > 0) {
        let goal = await trx("savings_goals")
          .where({ user_id: userId, name: "Monthly Savings Reserve" })
          .first();

        if (goal) {
          await trx("savings_goals")
            .where({ id: goal.id })
            .update({
              current_amount: Number(goal.current_amount || 0) + actualSurplus,
              updated_at: new Date()
            });
        } else {
          await trx("savings_goals").insert({
            user_id: userId,
            name: "Monthly Savings Reserve",
            target_amount: Math.max(actualSurplus * 6, 100000), // 6-month target
            current_amount: actualSurplus
          });
        }
      }
      // CRITICAL: DO NOT TOUCH recurring_transactions (preserved completely)
    });

    res.json({
      success: true,
      message: `Month ${monthStr} successfully settled. ₹${actualSurplus} unspent earnings transferred to Savings.`,
      savedAmount: actualSurplus,
      totalBudget,
      totalExpenses,
      totalIncome,
      availableMoney: 0,
      month: monthStr
    });
  } catch (error) {
    console.error("Error settling month:", error);
    res.status(500).json({ error: "Failed to settle month" });
  }
};

export const getSavingsHistory = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const query = db("monthly_savings")
      .leftJoin("users", "monthly_savings.user_id", "users.id")
      .select(
        "monthly_savings.*",
        "users.name as user_name",
        "users.email as user_email"
      )
      .orderBy("monthly_savings.month", "desc")
      .orderBy("monthly_savings.settled_at", "desc");

    if (scope.user_id) {
      query.where("monthly_savings.user_id", scope.user_id);
    }

    const history = await query;
    const totalAccumulated = history.reduce((sum, h) => sum + Number(h.saved_amount || 0), 0);

    const formatted = history.map(h => ({
      id: h.id,
      userId: h.user_id,
      user_id: h.user_id,
      userName: h.user_name || "User",
      user_name: h.user_name || "User",
      userEmail: h.user_email || "",
      user_email: h.user_email || "",
      month: h.month,
      savedAmount: Number(h.saved_amount),
      saved_amount: Number(h.saved_amount),
      totalBudget: Number(h.total_budget),
      total_budget: Number(h.total_budget),
      totalExpenses: Number(h.total_expenses),
      total_expenses: Number(h.total_expenses),
      totalIncome: Number(h.total_income),
      total_income: Number(h.total_income),
      settledAt: h.settled_at,
      settled_at: h.settled_at,
      notes: h.notes
    }));

    res.json({
      totalAccumulatedSavings: totalAccumulated,
      total_accumulated_savings: totalAccumulated,
      history: formatted
    });
  } catch (error) {
    console.error("Error fetching savings history:", error);
    res.status(500).json({ error: "Failed to fetch savings history" });
  }
};
