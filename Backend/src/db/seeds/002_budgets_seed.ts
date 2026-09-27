import { Knex } from "knex";
import crypto from "crypto";

export async function seed(knex: Knex): Promise<void> {
  // Deletes ALL existing entries
  await knex("budgets").del();

  const user = await knex("users").where({ email: "john@example.com" }).first();
  if (!user) {
    console.error("User john@example.com not found for seeding budgets.");
    return;
  }

  const foodCat = await knex("categories").where({ name: "Food" }).first();
  const housingCat = await knex("categories").where({ name: "Housing" }).first();

  if (!foodCat || !housingCat) {
    console.error("Categories Food or Housing not found for seeding budgets.");
    return;
  }

  const now = new Date();
  // Ensure we use the 1st of the current month
  const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-01`;

  await knex("budgets").insert([
    {
      id: crypto.randomUUID(),
      user_id: user.id,
      category_id: foodCat.id,
      amount: 10000,
      month: currentMonth,
      rollover_enabled: false,
    },
    {
      id: crypto.randomUUID(),
      user_id: user.id,
      category_id: housingCat.id,
      amount: 20000,
      month: currentMonth,
      rollover_enabled: true,
    },
  ]);
}
