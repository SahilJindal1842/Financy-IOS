import { Router, Response } from "express";
import bcrypt from "bcrypt";
import { authenticateToken, AuthRequest } from "../middleware/auth";
import { requireRole } from "../middleware/rbac";
import db from "../db/db";

const router = Router();

router.use(authenticateToken);
router.use(requireRole("ADMIN"));

router.get("/users", async (req: AuthRequest, res: Response) => {
  try {
    const users = await db("users")
      .select("id", "email", "mobile_number", "name", "role", "status", "avatar", "monthly_income", "currency", "created_at", "deleted_at")
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
    const requestedMonth = typeof req.query.month === "string" && /^\d{4}-\d{2}$/.test(req.query.month)
      ? req.query.month
      : today.toISOString().slice(0, 7); // YYYY-MM
    const currentMonthStr = requestedMonth;
    
    const [year, monthNum] = currentMonthStr.split("-").map(Number);
    const lastDayOfMonth = new Date(year, monthNum, 0).getDate();
    const endOfMonthDateStr = `${year}-${String(monthNum).padStart(2, "0")}-${String(lastDayOfMonth).padStart(2, "0")}`;
    const isEndOfMonth = (today.getFullYear() > year) || (today.getFullYear() === year && (today.getMonth() + 1) > monthNum) || (today.getFullYear() === year && (today.getMonth() + 1) === monthNum && today.getDate() >= 25);

    const nextTwoWeeks = new Date();
    nextTwoWeeks.setDate(today.getDate() + 14);

    if (isSpecificUser) {
      // Fetch stats for specific user
      const targetUser = await db("users").where({ id: selectedUserId }).first();
      if (!targetUser) {
        return res.status(404).json({ error: "User not found" });
      }

      const monthlyIncome = Number(targetUser.monthly_income || 0);

      // Check if month is settled from monthly_savings
      const settlement = await db("monthly_savings")
        .where({ user_id: selectedUserId, month: currentMonthStr })
        .first();
      const isSettled = !!settlement;

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

      if (settlement && Number(settlement.total_expenses || 0) > totalExpenses) {
        totalExpenses = Number(settlement.total_expenses);
      }

      // Total income calculation:
      // Base income is monthlyIncome (e.g. ₹20,000) + any extra income transactions.
      // If month is settled, settlement.total_income contains total income (monthlyIncome + extraIncome).
      // Do NOT set extraIncome = settlement.total_income as that doubles monthlyIncome!
      let totalIncome = monthlyIncome + extraIncome;
      if (settlement && Number(settlement.total_income || 0) > 0) {
        totalIncome = Math.max(Number(settlement.total_income), monthlyIncome + extraIncome);
      }

      const actualSpent = totalExpenses;
      const availableMoney = isSettled ? 0 : Math.max(0, totalIncome - actualSpent);
      const balance = availableMoney;

      // Accumulated monthly savings
      const allMonthlySavings = await db("monthly_savings")
        .where({ user_id: selectedUserId })
        .sum("saved_amount as total");
      const accumulatedSavings = Number(allMonthlySavings[0]?.total || 0);
      const savings = accumulatedSavings + (isSettled ? 0 : availableMoney);

      // Budgets
      let totalBudget = 0;
      if (settlement && Number(settlement.total_budget || 0) > 0) {
        totalBudget = Number(settlement.total_budget);
      } else {
        const currentMonthBudgets = await db("budgets")
          .where({ user_id: selectedUserId, month: `${currentMonthStr}-01` })
          .whereNull("deleted_at");

        for (const b of currentMonthBudgets) {
          totalBudget += Number(b.amount || 0);
        }

        if (totalBudget === 0) {
          const fallbackBudgets = await db("budgets")
            .where({ user_id: selectedUserId })
            .whereNull("deleted_at")
            .distinctOn("category_id")
            .orderBy("category_id")
            .orderBy("month", "desc");
          for (const b of fallbackBudgets) {
            totalBudget += Number(b.amount || 0);
          }
        }
      }

      const budgetUsedPercentage = totalBudget > 0 ? Math.min(100, Math.round((actualSpent / totalBudget) * 100)) : 0;
      const remainingBudget = Math.max(0, totalBudget - actualSpent);
      const unspentIncomeToSave = settlement 
        ? Number(settlement.saved_amount || 0) 
        : Math.max(0, totalIncome - actualSpent);

      const upcomingBills = await db("recurring_transactions")
        .where({ user_id: selectedUserId, status: "active" })
        .whereNull("deleted_at")
        .andWhere("next_due_date", "<=", nextTwoWeeks)
        .orderBy("next_due_date", "asc")
        .limit(10);

      const formattedTransactions = userTxs.slice(0, 5).map(t => ({
        id: t.id,
        accountId: t.account_id,
        categoryId: t.category_id,
        amount: t.type === "EXPENSE" ? -Math.abs(Number(t.amount)) : Math.abs(Number(t.amount)),
        type: (t.type || "EXPENSE").toLowerCase(),
        date: t.date,
        note: t.notes || t.description,
        merchant: t.description || t.category_name || "Expense"
      }));

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
        totalExpenses: actualSpent,
        balance,
        availableMoney,
        savings,
        budget: totalBudget,
        totalBudget,
        remainingBudget,
        budgetUsedPercentage,
        isSettled,
        isEndOfMonth,
        endOfMonthDate: endOfMonthDateStr,
        settlementMonth: currentMonthStr,
        leftoverSavings: unspentIncomeToSave,
        totalAccumulatedSavings: accumulatedSavings,
        transactions: formattedTransactions,
        upcomingBills: upcomingBills.map(b => ({
          id: b.id,
          merchant: b.merchant || "Bill",
          amount: Number(b.amount || 0),
          nextDueDate: b.next_due_date,
          frequency: b.frequency,
          type: b.type,
          userName: targetUser.name
        }))
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
      .select("transactions.*", "categories.name as category_name", "users.name as user_name", "users.email as user_email");

    let totalExpenses = 0;
    let extraIncome = 0;
    for (const tx of allCurrentTxs) {
      const amt = Number(tx.amount || 0);
      if (tx.type === "EXPENSE") totalExpenses += amt;
      else if (tx.type === "INCOME") extraIncome += amt;
    }

    const totalIncome = baseIncomeSum + extraIncome;
    const balance = Math.max(0, totalIncome - totalExpenses);

    const allBudgets = await db("budgets")
      .whereNull("deleted_at")
      .distinctOn("user_id", "category_id")
      .orderBy(["user_id", "category_id"])
      .orderBy("month", "desc");

    let totalBudget = 0;
    for (const b of allBudgets) totalBudget += Number(b.amount || 0);

    const budgetUsedPercentage = totalBudget > 0 ? Math.min(100, Math.round((totalExpenses / totalBudget) * 100)) : 0;
    const remainingBudget = Math.max(0, totalBudget - totalExpenses);

    const allMonthlySavings = await db("monthly_savings").sum("saved_amount as total");
    const totalAccumulatedSavings = Number(allMonthlySavings[0]?.total || 0);

    const upcomingBills = await db("recurring_transactions")
      .leftJoin("users", "recurring_transactions.user_id", "users.id")
      .whereNull("recurring_transactions.deleted_at")
      .andWhere("next_due_date", "<=", nextTwoWeeks)
      .select("recurring_transactions.*", "users.name as user_name", "users.email as user_email")
      .orderBy("next_due_date", "asc")
      .limit(10);

    const formattedTransactions = allCurrentTxs.slice(0, 10).map(t => ({
      id: t.id,
      accountId: t.account_id,
      categoryId: t.category_id,
      amount: t.type === "EXPENSE" ? -Math.abs(Number(t.amount)) : Math.abs(Number(t.amount)),
      type: (t.type || "EXPENSE").toLowerCase(),
      date: t.date,
      note: t.notes || t.description,
      merchant: `${t.user_name ? "[" + t.user_name + "] " : ""}${t.description || t.category_name || "Expense"}`
    }));

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
      availableMoney: balance,
      savings: totalAccumulatedSavings + balance,
      budget: totalBudget,
      totalBudget,
      remainingBudget,
      budgetUsedPercentage,
      isSettled: false,
      isEndOfMonth,
      endOfMonthDate: endOfMonthDateStr,
      settlementMonth: currentMonthStr,
      leftoverSavings: Math.max(0, totalIncome - totalExpenses),
      totalAccumulatedSavings,
      transactions: formattedTransactions,
      upcomingBills: upcomingBills.map(b => ({
        id: b.id,
        merchant: b.merchant || "Bill",
        amount: Number(b.amount || 0),
        nextDueDate: b.next_due_date,
        frequency: b.frequency,
        type: b.type,
        userName: (b as any).user_name || undefined
      }))
    });
  } catch (error) {
    console.error("Admin dashboard error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: Create User
router.post("/users", async (req: AuthRequest, res: Response) => {
  try {
    const { name, email, password, role = "USER", status = "ACTIVE", monthly_income = 0, currency = "INR", mobile_number } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: "Name, email and password are required" });
    }

    const existing = await db("users").where({ email }).first();
    if (existing) {
      return res.status(400).json({ error: "A user with this email already exists" });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const [newUser] = await db("users").insert({
      name,
      email,
      password_hash,
      role,
      status,
      monthly_income: Number(monthly_income) || 0,
      currency,
      mobile_number: mobile_number || null,
      email_verified: true
    }).returning(["id", "name", "email", "mobile_number", "role", "status", "monthly_income", "currency", "created_at"]);

    res.status(201).json(newUser);
  } catch (error) {
    console.error("Admin create user error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: Get Single User Details
router.get("/users/:id", async (req: AuthRequest, res: Response) => {
  try {
    const user = await db("users")
      .where({ id: req.params.id })
      .select("id", "name", "email", "mobile_number", "role", "status", "avatar", "monthly_income", "currency", "created_at", "updated_at")
      .first();

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const txCount = await db("transactions")
      .where({ user_id: user.id })
      .whereNull("deleted_at")
      .count("id as count")
      .first();

    const { month, start_date, end_date } = req.query;

    let txQuery = db("transactions")
      .leftJoin("categories", "transactions.category_id", "categories.id")
      .where({ "transactions.user_id": user.id })
      .whereNull("transactions.deleted_at")
      .select("transactions.*", "categories.name as category_name")
      .orderBy("transactions.date", "desc");

    if (month && /^\d{4}-\d{2}$/.test(month as string)) {
      txQuery = txQuery.whereRaw("to_char(transactions.date, 'YYYY-MM') = ?", [month as string]);
    }
    if (start_date) {
      txQuery = txQuery.where("transactions.date", ">=", start_date as string);
    }
    if (end_date) {
      txQuery = txQuery.where("transactions.date", "<=", end_date as string);
    }

    const recentTxs = await txQuery.limit(100);

    const budgets = await db("budgets")
      .leftJoin("categories", "budgets.category_id", "categories.id")
      .where({ "budgets.user_id": user.id })
      .whereNull("budgets.deleted_at")
      .select("budgets.*", "categories.name as category_name", "categories.icon as category_icon");

    const recurring = await db("recurring_transactions")
      .leftJoin("categories", "recurring_transactions.category_id", "categories.id")
      .where({ "recurring_transactions.user_id": user.id })
      .whereNull("recurring_transactions.deleted_at")
      .select("recurring_transactions.*", "categories.name as category_name")
      .orderBy("next_due_date", "asc");

    const accounts = await db("accounts")
      .where({ user_id: user.id })
      .whereNull("deleted_at");

    res.json({
      user,
      transactionCount: Number(txCount?.count || 0),
      recentTransactions: recentTxs,
      budgets,
      recurring,
      accounts
    });
  } catch (error) {
    console.error("Admin get user details error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: Update User
router.put("/users/:id", async (req: AuthRequest, res: Response) => {
  try {
    const { name, email, mobile_number, role, status, monthly_income, currency } = req.body;
    const updateData: any = {};
    if (name !== undefined) updateData.name = name;
    if (email !== undefined) updateData.email = email;
    if (mobile_number !== undefined) updateData.mobile_number = mobile_number;
    if (role !== undefined) updateData.role = role;
    if (status !== undefined) updateData.status = status;
    if (monthly_income !== undefined) updateData.monthly_income = Number(monthly_income) || 0;
    if (currency !== undefined) updateData.currency = currency;
    updateData.updated_at = new Date();

    const [updatedUser] = await db("users")
      .where({ id: req.params.id })
      .update(updateData)
      .returning(["id", "name", "email", "mobile_number", "role", "status", "avatar", "monthly_income", "currency", "updated_at"]);

    if (!updatedUser) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json(updatedUser);
  } catch (error) {
    console.error("Admin update user error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: Reset User Password
router.post("/users/:id/reset-password", async (req: AuthRequest, res: Response) => {
  try {
    const { newPassword } = req.body;
    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({ error: "Password must be at least 6 characters" });
    }

    const password_hash = await bcrypt.hash(newPassword, 10);
    const count = await db("users").where({ id: req.params.id }).update({
      password_hash,
      updated_at: new Date()
    });

    if (!count) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({ message: "Password updated successfully" });
  } catch (error) {
    console.error("Admin reset password error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: Delete User (Soft Delete or Permanent Hard Delete)
router.delete("/users/:id", async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.params.id;
    const isPermanent = req.query.permanent === "true" || req.query.hard === "true" || (req.body && req.body.permanent === true);

    // Prevent admin from deleting themselves
    if (req.user && req.user.id === userId) {
      return res.status(400).json({ error: "Cannot delete your own admin account while logged in" });
    }

    const existingUser = await db("users").where({ id: userId }).first();
    if (!existingUser) {
      return res.status(404).json({ error: "User not found" });
    }

    if (isPermanent) {
      // FULL PERMANENT PURGE FROM THE SYSTEM
      await db.transaction(async (trx) => {
        // Delete all child data explicitly to ensure complete purge
        await trx("transactions").where({ user_id: userId }).del();
        await trx("recurring_transactions").where({ user_id: userId }).del();
        await trx("budgets").where({ user_id: userId }).del();
        await trx("savings_goals").where({ user_id: userId }).del();
        await trx("monthly_savings").where({ user_id: userId }).del();
        await trx("categories").where({ user_id: userId }).del();
        await trx("accounts").where({ user_id: userId }).del();
        await trx("notifications").where({ user_id: userId }).del();
        await trx("otps").where({ user_id: userId }).del();
        await trx("user_identities").where({ user_id: userId }).del();
        await trx("user_purchases").where({ user_id: userId }).del();
        await trx("user_trials").where({ user_id: userId }).del();

        // Finally delete the user completely
        await trx("users").where({ id: userId }).del();
      });

      return res.json({
        message: `User ${existingUser.name || existingUser.email} has been completely deleted from the system`,
        permanent: true,
        id: userId
      });
    }

    // Default Soft Delete / Disable
    const count = await db("users").where({ id: userId }).update({
      deleted_at: new Date(),
      status: "DISABLED"
    });

    if (!count) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({ message: "User disabled successfully", permanent: false, id: userId });
  } catch (error) {
    console.error("Admin delete user error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: Dedicated Permanent Delete Route
router.delete("/users/:id/permanent", async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.params.id;

    if (req.user && req.user.id === userId) {
      return res.status(400).json({ error: "Cannot delete your own admin account while logged in" });
    }

    const existingUser = await db("users").where({ id: userId }).first();
    if (!existingUser) {
      return res.status(404).json({ error: "User not found" });
    }

    await db.transaction(async (trx) => {
      await trx("transactions").where({ user_id: userId }).del();
      await trx("recurring_transactions").where({ user_id: userId }).del();
      await trx("budgets").where({ user_id: userId }).del();
      await trx("savings_goals").where({ user_id: userId }).del();
      await trx("monthly_savings").where({ user_id: userId }).del();
      await trx("categories").where({ user_id: userId }).del();
      await trx("accounts").where({ user_id: userId }).del();
      await trx("notifications").where({ user_id: userId }).del();
      await trx("otps").where({ user_id: userId }).del();
      await trx("user_identities").where({ user_id: userId }).del();
      await trx("user_purchases").where({ user_id: userId }).del();
      await trx("user_trials").where({ user_id: userId }).del();

      await trx("users").where({ id: userId }).del();
    });

    res.json({
      message: `User ${existingUser.name || existingUser.email} has been completely deleted from the system`,
      permanent: true,
      id: userId
    });
  } catch (error) {
    console.error("Admin permanent delete user error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: List All Transactions
router.get("/transactions", async (req: AuthRequest, res: Response) => {
  try {
    const { user_id, category_id, type, search, month, start_date, end_date, date, limit = "200", offset = "0" } = req.query;

    let query = db("transactions")
      .leftJoin("users", "transactions.user_id", "users.id")
      .leftJoin("categories", "transactions.category_id", "categories.id")
      .whereNull("transactions.deleted_at")
      .select(
        "transactions.*",
        "users.name as user_name",
        "users.email as user_email",
        "categories.name as category_name",
        "categories.icon as category_icon"
      )
      .orderBy("transactions.date", "desc")
      .limit(Number(limit))
      .offset(Number(offset));

    if (user_id && user_id !== "all") {
      query = query.where({ "transactions.user_id": user_id as string });
    }
    if (category_id && category_id !== "all") {
      query = query.where({ "transactions.category_id": category_id as string });
    }
    if (type && type !== "all") {
      query = query.where({ "transactions.type": (type as string).toUpperCase() });
    }
    if (month && /^\d{4}-\d{2}$/.test(month as string)) {
      query = query.whereRaw("to_char(transactions.date, 'YYYY-MM') = ?", [month as string]);
    }
    if (date) {
      query = query.whereRaw("to_char(transactions.date, 'YYYY-MM-DD') = ?", [date as string]);
    }
    if (start_date) {
      query = query.where("transactions.date", ">=", start_date as string);
    }
    if (end_date) {
      query = query.where("transactions.date", "<=", end_date as string);
    }
    if (search) {
      const term = `%${search}%`;
      query = query.andWhere((builder) => {
        builder.whereILike("transactions.description", term)
          .orWhereILike("transactions.notes", term)
          .orWhereILike("users.name", term)
          .orWhereILike("users.email", term);
      });
    }

    const txs = await query;
    res.json(txs);
  } catch (error) {
    console.error("Admin list transactions error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: Delete Transaction
router.delete("/transactions/:id", async (req: AuthRequest, res: Response) => {
  try {
    const count = await db("transactions").where({ id: req.params.id }).update({
      deleted_at: new Date()
    });
    if (!count) return res.status(404).json({ error: "Transaction not found" });
    res.json({ message: "Transaction deleted successfully" });
  } catch (error) {
    console.error("Admin delete transaction error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: List All Budgets with Real-time Spending
router.get("/budgets", async (req: AuthRequest, res: Response) => {
  try {
    const { user_id, category_id, month } = req.query;
    let query = db("budgets")
      .leftJoin("users", "budgets.user_id", "users.id")
      .leftJoin("categories", "budgets.category_id", "categories.id")
      .whereNull("budgets.deleted_at")
      .select(
        "budgets.*",
        "users.name as user_name",
        "users.email as user_email",
        "categories.name as category_name",
        "categories.icon as category_icon"
      )
      .orderBy("budgets.created_at", "desc");

    if (user_id && user_id !== "all") {
      query = query.where({ "budgets.user_id": user_id as string });
    }
    if (category_id && category_id !== "all") {
      query = query.where({ "budgets.category_id": category_id as string });
    }
    if (month) {
      const mStr = (month as string).slice(0, 7);
      query = query.whereRaw("to_char(budgets.month, 'YYYY-MM') = ?", [mStr]);
    }

    const budgets = await query;

    // Calculate actual spend for each budget in its month
    const budgetsWithSpent = await Promise.all(
      budgets.map(async (b) => {
        const budgetMonthStr = b.month
          ? new Date(b.month).toISOString().slice(0, 7)
          : new Date().toISOString().slice(0, 7);

        const spentRes = await db("transactions")
          .where({
            user_id: b.user_id,
            category_id: b.category_id,
            type: "EXPENSE",
          })
          .whereNull("deleted_at")
          .whereRaw("to_char(date, 'YYYY-MM') = ?", [budgetMonthStr])
          .sum("amount as total")
          .first();

        const spent = Number(spentRes?.total || 0);
        const limit = Number(b.amount || 0);
        const remaining = Math.max(0, limit - spent);
        const percentage = limit > 0 ? Math.round((spent / limit) * 100) : 0;
        const status = percentage > 100 ? "OVER_BUDGET" : percentage >= 80 ? "NEAR_LIMIT" : "UNDER";

        return {
          ...b,
          spent_amount: spent,
          remaining_amount: remaining,
          percentage_used: percentage,
          status,
        };
      })
    );

    res.json(budgetsWithSpent);
  } catch (error) {
    console.error("Admin list budgets error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: Create or Update Budget
router.post("/budgets", async (req: AuthRequest, res: Response) => {
  try {
    const { user_id, category_id, amount, month } = req.body;
    if (!user_id || !category_id || amount === undefined) {
      return res.status(400).json({ error: "user_id, category_id and amount are required" });
    }

    const budgetMonth = month || `${new Date().toISOString().slice(0, 7)}-01`;
    const existing = await db("budgets")
      .where({ user_id, category_id, month: budgetMonth })
      .whereNull("deleted_at")
      .first();

    if (existing) {
      const [updated] = await db("budgets")
        .where({ id: existing.id })
        .update({ amount: Number(amount), updated_at: new Date() })
        .returning("*");
      return res.json(updated);
    }

    const [created] = await db("budgets").insert({
      user_id,
      category_id,
      amount: Number(amount),
      month: budgetMonth
    }).returning("*");

    res.status(201).json(created);
  } catch (error) {
    console.error("Admin save budget error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: Delete Budget
router.delete("/budgets/:id", async (req: AuthRequest, res: Response) => {
  try {
    const count = await db("budgets").where({ id: req.params.id }).update({
      deleted_at: new Date()
    });
    if (!count) return res.status(404).json({ error: "Budget not found" });
    res.json({ message: "Budget deleted successfully" });
  } catch (error) {
    console.error("Admin delete budget error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: List All Recurring Transactions
router.get("/recurring", async (req: AuthRequest, res: Response) => {
  try {
    const recurring = await db("recurring_transactions")
      .leftJoin("users", "recurring_transactions.user_id", "users.id")
      .leftJoin("categories", "recurring_transactions.category_id", "categories.id")
      .whereNull("recurring_transactions.deleted_at")
      .select(
        "recurring_transactions.*",
        "users.name as user_name",
        "users.email as user_email",
        "categories.name as category_name"
      )
      .orderBy("next_due_date", "asc");

    res.json(recurring);
  } catch (error) {
    console.error("Admin list recurring error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: Update Recurring Status
router.put("/recurring/:id/status", async (req: AuthRequest, res: Response) => {
  try {
    const { status } = req.body;
    const [updated] = await db("recurring_transactions")
      .where({ id: req.params.id })
      .update({ status, updated_at: new Date() })
      .returning("*");

    if (!updated) return res.status(404).json({ error: "Recurring item not found" });
    res.json(updated);
  } catch (error) {
    console.error("Admin update recurring status error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: System Health & Diagnostics
router.get("/system", async (req: AuthRequest, res: Response) => {
  try {
    const totalUsers = await db("users").whereNull("deleted_at").count("id as count").first();
    const activeUsers = await db("users").where({ status: "ACTIVE" }).whereNull("deleted_at").count("id as count").first();
    const adminUsers = await db("users").where({ role: "ADMIN" }).whereNull("deleted_at").count("id as count").first();
    const totalTxs = await db("transactions").whereNull("deleted_at").count("id as count").first();
    const totalVolume = await db("transactions").whereNull("deleted_at").sum("amount as total").first();
    const totalBudgets = await db("budgets").whereNull("deleted_at").count("id as count").first();
    const totalRecurring = await db("recurring_transactions").where({ status: "active" }).whereNull("deleted_at").count("id as count").first();

    res.json({
      database: "CONNECTED",
      databaseHost: "localhost:5432",
      databaseName: "finpilot",
      nodeVersion: process.version,
      uptimeSeconds: Math.floor(process.uptime()),
      serverTime: new Date().toISOString(),
      stats: {
        totalUsers: Number(totalUsers?.count || 0),
        activeUsers: Number(activeUsers?.count || 0),
        adminUsers: Number(adminUsers?.count || 0),
        totalTransactions: Number(totalTxs?.count || 0),
        totalVolume: Number(totalVolume?.total || 0),
        totalBudgets: Number(totalBudgets?.count || 0),
        activeRecurringRules: Number(totalRecurring?.count || 0)
      }
    });
  } catch (error) {
    console.error("Admin system health error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin: Aggregated Reports
router.get("/reports", async (req: AuthRequest, res: Response) => {
  try {
    const { user_id } = req.query;
    const isSpecificUser = user_id && user_id !== "all";

    // Past 6 months income vs expenses
    let monthlyStats;
    if (isSpecificUser) {
      monthlyStats = await db.raw(
        `
        SELECT 
          to_char(date, 'YYYY-MM') as month,
          SUM(CASE WHEN type = 'INCOME' THEN amount ELSE 0 END) as income,
          SUM(CASE WHEN type = 'EXPENSE' THEN amount ELSE 0 END) as expense,
          COUNT(id) as transaction_count
        FROM transactions
        WHERE deleted_at IS NULL
          AND user_id = ?
          AND date >= CURRENT_DATE - INTERVAL '6 months'
        GROUP BY to_char(date, 'YYYY-MM')
        ORDER BY month ASC
      `,
        [String(user_id)]
      );
    } else {
      monthlyStats = await db.raw(`
        SELECT 
          to_char(date, 'YYYY-MM') as month,
          SUM(CASE WHEN type = 'INCOME' THEN amount ELSE 0 END) as income,
          SUM(CASE WHEN type = 'EXPENSE' THEN amount ELSE 0 END) as expense,
          COUNT(id) as transaction_count
        FROM transactions
        WHERE deleted_at IS NULL
          AND date >= CURRENT_DATE - INTERVAL '6 months'
        GROUP BY to_char(date, 'YYYY-MM')
        ORDER BY month ASC
      `);
    }

    // Category breakdown
    let catQuery = db("transactions")
      .leftJoin("categories", "transactions.category_id", "categories.id")
      .whereNull("transactions.deleted_at")
      .where("transactions.type", "EXPENSE")
      .select("categories.name as category_name", "categories.color as category_color")
      .sum("transactions.amount as total_amount")
      .groupBy("categories.name", "categories.color")
      .orderBy("total_amount", "desc")
      .limit(8);

    if (isSpecificUser) {
      catQuery = catQuery.where({ "transactions.user_id": user_id as string });
    }

    const categoryStats = await catQuery;

    res.json({
      monthlyTrends: monthlyStats.rows.map((r: any) => ({
        month: r.month,
        income: Number(r.income || 0),
        expense: Number(r.expense || 0),
        transactions: Number(r.transaction_count || 0)
      })),
      categoryBreakdown: categoryStats.map((c: any) => ({
        name: c.category_name || "Uncategorized",
        color: c.category_color || "#10b981",
        amount: Number(c.total_amount || 0)
      }))
    });
  } catch (error) {
    console.error("Admin reports error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

export default router;
