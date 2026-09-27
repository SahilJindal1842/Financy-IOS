import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
    await knex.schema.alterTable("transactions", (table) => {
        table.index(["user_id", "date"]);
        table.index(["account_id"]);
    });
}

export async function down(knex: Knex): Promise<void> {
    await knex.schema.alterTable("transactions", (table) => {
        table.dropIndex(["user_id", "date"]);
        table.dropIndex(["account_id"]);
    });
}
