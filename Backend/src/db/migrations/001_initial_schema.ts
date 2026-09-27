import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable("users", (table) => {
    table.uuid("id").primary().defaultTo(knex.fn.uuid());
    table.string("email").notNullable().unique();
    table.string("password_hash").notNullable();
    table.string("name").notNullable();
    table.timestamps(true, true);
  });

  await knex.schema.createTable("accounts", (table) => {
    table.uuid("id").primary().defaultTo(knex.fn.uuid());
    table.uuid("user_id").notNullable().references("id").inTable("users").onDelete("CASCADE");
    table.string("name").notNullable();
    table.enum("type", ["bank", "credit", "cash"]).notNullable();
    table.string("currency_code").notNullable().defaultTo("USD");
    table.timestamps(true, true);
  });

  await knex.schema.createTable("categories", (table) => {
    table.uuid("id").primary().defaultTo(knex.fn.uuid());
    table.uuid("user_id").nullable().references("id").inTable("users").onDelete("CASCADE");
    table.uuid("parent_id").nullable().references("id").inTable("categories").onDelete("CASCADE");
    table.string("name").notNullable();
    table.string("icon").nullable();
    table.string("color").nullable();
    table.enum("type", ["income", "expense"]).notNullable();
    table.timestamps(true, true);
  });

  await knex.schema.createTable("transactions", (table) => {
    table.uuid("id").primary().defaultTo(knex.fn.uuid());
    table.uuid("user_id").notNullable().references("id").inTable("users").onDelete("CASCADE");
    table.enum("type", ["INCOME", "EXPENSE", "TRANSFER"]).notNullable();
    table.decimal("amount", 14, 2).notNullable();
    table.date("date").notNullable();
    table.uuid("account_id").notNullable().references("id").inTable("accounts").onDelete("CASCADE");
    table.uuid("destination_account_id").nullable().references("id").inTable("accounts").onDelete("CASCADE");
    table.uuid("category_id").nullable().references("id").inTable("categories").onDelete("SET NULL");
    table.string("description").notNullable();
    table.text("notes").nullable();
    table.timestamps(true, true);
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists("transactions");
  await knex.schema.dropTableIfExists("categories");
  await knex.schema.dropTableIfExists("accounts");
  await knex.schema.dropTableIfExists("users");
}
