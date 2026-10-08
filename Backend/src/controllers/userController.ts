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
      .select(
        "id", "name", "email", "mobile_number", "role",
        "monthly_income", "currency", "primary_goal", "created_at", "avatar",
        "subscription_status", "is_subscribed", "trial_ends_at",
        "savings_target", "notifications_enabled", "biometrics_enabled", "last_settled_month"
      )
      .first();

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    const now = new Date();
    const trialEnd = user.trial_ends_at ? new Date(user.trial_ends_at) : new Date(new Date(user.created_at).getTime() + 7 * 24 * 60 * 60 * 1000);
    const msRemaining = trialEnd.getTime() - now.getTime();
    const daysRemaining = Math.max(0, Math.ceil(msRemaining / (1000 * 60 * 60 * 24)));
    const isExpired = msRemaining <= 0 && !user.is_subscribed;
    const computedStatus = user.is_subscribed ? "LIFETIME" : (isExpired ? "EXPIRED" : "TRIAL");
    const settledRows = await db("monthly_savings")
      .where({ user_id: userId })
      .select("month");
    const settledMonths = settledRows.map((r: any) => r.month);

    res.json({
      user: {
        ...user,
        settledMonths,
        settled_months: settledMonths,
        mobileNumber: user.mobile_number || "",
        monthlyIncome: Number(user.monthly_income || 0),
        monthly_income: Number(user.monthly_income || 0),
        savingsTarget: Number(user.savings_target || 0),
        savings_target: Number(user.savings_target || 0),
        notificationsEnabled: user.notifications_enabled !== false,
        biometricsEnabled: !!user.biometrics_enabled,
        subscription_status: computedStatus,
        is_subscribed: !!user.is_subscribed,
        trial_ends_at: trialEnd,
        trial_days_remaining: daysRemaining,
        is_trial_expired: isExpired
      }
    });
  } catch (error) {
    console.error("Error fetching profile:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const subscribe = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    await db("users").where({ id: userId }).update({
      is_subscribed: true,
      subscription_status: "ACTIVE_LIFETIME",
      updated_at: new Date()
    });

    res.json({
      success: true,
      message: "Subscribed to Lifetime Access ($9.99) successfully!",
      is_subscribed: true,
      subscription_status: "ACTIVE_LIFETIME"
    });
  } catch (error) {
    console.error("Subscription error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const updateProfile = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const {
      monthlyIncome, monthly_income,
      currency,
      primaryGoal, primary_goal,
      name,
      avatar,
      mobileNumber, mobile_number,
      email,
      savingsTarget, savings_target,
      notificationsEnabled, notifications_enabled,
      biometricsEnabled, biometrics_enabled
    } = req.body;

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

    if (email !== undefined && email.includes("@")) {
      updateData.email = email;
    }

    const mobVal = mobileNumber !== undefined ? mobileNumber : mobile_number;
    if (mobVal !== undefined) {
      updateData.mobile_number = mobVal;
    }

    const savVal = savingsTarget !== undefined ? savingsTarget : savings_target;
    if (savVal !== undefined) {
      const parsedSav = parseFloat(String(savVal).replace(/[^0-9.]/g, ""));
      updateData.savings_target = isNaN(parsedSav) ? 0.0 : parsedSav;
    }

    const notifVal = notificationsEnabled !== undefined ? notificationsEnabled : notifications_enabled;
    if (notifVal !== undefined) {
      updateData.notifications_enabled = Boolean(notifVal);
    }

    const bioVal = biometricsEnabled !== undefined ? biometricsEnabled : biometrics_enabled;
    if (bioVal !== undefined) {
      updateData.biometrics_enabled = Boolean(bioVal);
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
      .select(
        "id", "name", "email", "mobile_number", "role",
        "monthly_income", "currency", "primary_goal", "avatar",
        "savings_target", "notifications_enabled", "biometrics_enabled"
      )
      .first();

    res.json({
      message: "Profile updated successfully",
      user: {
        ...updatedUser,
        mobileNumber: updatedUser?.mobile_number || "",
        monthlyIncome: Number(updatedUser?.monthly_income || 0),
        monthly_income: Number(updatedUser?.monthly_income || 0),
        savingsTarget: Number(updatedUser?.savings_target || 0),
        savings_target: Number(updatedUser?.savings_target || 0),
        notificationsEnabled: updatedUser?.notifications_enabled !== false,
        biometricsEnabled: !!updatedUser?.biometrics_enabled
      }
    });
  } catch (error) {
    console.error("Error updating profile:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const deleteAccount = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    await db("users").where({ id: userId }).update({
      deleted_at: new Date(),
      status: "deleted"
    });

    res.json({ success: true, message: "Account deleted successfully" });
  } catch (error) {
    console.error("Error deleting account:", error);
    res.status(500).json({ error: "Failed to delete account" });
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
      .select("id", "name", "email", "monthly_income", "currency", "avatar", "last_settled_month")
      .first();

    const monthlyIncome = Number(user?.monthly_income || 0);

    // 2. Fetch user transactions for requested/current month
    const today = new Date();
    const requestedMonth = typeof req.query.month === "string" && /^\d{4}-\d{2}$/.test(req.query.month) 
      ? req.query.month 
      : today.toISOString().slice(0, 7); // YYYY-MM
    const currentMonthStr = requestedMonth;
    
    // Check if month is settled from monthly_savings
    const settlement = await db("monthly_savings")
      .where({ user_id: userId, month: currentMonthStr })
      .first();
    const isSettled = !!settlement;
    
    const [year, monthNum] = currentMonthStr.split("-").map(Number);
    const lastDayOfMonth = new Date(year, monthNum, 0).getDate();
    const endOfMonthDateStr = `${year}-${String(monthNum).padStart(2, "0")}-${String(lastDayOfMonth).padStart(2, "0")}`;
    const isEndOfMonth = (today.getFullYear() > year) || (today.getFullYear() === year && (today.getMonth() + 1) > monthNum) || (today.getFullYear() === year && (today.getMonth() + 1) === monthNum && today.getDate() >= 25);

    // Fetch all current month transactions regardless of is_settled to preserve real expense history
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

    if (settlement && Number(settlement.total_expenses || 0) > totalExpenses) {
      totalExpenses = Number(settlement.total_expenses);
    }

    // Total income calculation:
    // Base income is monthlyIncome (e.g. ₹20,000) + any extra income transactions.
    // If the month is settled, settlement.total_income already contains the full total income (monthlyIncome + extraIncome).
    // Do NOT set extraIncome = settlement.total_income as that adds monthlyIncome twice!
    let totalIncome = monthlyIncome + extraIncome;
    if (settlement && Number(settlement.total_income || 0) > 0) {
      totalIncome = Math.max(Number(settlement.total_income), monthlyIncome + extraIncome);
    }

    // Real financial calculation logic:
    // - Monthly Income = actual money user earns (profile monthly_income + current month extra income)
    // - Actual Spent = sum of actual expense transactions only
    // - Available Money = Total Income - Actual Spent (Never add budget to income or available money)
    // - Budget = spending plan/limit only, kept completely separate from cash balances
    const actualSpent = totalExpenses;
    const availableMoney = isSettled ? 0 : Math.max(0, totalIncome - actualSpent);
    const balance = availableMoney;

    // Fetch total accumulated monthly savings from monthly_savings table
    const allMonthlySavings = await db("monthly_savings")
      .where({ user_id: userId })
      .sum("saved_amount as total");
    const accumulatedSavings = Number(allMonthlySavings[0]?.total || 0);
    const savings = accumulatedSavings + (isSettled ? 0 : availableMoney);

    // Fetch total category budget for current month (purely a spending plan/limit)
    let totalBudget = 0;
    if (settlement && Number(settlement.total_budget || 0) > 0) {
      totalBudget = Number(settlement.total_budget);
    } else {
      const currentMonthBudgets = await db("budgets")
        .where({ user_id: userId, month: `${currentMonthStr}-01` })
        .whereNull("deleted_at");

      for (const b of currentMonthBudgets) {
        totalBudget += Number(b.amount || 0);
      }
    }
    
    // Budget Remaining = Total Budget - Actual Spent (independent from cash balance)
    const budgetUsedPercentage = totalBudget > 0 ? Math.min(100, Math.round((actualSpent / totalBudget) * 100)) : 0;
    const remainingBudget = Math.max(0, totalBudget - actualSpent);

    // Actual unspent income available to transfer to savings upon settlement:
    // When settling, unused budget is NOT money received; only actual unspent income (Income - Expenses) is saved!
    const unspentIncomeToSave = settlement 
      ? Number(settlement.saved_amount || 0) 
      : Math.max(0, totalIncome - actualSpent);

    // 3. Fetch upcoming recurring bills (including due today and within 14 days, with 2-day overdue tolerance)
    const upcomingLimit = new Date();
    upcomingLimit.setDate(today.getDate() + 14); // Next 14 days
    const pastOverdueTolerance = new Date();
    pastOverdueTolerance.setDate(today.getDate() - 3);
    
    const upcomingBills = await db("recurring_transactions")
      .where({ user_id: userId, status: "active" })
      .whereNull("deleted_at")
      .where("next_due_date", ">=", pastOverdueTolerance.toISOString().split("T")[0])
      .where("next_due_date", "<=", upcomingLimit.toISOString().split("T")[0])
      .orderBy("next_due_date", "asc")
      .limit(15);

    // Auto-generate notifications for bills due on due date (today) and 2 days before
    try {
      const todayDateStr = today.toISOString().split("T")[0];
      const twoDaysFromNow = new Date();
      twoDaysFromNow.setDate(today.getDate() + 2);
      const twoDaysStr = twoDaysFromNow.toISOString().split("T")[0];

      const dueAlertBills = upcomingBills.filter(b => {
        if (b.type !== "expense") return false;
        const dStr = (b.next_due_date instanceof Date ? b.next_due_date.toISOString() : String(b.next_due_date)).split("T")[0];
        return dStr <= twoDaysStr;
      });

      for (const bill of dueAlertBills) {
        const dStr = (bill.next_due_date instanceof Date ? bill.next_due_date.toISOString() : String(bill.next_due_date)).split("T")[0];
        const diffMs = new Date(dStr).getTime() - new Date(todayDateStr).getTime();
        const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));
        
        let title = "Upcoming Bill Reminder";
        let timeDesc = `due in ${diffDays} days`;
        if (diffDays <= 0) {
          title = "Recurring Payment Due Today!";
          timeDesc = "due today";
        } else if (diffDays === 1) {
          title = "Recurring Payment Due Tomorrow";
          timeDesc = "due tomorrow";
        } else if (diffDays === 2) {
          title = "Recurring Payment Due in 2 Days";
          timeDesc = "due in 2 days";
        }
        
        const message = `${bill.merchant || "Recurring expense"} of INR ${Number(bill.amount).toLocaleString()} is ${timeDesc}.`;
        
        const existing = await db("notifications")
          .where({ user_id: userId, title })
          .whereRaw("created_at >= ?", [todayDateStr])
          .whereNull("deleted_at")
          .first();

        if (!existing) {
          await db("notifications").insert({
            user_id: userId,
            title,
            message,
            type: "BILL_REMINDER",
            is_read: false
          });
        }
      }
    } catch (e) {
      console.error("Error auto-generating bill reminder notifications:", e);
    }

    // Format transactions for recent list
    const recentTxs = await db("transactions")
      .leftJoin("categories", "transactions.category_id", "categories.id")
      .where({ "transactions.user_id": userId })
      .whereNull("transactions.deleted_at")
      .whereRaw("to_char(date, 'YYYY-MM') = ?", [currentMonthStr])
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
      monthlyIncome: monthlyIncome,
      totalIncome,
      totalExpenses: actualSpent,
      balance,
      availableMoney,
      savings,
      budget: totalBudget,
      remainingBudget,
      budgetUsedPercentage,
      incomeGrowth: 12.0,
      expenseGrowth: 8.0,
      savingsGrowth: 16.0,
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
