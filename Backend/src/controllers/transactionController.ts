import { Response, NextFunction } from "express";
import { AuthRequest } from "../middleware/auth";
import db from "../db/db";
import { getQueryScope } from "../utils/rbacUtils";
import { z } from "zod";

const transactionSchema = z.object({
  type: z.enum(["INCOME", "EXPENSE", "TRANSFER"]),
  amount: z.number().positive("Amount must be greater than 0"),
  date: z.string().refine((val) => !isNaN(Date.parse(val)), { message: "Invalid date format" }),
  account_id: z.string().uuid("Invalid account_id UUID"),
  destination_account_id: z.string().uuid("Invalid destination_account_id UUID").optional().nullable(),
  category_id: z.string().uuid("Invalid category_id UUID").optional().nullable(),
  description: z.string().optional().nullable(),
  notes: z.string().optional().nullable()
});

export const getTransactions = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const scope = getQueryScope(req);
    const whereClause = scope.user_id ? { "transactions.user_id": scope.user_id } : scope;
    const { status, include_settled, month } = req.query;
    
    let query = db("transactions")
      .leftJoin("categories", "transactions.category_id", "categories.id")
      .leftJoin("users", "transactions.user_id", "users.id")
      .where(whereClause)
      .whereNull("transactions.deleted_at");

    if (month && typeof month === "string" && /^\d{4}-\d{2}$/.test(month)) {
      query = query.where(function() {
        this.where("transactions.settled_month", month)
          .orWhereRaw("to_char(transactions.date, 'YYYY-MM') = ?", [month]);
      });
    }

    if (status === "settled") {
      query = query.where("transactions.is_settled", true);
    } else if (status === "active") {
      query = query.where(function() {
        this.whereNull("transactions.is_settled").orWhere("transactions.is_settled", false);
      });
    } else {
      // Include all transactions by default (both active and settled) so records are preserved for history and reports
    }

    const transactions = await query
      .select(
        "transactions.*",
        "categories.name as category_name",
        "categories.icon as category_icon",
        "categories.color as category_color",
        "users.name as user_name",
        "users.email as user_email"
      )
      .orderBy("transactions.date", "desc")
      .orderBy("transactions.created_at", "desc");

    const formatted = transactions.map((t) => ({
      id: t.id,
      userId: t.user_id,
      user_id: t.user_id,
      userName: t.user_name || "User",
      user_name: t.user_name || "User",
      userEmail: t.user_email || "",
      user_email: t.user_email || "",
      accountId: t.account_id,
      categoryId: t.category_name || t.category_id,
      amount: t.type === "EXPENSE" ? -Math.abs(Number(t.amount)) : Math.abs(Number(t.amount)),
      type: (t.type || "EXPENSE").toLowerCase(),
      date: t.date,
      note: t.notes || t.description,
      merchant: t.description || t.category_name || "Expense",
      destinationAccountId: t.destination_account_id,
      isSettled: !!t.is_settled,
      settledMonth: t.settled_month,
      settledForReports: !!t.settled_for_reports,
      createdAt: t.created_at,
      updatedAt: t.updated_at
    }));

    res.json(formatted);
  } catch (error) {
    next(error);
  }
};

export const createTransaction = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const rawType = (req.body.type || "EXPENSE").toUpperCase();
    const type = ["INCOME", "EXPENSE", "TRANSFER"].includes(rawType) ? rawType : "EXPENSE";

    const rawAmount = parseFloat(String(req.body.amount || 0));
    const amount = Math.abs(rawAmount);

    if (isNaN(amount) || amount <= 0) {
      return res.status(400).json({ error: "Amount must be greater than 0" });
    }

    const dateVal = req.body.date ? new Date(req.body.date) : new Date();
    const date = isNaN(dateVal.getTime()) ? new Date().toISOString().split("T")[0] : dateVal.toISOString().split("T")[0];

    // Check if the month is already settled and locked
    const txMonth = date.substring(0, 7);
    const settledMonth = await db("monthly_savings")
      .where({ user_id: userId, month: txMonth })
      .first();

    if (settledMonth) {
      return res.status(400).json({
        error: `Month ${txMonth} has already been settled and locked. Adding new expenses or income to a settled month is not allowed.`
      });
    }

    // Ensure valid account_id belonging to user
    let accountId = req.body.account_id || req.body.accountId;
    const isUUID = accountId && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(accountId);

    if (!isUUID) {
      let userAccount = await db("accounts").where({ user_id: userId }).first();
      if (!userAccount) {
        [userAccount] = await db("accounts").insert({
          user_id: userId,
          name: "Primary Account",
          type: "cash",
          currency_code: "INR"
        }).returning("*");
      }
      accountId = userAccount.id;
    }

    // Resolve category_id (UUID or Name)
    let categoryId = req.body.category_id || req.body.categoryId || req.body.category;
    if (categoryId) {
      const isCatUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(categoryId);
      if (!isCatUUID) {
        let cat = await db("categories").where({ name: categoryId }).first();
        if (!cat) {
          [cat] = await db("categories").insert({
            name: categoryId,
            type: type === "INCOME" ? "income" : "expense"
          }).returning("*");
        }
        categoryId = cat.id;
      }
    }

    const description = req.body.description || req.body.merchant || req.body.category || "Expense";
    const notes = req.body.notes || req.body.note || null;
    const destinationAccountId = type === "TRANSFER" ? (req.body.destination_account_id || req.body.destinationAccountId) : null;

    const [transaction] = await db("transactions").insert({
      user_id: userId,
      type,
      amount,
      date,
      account_id: accountId,
      destination_account_id: destinationAccountId,
      category_id: type === "TRANSFER" ? null : categoryId,
      description,
      notes
    }).returning("*");
    // ---------------- NOTIFICATIONS LOGIC ----------------
    try {
      if (type === "INCOME") {
        await db("notifications").insert({
          user_id: userId,
          type: "income",
          title: "Income Added",
          message: `You have successfully added an income of ${amount}.`
        });
      } else if (type === "EXPENSE") {
        await db("notifications").insert({
          user_id: userId,
          type: "expense",
          title: "Expense Added",
          message: `You have added an expense of ${amount} for ${description}.`
        });

        // Budget check
        if (categoryId) {
          const [year, month] = date.split("-");
          const monthDate = `${year}-${month}-01`;
          
          const budget = await db("budgets")
            .where({ user_id: userId, category_id: categoryId, month: monthDate })
            .whereNull("deleted_at")
            .first();

          if (budget) {
            const nextMonth = Number(month) === 12 ? 1 : Number(month) + 1;
            const nextYear = Number(month) === 12 ? Number(year) + 1 : Number(year);
            const endDate = `${nextYear}-${String(nextMonth).padStart(2, "0")}-01`;
            
            const expenses = await db("transactions")
              .where({ user_id: userId, type: "EXPENSE", category_id: categoryId })
              .andWhere("date", ">=", monthDate)
              .andWhere("date", "<", endDate)
              .whereNull("deleted_at");

            const totalSpent = expenses.reduce((sum, exp) => sum + Number(exp.amount), 0);
            const budgetAmount = Number(budget.amount);

            if (totalSpent >= budgetAmount * 0.9) {
              const exceedMsg = totalSpent > budgetAmount 
                ? `You have exceeded your budget! You've spent ${totalSpent} out of ${budgetAmount}.`
                : `You are approaching your budget limit! You've spent ${totalSpent} out of ${budgetAmount}.`;
              
              await db("notifications").insert({
                user_id: userId,
                type: "budget_alert",
                title: "Budget Alert",
                message: exceedMsg
              });
            }
          }
        }
      }
    } catch (notifErr) {
      console.error("Error creating notification:", notifErr);
      // We don't fail the transaction if notification fails
    }
    // ------------------------------------------------------


    res.status(201).json({
      id: transaction.id,
      userId: transaction.user_id,
      accountId: transaction.account_id,
      categoryId: req.body.category || req.body.categoryId || transaction.category_id,
      amount: transaction.type === "EXPENSE" ? -Math.abs(Number(transaction.amount)) : Math.abs(Number(transaction.amount)),
      type: transaction.type.toLowerCase(),
      date: transaction.date,
      note: transaction.notes,
      merchant: transaction.description,
      destinationAccountId: transaction.destination_account_id,
      createdAt: transaction.created_at,
      updatedAt: transaction.updated_at
    });
  } catch (error) {
    next(error);
  }
};

export const deleteTransaction = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const scope = getQueryScope(req);
    const { id } = req.params;
    const whereClause = scope.user_id ? { id, user_id: scope.user_id } : { id };
    
    const existing = await db("transactions").where(whereClause).whereNull("deleted_at").first();
    if (!existing) {
      return res.status(404).json({ error: "Transaction not found" });
    }

    if (existing.is_settled) {
      return res.status(400).json({ error: "Cannot delete a settled transaction. Settled transactions are preserved for monthly reports." });
    }

    await db("transactions").where(whereClause).update({ deleted_at: db.fn.now() });
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
};
