import { Response } from "express";
import { AuthRequest } from "../middleware/auth";
import db from "../db/db";
import { getQueryScope } from "../utils/rbacUtils";

export const getAccounts = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    
    // Fetch all accounts for user
    const accounts = await db("accounts").where(scope);
    
    // Fetch all transactions for user
    const transactions = await db("transactions").where(scope);
    
    // Calculate balances
    const accountsWithBalances = accounts.map((account) => {
      let balance = 0;
      for (const tx of transactions) {
        const amount = Number(tx.amount);
        if (tx.account_id === account.id) {
          if (tx.type === "INCOME") balance += amount;
          if (tx.type === "EXPENSE") balance -= amount;
          if (tx.type === "TRANSFER") balance -= amount;
        }
        if (tx.destination_account_id === account.id && tx.type === "TRANSFER") {
          balance += amount;
        }
      }
      return { ...account, balance };
    });

    res.json(accountsWithBalances);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const createAccount = async (req: AuthRequest, res: Response) => {
  try {
    const { name, type, currency_code } = req.body;
    const [account] = await db("accounts").insert({
      user_id: req.user?.id,
      name,
      type,
      currency_code: currency_code || "USD",
    }).returning("*");
    
    res.status(201).json({ ...account, balance: 0 });
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
};
