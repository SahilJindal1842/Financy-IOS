import { Response } from "express";
import { AuthRequest } from "../middleware/auth";
import db from "../db/db";

export const getProfile = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const user = await db("users")
      .where({ id: userId })
      .select("id", "name", "email", "mobile_number", "role", "monthly_income", "currency", "primary_goal", "created_at")
      .first();

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({
      user: {
        ...user,
        monthly_income: Number(user.monthly_income || 0)
      }
    });
  } catch (error) {
    console.error("Error fetching profile:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const updateProfile = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const { monthlyIncome, monthly_income, currency, primaryGoal, primary_goal, name } = req.body;

    const incomeVal = monthlyIncome !== undefined ? monthlyIncome : monthly_income;
    const goalVal = primaryGoal !== undefined ? primaryGoal : primary_goal;

    const updateData: Record<string, any> = {};

    if (incomeVal !== undefined) {
      const parsedIncome = parseFloat(String(incomeVal).replace(/[^0-9.]/g, ""));
      updateData.monthly_income = isNaN(parsedIncome) ? 0.0 : parsedIncome;
    }

    if (currency !== undefined) {
      updateData.currency = currency;
    }

    if (goalVal !== undefined) {
      updateData.primary_goal = goalVal;
    }

    if (name !== undefined) {
      updateData.name = name;
    }

    if (Object.keys(updateData).length > 0) {
      await db("users").where({ id: userId }).update(updateData);
    }

    // Ensure user has at least one account in accounts table
    const existingAccount = await db("accounts").where({ user_id: userId }).first();
    if (!existingAccount) {
      await db("accounts").insert({
        user_id: userId,
        name: "Primary Account",
        type: "cash",
        currency_code: currency || "INR"
      });
    }

    const updatedUser = await db("users")
      .where({ id: userId })
      .select("id", "name", "email", "mobile_number", "role", "monthly_income", "currency", "primary_goal")
      .first();

    res.json({
      message: "Profile updated successfully",
      user: {
        ...updatedUser,
        monthly_income: Number(updatedUser?.monthly_income || 0)
      }
    });
  } catch (error) {
    console.error("Error updating profile:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const getDashboardStats = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // 1. Fetch user profile
    const user = await db("users")
      .where({ id: userId })
      .select("id", "name", "email", "monthly_income", "currency")
      .first();

    const monthlyIncome = Number(user?.monthly_income || 0);

    // 2. Fetch all user transactions strictly filtered by user_id
    const userTransactions = await db("transactions")
      .leftJoin("categories", "transactions.category_id", "categories.id")
      .where({ "transactions.user_id": userId })
      .select(
        "transactions.*",
        "categories.name as category_name"
      )
      .orderBy("transactions.date", "desc")
      .orderBy("transactions.created_at", "desc");

    let totalExpenses = 0;
    let extraIncome = 0;

    for (const tx of userTransactions) {
      const amt = Number(tx.amount || 0);
      if (tx.type === "EXPENSE") {
        totalExpenses += amt;
      } else if (tx.type === "INCOME") {
        extraIncome += amt;
      }
    }

    const totalIncome = monthlyIncome + extraIncome;
    const balance = totalIncome - totalExpenses;
    const savings = Math.max(0, balance);

    // 3. User's monthly budget (if created)
    const userBudgets = await db("budgets").where({ user_id: userId });
    const totalBudgetSet = userBudgets.reduce((acc, b) => acc + Number(b.amount || 0), 0);

    const formattedRecent = userTransactions.slice(0, 10).map((t) => ({
      id: t.id,
      accountId: t.account_id,
      categoryId: t.category_name || t.category_id,
      amount: t.type === "EXPENSE" ? -Math.abs(Number(t.amount)) : Math.abs(Number(t.amount)),
      type: (t.type || "EXPENSE").toLowerCase(),
      date: t.date,
      note: t.notes || t.description,
      merchant: t.description || t.category_name || "Expense",
      destinationAccountId: t.destination_account_id,
      createdAt: t.created_at,
      updatedAt: t.updated_at
    }));

    res.json({
      userName: user?.name || "User",
      currency: user?.currency || "INR",
      monthlyIncome,
      totalIncome,
      totalExpenses,
      totalSpent: totalExpenses,
      balance,
      savings,
      budget: totalBudgetSet > 0 ? totalBudgetSet : monthlyIncome,
      transactionsCount: userTransactions.length,
      recentTransactions: formattedRecent
    });
  } catch (error) {
    console.error("Error fetching dashboard stats:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
