import { Knex } from "knex";
import bcrypt from "bcrypt";
import crypto from "crypto";

export async function seed(knex: Knex): Promise<void> {
  // Deletes ALL existing entries
  await knex("transactions").del();
  await knex("categories").del();
  await knex("accounts").del();
  await knex("users").del();

  const userId = crypto.randomUUID();
  const passwordHash = await bcrypt.hash("password123", 10);

  // 1. Users
  await knex("users").insert([
    {
      id: userId,
      email: "john@example.com",
      password_hash: passwordHash,
      name: "John Doe",
    },
  ]);

  // 2. Categories
  const foodCatId = crypto.randomUUID();
  const housingCatId = crypto.randomUUID();
  const salaryCatId = crypto.randomUUID();

  await knex("categories").insert([
    { id: foodCatId, name: "Food", type: "expense", icon: "fast-food", color: "#FF5733" },
    { id: housingCatId, name: "Housing", type: "expense", icon: "home", color: "#3388FF" },
    { id: salaryCatId, name: "Salary", type: "income", icon: "cash", color: "#33FF57" },
  ]);

  // Subcategories
  const groceriesCatId = crypto.randomUUID();
  const rentCatId = crypto.randomUUID();
  await knex("categories").insert([
    { id: groceriesCatId, parent_id: foodCatId, name: "Groceries", type: "expense", icon: "basket", color: "#FF8F33" },
    { id: rentCatId, parent_id: housingCatId, name: "Rent", type: "expense", icon: "key", color: "#3355FF" },
  ]);

  // 3. Accounts
  const hdfcAccountId = crypto.randomUUID();
  const cashAccountId = crypto.randomUUID();

  await knex("accounts").insert([
    { id: hdfcAccountId, user_id: userId, name: "HDFC Bank", type: "bank", currency_code: "INR" },
    { id: cashAccountId, user_id: userId, name: "Cash", type: "cash", currency_code: "INR" },
  ]);

  // 4. Transactions
  await knex("transactions").insert([
    {
      id: crypto.randomUUID(),
      user_id: userId,
      type: "INCOME",
      amount: 50000,
      date: new Date().toISOString().split("T")[0],
      account_id: hdfcAccountId,
      category_id: salaryCatId,
      description: "Monthly Salary",
    },
    {
      id: crypto.randomUUID(),
      user_id: userId,
      type: "EXPENSE",
      amount: 15000,
      date: new Date().toISOString().split("T")[0],
      account_id: hdfcAccountId,
      category_id: rentCatId,
      description: "Rent Payment",
    },
    {
      id: crypto.randomUUID(),
      user_id: userId,
      type: "TRANSFER",
      amount: 5000,
      date: new Date().toISOString().split("T")[0],
      account_id: hdfcAccountId,
      destination_account_id: cashAccountId,
      description: "ATM Withdrawal",
    },
    {
      id: crypto.randomUUID(),
      user_id: userId,
      type: "EXPENSE",
      amount: 1000,
      date: new Date().toISOString().split("T")[0],
      account_id: cashAccountId,
      category_id: groceriesCatId,
      description: "Groceries",
    },
  ]);
}
