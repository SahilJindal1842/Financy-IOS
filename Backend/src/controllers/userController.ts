import fs from "fs";
import path from "path";
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
      .select("id", "name", "email", "mobile_number", "role", "monthly_income", "currency", "primary_goal", "created_at", "avatar")
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

    const { monthlyIncome, monthly_income, currency, primaryGoal, primary_goal, name, avatar } = req.body;

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

    if (avatar !== undefined) {
      if (avatar !== null && avatar !== "") {
        const maxSize = 5242880 * (4/3); 
        if (avatar.length > maxSize) {
          return res.status(400).json({ error: "Profile picture exceeds maximum size of 5MB" });
        }
        
        const header = avatar.substring(0, 15);
        if (!header.startsWith("/9j/") && !header.startsWith("iVBORw") && !header.startsWith("R0lGOD")) {
           return res.status(400).json({ error: "Invalid image format. Supported formats are JPG, PNG, GIF." });
        }

        // Save to local disk
        const uploadDir = path.join(process.cwd(), "uploads", "avatars");
        if (!fs.existsSync(uploadDir)) {
          fs.mkdirSync(uploadDir, { recursive: true });
        }

        // Determine extension
        let ext = ".jpg";
        if (header.startsWith("iVBORw")) ext = ".png";
        else if (header.startsWith("R0lGOD")) ext = ".gif";

        const fileName = `${userId}${ext}`;
        const filePath = path.join(uploadDir, fileName);
        
        // Convert base64 to buffer and save
        const buffer = Buffer.from(avatar, "base64");
        fs.writeFileSync(filePath, buffer);

        // Store the URL path in the DB
        updateData.avatar = `/uploads/avatars/${fileName}?t=${Date.now()}`;
      } else {
        updateData.avatar = null;
      }
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
      .select("id", "name", "email", "mobile_number", "role", "monthly_income", "currency", "primary_goal", "avatar")
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
      .select("id", "name", "email", "monthly_income", "currency", "avatar")
      .first();

    const monthlyIncome = Number(user?.monthly_income || 0);

    // 2. Fetch all user transactions for current month
    const today = new Date();
    const currentMonthStr = today.toISOString().slice(0, 7); // YYYY-MM
    
    const currentMonthTxs = await db("transactions")
      .leftJoin("categories", "transactions.category_id", "categories.id")
      .where({ "transactions.user_id": userId })
      .whereNull("transactions.deleted_at")
      .whereRaw("to_char(date, 'YYYY-MM') = ?", [currentMonthStr])
      .select("transactions.*", "categories.name as category_name");

    let totalExpenses = 0;
    let extraIncome = 0;

    for (const tx of currentMonthTxs) {
      const amt = Number(tx.amount || 0);
      if (tx.type === "EXPENSE") {
        totalExpenses += amt;
      } else if (tx.type === "INCOME") {
        extraIncome += amt;
      }
    }

    const totalIncome = monthlyIncome + extraIncome;
    const balance = totalIncome - totalExpenses;
    const savings = balance;

    // Fetch total budget for current month
    // Get the latest budget for each category for this user
    const budgets = await db("budgets")
      .where({ user_id: userId })
      .whereNull("deleted_at")
      .distinctOn("category_id")
      .orderBy("category_id")
      .orderBy("month", "desc");
      
    let totalBudget = 0;
    for (const b of budgets) {
        totalBudget += Number(b.amount || 0);
    }
    
    
    const budgetUsedPercentage = totalBudget > 0 ? Math.min(100, Math.round((totalExpenses / totalBudget) * 100)) : 0;
    const remainingBudget = totalBudget - totalExpenses;

    // 3. Fetch upcoming recurring bills
    const nextWeek = new Date();
    nextWeek.setDate(today.getDate() + 14); // Next 14 days
    
    const upcomingBills = await db("recurring_transactions")
      .where({ user_id: userId, status: "active" })
      .whereNull("deleted_at")
      .where("next_due_date", ">=", today.toISOString().split("T")[0])
      .where("next_due_date", "<=", nextWeek.toISOString().split("T")[0])
      .orderBy("next_due_date", "asc")
      .limit(3); // Prototype shows 3 items usually

    // Format transactions for recent list
    const recentTxs = await db("transactions")
      .leftJoin("categories", "transactions.category_id", "categories.id")
      .where({ "transactions.user_id": userId })
      .whereNull("transactions.deleted_at")
      .orderBy("date", "desc")
      .limit(5)
      .select("transactions.*", "categories.name as category_name");

    const formattedTransactions = recentTxs.map(t => ({
      id: t.id,
      accountId: t.account_id,
      categoryId: t.category_id,
      amount: t.type === "EXPENSE" ? -Math.abs(Number(t.amount)) : Math.abs(Number(t.amount)),
      type: (t.type || "EXPENSE").toLowerCase(),
      date: t.date,
      note: t.notes || t.description,
      merchant: t.description || t.category_name || "Expense"
    }));

    res.json({
      userName: user?.name || "User",
      avatar: user?.avatar,
      currency: user?.currency || "INR",
      monthlyIncome,
      totalIncome,
      totalExpenses,
      balance,
      savings,
      budget: totalBudget,
      remainingBudget,
      budgetUsedPercentage,
      incomeGrowth: 12.0, // Dummy for prototype
      expenseGrowth: 8.0,
      savingsGrowth: 16.0,
      transactions: formattedTransactions,
      upcomingBills: upcomingBills.map(b => ({
        id: b.id,
        merchant: b.merchant || "Bill",
        amount: Number(b.amount),
        nextDueDate: b.next_due_date,
        frequency: b.frequency,
        type: b.type
      }))
    });
  } catch (error) {
    console.error("Error fetching dashboard stats:", error);
    res.status(500).json({ error: "Failed to fetch dashboard stats" });
  }
};
