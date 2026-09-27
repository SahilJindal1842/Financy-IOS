import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable("users", (table) => {
    table.decimal("monthly_income", 14, 2).defaultTo(0.0);
    table.string("currency").defaultTo("INR");
    table.string("primary_goal").nullable();
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable("users", (table) => {
    table.dropColumn("primary_goal");
    table.dropColumn("currency");
    table.dropColumn("monthly_income");
  });
}
