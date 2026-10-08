import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  // 1. Add settled_for_reports to transactions
  const hasSettledForReports = await knex.schema.hasColumn("transactions", "settled_for_reports");
  if (!hasSettledForReports) {
    await knex.schema.alterTable("transactions", (table) => {
      table.boolean("settled_for_reports").defaultTo(false);
    });
  }

  // 2. Add is_system to categories
  const hasIsSystem = await knex.schema.hasColumn("categories", "is_system");
  if (!hasIsSystem) {
    await knex.schema.alterTable("categories", (table) => {
      table.boolean("is_system").defaultTo(false);
    });
  }

  // 3. Add profile fields to users if missing
  const hasSavingsTarget = await knex.schema.hasColumn("users", "savings_target");
  if (!hasSavingsTarget) {
    await knex.schema.alterTable("users", (table) => {
      table.decimal("savings_target", 14, 2).defaultTo(0);
    });
  }

  const hasNotifEnabled = await knex.schema.hasColumn("users", "notifications_enabled");
  if (!hasNotifEnabled) {
    await knex.schema.alterTable("users", (table) => {
      table.boolean("notifications_enabled").defaultTo(true);
    });
  }

  const hasBioEnabled = await knex.schema.hasColumn("users", "biometrics_enabled");
  if (!hasBioEnabled) {
    await knex.schema.alterTable("users", (table) => {
      table.boolean("biometrics_enabled").defaultTo(false);
    });
  }

  // 4. Backfill existing settled transactions
  await knex("transactions")
    .where("is_settled", true)
    .update({ settled_for_reports: true });

  // 5. Mark global categories as is_system = true
  await knex("categories")
    .whereNull("user_id")
    .update({ is_system: true });

  // 6. Ensure standard essential default categories exist
  const standardCategories = [
    { name: "Groceries", type: "expense", icon: "cart.fill", color: "#10B981" },
    { name: "Food & Dining", type: "expense", icon: "fork.knife", color: "#F59E0B" },
    { name: "Rent & Housing", type: "expense", icon: "house.fill", color: "#6366F1" },
    { name: "Utilities & Bills", type: "expense", icon: "bolt.fill", color: "#EC4899" },
    { name: "Transportation", type: "expense", icon: "car.fill", color: "#3B82F6" },
    { name: "Health & Medical", type: "expense", icon: "cross.case.fill", color: "#EF4444" },
    { name: "Entertainment", type: "expense", icon: "film.fill", color: "#8B5CF6" },
    { name: "Shopping", type: "expense", icon: "bag.fill", color: "#F97316" },
    { name: "Personal Care", type: "expense", icon: "heart.fill", color: "#14B8A6" },
    { name: "Education", type: "expense", icon: "book.fill", color: "#06B6D4" },
    { name: "Salary", type: "income", icon: "briefcase.fill", color: "#10B981" },
    { name: "Investments", type: "income", icon: "chart.line.uptrend.xyaxis", color: "#3B82F6" },
    { name: "Freelance", type: "income", icon: "laptopcomputer", color: "#8B5CF6" },
    { name: "Other Income", type: "income", icon: "dollarsign.circle.fill", color: "#F59E0B" }
  ];

  for (const cat of standardCategories) {
    const existing = await knex("categories")
      .where({ name: cat.name, user_id: null })
      .first();

    if (!existing) {
      await knex("categories").insert({
        user_id: null,
        name: cat.name,
        type: cat.type,
        icon: cat.icon,
        color: cat.color,
        is_system: true
      });
    } else {
      await knex("categories")
        .where({ id: existing.id })
        .update({ is_system: true, icon: cat.icon, color: cat.color });
    }
  }
}

export async function down(knex: Knex): Promise<void> {
  const hasSettledForReports = await knex.schema.hasColumn("transactions", "settled_for_reports");
  if (hasSettledForReports) {
    await knex.schema.alterTable("transactions", (table) => {
      table.dropColumn("settled_for_reports");
    });
  }

  const hasIsSystem = await knex.schema.hasColumn("categories", "is_system");
  if (hasIsSystem) {
    await knex.schema.alterTable("categories", (table) => {
      table.dropColumn("is_system");
    });
  }

  const hasSavingsTarget = await knex.schema.hasColumn("users", "savings_target");
  if (hasSavingsTarget) {
    await knex.schema.alterTable("users", (table) => {
      table.dropColumn("savings_target");
    });
  }

  const hasNotifEnabled = await knex.schema.hasColumn("users", "notifications_enabled");
  if (hasNotifEnabled) {
    await knex.schema.alterTable("users", (table) => {
      table.dropColumn("notifications_enabled");
    });
  }

  const hasBioEnabled = await knex.schema.hasColumn("users", "biometrics_enabled");
  if (hasBioEnabled) {
    await knex.schema.alterTable("users", (table) => {
      table.dropColumn("biometrics_enabled");
    });
  }
}
