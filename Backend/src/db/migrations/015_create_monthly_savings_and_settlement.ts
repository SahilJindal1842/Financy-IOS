import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  const hasSavingsTable = await knex.schema.hasTable("monthly_savings");
  if (!hasSavingsTable) {
    await knex.schema.createTable("monthly_savings", (table) => {
      table.uuid("id").primary().defaultTo(knex.fn.uuid());
      table.uuid("user_id").notNullable().references("id").inTable("users").onDelete("CASCADE");
      table.string("month", 7).notNullable(); // YYYY-MM
      table.decimal("saved_amount", 14, 2).notNullable().defaultTo(0);
      table.decimal("total_budget", 14, 2).notNullable().defaultTo(0);
      table.decimal("total_expenses", 14, 2).notNullable().defaultTo(0);
      table.decimal("total_income", 14, 2).notNullable().defaultTo(0);
      table.timestamp("settled_at").defaultTo(knex.fn.now());
      table.text("notes").nullable();
      table.timestamps(true, true);
      table.unique(["user_id", "month"]);
    });
  }

  const hasIsSettled = await knex.schema.hasColumn("transactions", "is_settled");
  if (!hasIsSettled) {
    await knex.schema.alterTable("transactions", (table) => {
      table.boolean("is_settled").defaultTo(false);
      table.string("settled_month", 7).nullable();
    });
  }

  const hasLastSettledMonth = await knex.schema.hasColumn("users", "last_settled_month");
  if (!hasLastSettledMonth) {
    await knex.schema.alterTable("users", (table) => {
      table.string("last_settled_month", 7).nullable();
    });
  }
}

export async function down(knex: Knex): Promise<void> {
  const hasLastSettledMonth = await knex.schema.hasColumn("users", "last_settled_month");
  if (hasLastSettledMonth) {
    await knex.schema.alterTable("users", (table) => {
      table.dropColumn("last_settled_month");
    });
  }

  const hasIsSettled = await knex.schema.hasColumn("transactions", "is_settled");
  if (hasIsSettled) {
    await knex.schema.alterTable("transactions", (table) => {
      table.dropColumn("settled_month");
      table.dropColumn("is_settled");
    });
  }

  await knex.schema.dropTableIfExists("monthly_savings");
}
