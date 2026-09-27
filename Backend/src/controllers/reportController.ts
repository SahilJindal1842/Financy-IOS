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
