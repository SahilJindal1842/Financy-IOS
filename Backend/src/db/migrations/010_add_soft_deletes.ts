import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  const tables = [
    "users",
    "accounts",
    "categories",
    "transactions",
    "budgets",
    "recurring_transactions",
    "savings_goals"
  ];

  for (const table of tables) {
    const hasTable = await knex.schema.hasTable(table);
    if (hasTable) {
      await knex.schema.alterTable(table, (t) => {
        t.timestamp("deleted_at").nullable();
      });
    }
  }
}

export async function down(knex: Knex): Promise<void> {
  const tables = [
    "users",
    "accounts",
    "categories",
    "transactions",
    "budgets",
    "recurring_transactions",
    "savings_goals"
  ];

  for (const table of tables) {
    const hasTable = await knex.schema.hasTable(table);
    if (hasTable) {
      await knex.schema.alterTable(table, (t) => {
        t.dropColumn("deleted_at");
      });
    }
  }
}
