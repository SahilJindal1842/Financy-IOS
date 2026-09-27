import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable("users", (table) => {
    table.string("email").nullable().alter();
    table.string("mobile_number").unique().nullable();
    table.enum("role", ["USER", "ADMIN"]).defaultTo("USER");
    table.enum("status", ["PENDING", "ACTIVE", "SUSPENDED", "DISABLED"]).defaultTo("PENDING");
    table.boolean("email_verified").defaultTo(false);
    table.boolean("mobile_verified").defaultTo(false);
    table.timestamp("last_login_at").nullable();
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable("users", (table) => {
    table.dropColumn("last_login_at");
    table.dropColumn("mobile_verified");
    table.dropColumn("email_verified");
    table.dropColumn("status");
    table.dropColumn("role");
    table.dropColumn("mobile_number");
    table.string("email").notNullable().alter();
  });
}
