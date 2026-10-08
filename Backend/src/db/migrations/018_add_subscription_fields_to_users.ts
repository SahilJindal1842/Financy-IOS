import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  await knex.schema.alterTable("users", (table) => {
    table.string("subscription_status", 50).defaultTo("TRIAL");
    table.boolean("is_subscribed").defaultTo(false);
    table.timestamp("trial_ends_at", { useTz: true }).nullable();
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.alterTable("users", (table) => {
    table.dropColumn("trial_ends_at");
    table.dropColumn("is_subscribed");
    table.dropColumn("subscription_status");
  });
}
