import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable("notifications", (table) => {
    table.uuid("id").primary().defaultTo(knex.fn.uuid());
    table.uuid("user_id").notNullable().references("id").inTable("users").onDelete("CASCADE");
    table.string("title").notNullable();
    table.string("message").notNullable();
    table.string("type").notNullable(); // 'income', 'expense', 'budget_alert'
    table.boolean("is_read").defaultTo(false).notNullable();
    table.timestamps(true, true);
    table.timestamp("deleted_at").nullable();
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists("notifications");
}
