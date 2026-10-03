import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  const hasAvatar = await knex.schema.hasColumn("users", "avatar");
  if (!hasAvatar) {
    await knex.schema.alterTable("users", (table) => {
      table.text("avatar").nullable();
    });
  }
}

export async function down(knex: Knex): Promise<void> {
  const hasAvatar = await knex.schema.hasColumn("users", "avatar");
  if (hasAvatar) {
    await knex.schema.alterTable("users", (table) => {
      table.dropColumn("avatar");
    });
  }
}
