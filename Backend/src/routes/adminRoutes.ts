import { Router, Response } from "express";
import { authenticateToken, AuthRequest } from "../middleware/auth";
import { requireRole } from "../middleware/rbac";
import db from "../db/db";

const router = Router();

router.use(authenticateToken);
router.use(requireRole("ADMIN"));

router.get("/users", async (req: AuthRequest, res: Response) => {
  try {
    const users = await db("users")
      .select("id", "email", "mobile_number", "name", "role", "status", "avatar", "monthly_income", "currency", "created_at")
      .orderBy("created_at", "desc");
    res.json(users);
  } catch (error) {
    console.error("Admin fetch users error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

router.get("/dashboard", async (req: AuthRequest, res: Response) => {
  try {
    const selectedUserId = req.query.user_id as string;
    const isSpecificUser = selectedUserId && selectedUserId !== "all" && selectedUserId !== "";

    const today = new Date();
    const currentMonthStr = today.toISOString().slice(0, 7); // YYYY-MM
    const nextTwoWeeks = new Date();
    nextTwoWeeks.setDate(today.getDate() + 14);

    if (isSpecificUser) {
      // Fetch stats for specific user
      const targetUser = await db("users").where({ id: selectedUserId }).first();
      if (!targetUser) {
        return res.status(404).json({ error: "User not found" });
      }

      const monthlyIncome = Number(targetUser.monthly_income || 0);

      const userTxs = await db("transactions")
        .leftJoin("categories", "transactions.category_id", "categories.id")
        .where({ "transactions.user_id": selectedUserId })
        .whereNull("transactions.deleted_at")
        .whereRaw("to_char(date, 'YYYY-MM') = ?", [currentMonthStr])
        .select("transactions.*", "categories.name as category_name");

      let totalExpenses = 0;
      let extraIncome = 0;
      for (const tx of userTxs) {
        const amt = Number(tx.amount || 0);
        if (tx.type === "EXPENSE") totalExpenses += amt;
        else if (tx.type === "INCOME") extraIncome += amt;
      }

      const totalIncome = monthlyIncome + extraIncome;
      const balance = totalIncome - totalExpenses;

      const budgets = await db("budgets")
        .where({ user_id: selectedUserId })
        .whereNull("deleted_at")
        .distinctOn("category_id")
        .orderBy("category_id")
        .orderBy("month", "desc");

      let totalBudget = 0;
      for (const b of budgets) totalBudget += Number(b.amount || 0);

      const budgetUsedPercentage = totalBudget > 0 ? Math.min(100, Math.round((totalExpenses / totalBudget) * 100)) : 0;
      const remainingBudget = totalBudget - totalExpenses;

      const upcomingBills = await db("recurring_transactions")
        .where({ user_id: selectedUserId })
        .whereNull("deleted_at")
        .andWhere("next_due_date", "<=", nextTwoWeeks)
        .orderBy("next_due_date", "asc")
        .limit(5);

      return res.json({
        isAdmin: true,
        isConsolidated: false,
        selectedUser: {
          id: targetUser.id,
          name: targetUser.name,
          email: targetUser.email,
          avatar: targetUser.avatar
        },
        userName: targetUser.name,
        userEmail: targetUser.email,
        avatar: targetUser.avatar,
        currency: targetUser.currency || "INR",
        monthlyIncome,
        totalIncome,
        totalExpenses,
        balance,
        savings: balance,
        totalBudget,
        remainingBudget,
        budgetUsedPercentage,
        currentMonth: today.toLocaleString("default", { month: "long", year: "numeric" }),
        upcomingBills
      });
    }

    // Consolidated stats across all users
    const allUsers = await db("users").whereNull("deleted_at").select("id", "name", "email", "monthly_income");
    const totalUsersCount = allUsers.length;

    let baseIncomeSum = 0;
    for (const u of allUsers) {
      baseIncomeSum += Number(u.monthly_income || 0);
    }

    const allCurrentTxs = await db("transactions")
      .leftJoin("categories", "transactions.category_id", "categories.id")
      .leftJoin("users", "transactions.user_id", "users.id")
      .whereNull("transactions.deleted_at")
      .whereRaw("to_char(date, 'YYYY-MM') = ?", [currentMonthStr])
      .select("transactions.*", "categories.name as category_name", "users.name as user_name");

    let totalExpenses = 0;
    let extraIncome = 0;
    for (const tx of allCurrentTxs) {
      const amt = Number(tx.amount || 0);
      if (tx.type === "EXPENSE") totalExpenses += amt;
      else if (tx.type === "INCOME") extraIncome += amt;
    }

    const totalIncome = baseIncomeSum + extraIncome;
    const balance = totalIncome - totalExpenses;

    const allBudgets = await db("budgets")
      .whereNull("deleted_at")
      .distinctOn("user_id", "category_id")
      .orderBy(["user_id", "category_id"])
      .orderBy("month", "desc");

    let totalBudget = 0;
    for (const b of allBudgets) totalBudget += Number(b.amount || 0);

    const budgetUsedPercentage = totalBudget > 0 ? Math.min(100, Math.round((totalExpenses / totalBudget) * 100)) : 0;
    const remainingBudget = totalBudget - totalExpenses;

    const upcomingBills = await db("recurring_transactions")
      .leftJoin("users", "recurring_transactions.user_id", "users.id")
      .whereNull("recurring_transactions.deleted_at")
      .andWhere("next_due_date", "<=", nextTwoWeeks)
      .select("recurring_transactions.*", "users.name as user_name")
      .orderBy("next_due_date", "asc")
      .limit(6);

    res.json({
      isAdmin: true,
      isConsolidated: true,
      totalUsers: totalUsersCount,
      userName: "All Users (Consolidated)",
      userEmail: "admin@financy.app",
      currency: "INR",
      monthlyIncome: baseIncomeSum,
      totalIncome,
      totalExpenses,
      balance,
      savings: balance,
      totalBudget,
      remainingBudget,
      budgetUsedPercentage,
      currentMonth: today.toLocaleString("default", { month: "long", year: "numeric" }),
      upcomingBills
    });
  } catch (error) {
    console.error("Admin dashboard error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

export default router;
