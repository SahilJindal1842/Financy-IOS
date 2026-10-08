import { Response } from "express";
import { AuthRequest } from "../middleware/auth";
import db from "../db/db";
import { getQueryScope } from "../utils/rbacUtils";

export const getTopSpending = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const userId = scope.user_id;
    let monthStr = req.query.month as string;

    if (!monthStr || !/^\d{4}-\d{2}$/.test(monthStr)) {
      const now = new Date();
      monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    }

    const startDate = `${monthStr}-01`;
    const [year, month] = monthStr.split("-").map(Number);
    const nextMonth = month === 12 ? 1 : month + 1;
    const nextYear = month === 12 ? year + 1 : year;
    const endDate = `${nextYear}-${String(nextMonth).padStart(2, "0")}-01`;

    let query = db("transactions")
      .join("categories", "transactions.category_id", "categories.id")
      .andWhere("transactions.type", "EXPENSE")
      .andWhere("transactions.date", ">=", startDate)
      .andWhere("transactions.date", "<", endDate);

    if (userId !== undefined) {
      query = query.where("transactions.user_id", userId);
    }

    const expenses = await query
      .select("categories.id as category_id", "categories.name as category_name")
      .sum("transactions.amount as total_amount")
      .groupBy("categories.id")
      .orderBy("total_amount", "desc")
      .limit(5);

    const formattedExpenses = expenses.map(e => ({
      categoryId: String(e.category_id || ""),
      categoryName: e.category_name || "Unknown",
      totalSpent: Number(e.total_amount)
    }));

    res.json(formattedExpenses);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const getDailySpending = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const userId = scope.user_id;
    let monthStr = req.query.month as string;

    if (!monthStr || !/^\d{4}-\d{2}$/.test(monthStr)) {
      const now = new Date();
      monthStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    }

    const startDate = `${monthStr}-01`;
    const [year, month] = monthStr.split("-").map(Number);
    const nextMonth = month === 12 ? 1 : month + 1;
    const nextYear = month === 12 ? year + 1 : year;
    const endDate = `${nextYear}-${String(nextMonth).padStart(2, "0")}-01`;

    let query = db("transactions")
      .andWhere("type", "EXPENSE")
      .andWhere("date", ">=", startDate)
      .andWhere("date", "<", endDate);

    if (userId !== undefined) {
      query = query.where("user_id", userId);
    }

    const expenses = await query.select("date", "amount");

    const dailyTotals: Record<string, number> = {};

    for (const exp of expenses) {
      const dateStr = exp.date instanceof Date ? exp.date.toISOString().split("T")[0] : String(exp.date).split("T")[0];
      dailyTotals[dateStr] = (dailyTotals[dateStr] || 0) + Number(exp.amount);
    }

    const result = Object.entries(dailyTotals)
      .map(([date, totalSpent]) => ({ date, totalSpent }))
      .sort((a, b) => a.date.localeCompare(b.date));

    res.json(result);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const getMonthlyExpenseReport = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const userId = scope.user_id || (req.user?.role !== "ADMIN" ? req.user?.id : undefined);

    const requestedMonth = req.query.month as string;

    // Fetch all settled records from monthly_savings
    let query = db("monthly_savings")
      .leftJoin("users", "monthly_savings.user_id", "users.id")
      .select("monthly_savings.*", "users.name as user_name", "users.email as user_email")
      .orderBy("monthly_savings.month", "desc")
      .orderBy("monthly_savings.settled_at", "desc");

    if (userId) {
      query = query.where("monthly_savings.user_id", userId);
    }

    const settledMonths = await query;

    if (!requestedMonth) {
      // Return list of all settled months summary for reporting
      const summaryList = await Promise.all(
        settledMonths.map(async (record) => {
          const txCountRes = await db("transactions")
            .where({ user_id: record.user_id })
            .where(function () {
              this.where("settled_month", record.month)
                .orWhere(function() {
                  this.where("settled_for_reports", true)
                    .andWhereRaw("to_char(date, 'YYYY-MM') = ?", [record.month]);
                });
            })
            .whereNull("deleted_at")
            .count("id as count");

          const txCount = Number(txCountRes[0]?.count || 0);

          return {
            id: `${record.user_id}_${record.month}`,
            userId: record.user_id,
            userName: record.user_name || "User",
            userEmail: record.user_email || "",
            month: record.month,
            totalExpenses: Number(record.total_expenses),
            totalIncome: Number(record.total_income),
            totalBudget: Number(record.total_budget),
            savedAmount: Number(record.saved_amount),
            settledAt: record.settled_at,
            transactionCount: txCount,
            notes: record.notes
          };
        })
      );

      return res.json({
        settledMonths: summaryList,
        totalHistoricalSavings: summaryList.reduce((acc, curr) => acc + curr.savedAmount, 0),
        totalHistoricalExpenses: summaryList.reduce((acc, curr) => acc + curr.totalExpenses, 0)
      });
    }

    // Detailed report for a specific month
    const targetUserId = userId || (req.query.target_user_id as string) || settledMonths[0]?.user_id || req.user?.id;
    const settlement = settledMonths.find((m) => m.month === requestedMonth && (!targetUserId || m.user_id === targetUserId)) || settledMonths.find((m) => m.month === requestedMonth);
    const detailUserId = settlement?.user_id || targetUserId;
    const targetUser = detailUserId ? await db("users").where({ id: detailUserId }).first() : null;

    // Fetch transactions preserved with settled_for_reports = true or settled_month = requestedMonth
    const transactions = await db("transactions")
      .leftJoin("categories", "transactions.category_id", "categories.id")
      .where({ "transactions.user_id": detailUserId })
      .where(function () {
        this.where("transactions.settled_month", requestedMonth)
          .orWhere(function () {
            this.where("transactions.settled_for_reports", true)
              .andWhereRaw("to_char(transactions.date, 'YYYY-MM') = ?", [requestedMonth]);
          });
      })
      .whereNull("transactions.deleted_at")
      .select(
        "transactions.*",
        "categories.name as category_name",
        "categories.icon as category_icon",
        "categories.color as category_color"
      )
      .orderBy("transactions.date", "desc");

    // Group by category
    const categoryTotals: Record<string, { id: string; name: string; icon: string; color: string; amount: number }> = {};
    let totalExpenseAmount = 0;
    let totalIncomeAmount = 0;

    for (const t of transactions) {
      const amt = Number(t.amount || 0);
      if (t.type === "EXPENSE") {
        totalExpenseAmount += amt;
        const catId = t.category_id || "uncategorized";
        if (!categoryTotals[catId]) {
          categoryTotals[catId] = {
            id: catId,
            name: t.category_name || "General Expense",
            icon: t.category_icon || "tag.fill",
            color: t.category_color || "#6366F1",
            amount: 0
          };
        }
        categoryTotals[catId].amount += amt;
      } else if (t.type === "INCOME") {
        totalIncomeAmount += amt;
      }
    }

    const categoryBreakdown = Object.values(categoryTotals)
      .map((c) => ({
        ...c,
        percentage: totalExpenseAmount > 0 ? (c.amount / totalExpenseAmount) * 100 : 0
      }))
      .sort((a, b) => b.amount - a.amount);

    const formattedTxs = transactions.map((t) => ({
      id: t.id,
      amount: t.type === "EXPENSE" ? -Math.abs(Number(t.amount)) : Math.abs(Number(t.amount)),
      type: (t.type || "EXPENSE").toLowerCase(),
      date: t.date,
      note: t.notes || t.description,
      merchant: t.description || t.category_name || "Expense",
      categoryName: t.category_name || "General",
      categoryIcon: t.category_icon || "tag.fill",
      categoryColor: t.category_color || "#6366F1",
      settledForReports: !!t.settled_for_reports,
      settledMonth: t.settled_month
    }));

    res.json({
      month: requestedMonth,
      userId: detailUserId,
      userName: targetUser?.name || settlement?.user_name || "User",
      userEmail: targetUser?.email || settlement?.user_email || "",
      isSettled: !!settlement,
      settlementRecord: settlement
        ? {
            id: settlement.id,
            userId: settlement.user_id,
            userName: targetUser?.name || settlement.user_name || "User",
            userEmail: targetUser?.email || settlement.user_email || "",
            month: settlement.month,
            savedAmount: Number(settlement.saved_amount || 0),
            totalBudget: Number(settlement.total_budget || 0),
            totalExpenses: Number(settlement.total_expenses || 0),
            totalIncome: Number(settlement.total_income || 0),
            settledAt: settlement.settled_at,
            notes: settlement.notes
          }
        : null,
      totalExpenses: settlement ? Number(settlement.total_expenses) : totalExpenseAmount,
      totalIncome: settlement ? Number(settlement.total_income) : totalIncomeAmount,
      totalBudget: settlement ? Number(settlement.total_budget) : 0,
      savedAmount: settlement ? Number(settlement.saved_amount) : 0,
      settledAt: settlement?.settled_at || null,
      categoryBreakdown,
      transactions: formattedTxs
    });
  } catch (error) {
    console.error("Error generating monthly expense report:", error);
    res.status(500).json({ error: "Failed to generate monthly expense report" });
  }
};
