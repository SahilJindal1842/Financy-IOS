import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable("budgets", (table) => {
    table.uuid("id").primary().defaultTo(knex.fn.uuid());
    table.uuid("user_id").notNullable().references("id").inTable("users").onDelete("CASCADE");
    table.uuid("category_id").notNullable().references("id").inTable("categories").onDelete("CASCADE");
    table.decimal("amount", 14, 2).notNullable();
    table.date("month").notNullable();
    table.boolean("rollover_enabled").notNullable().defaultTo(false);
    table.timestamps(true, true);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists("budgets");
}
