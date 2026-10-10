import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  const hasIdentitiesTable = await knex.schema.hasTable("user_identities");
  if (!hasIdentitiesTable) {
    await knex.schema.createTable("user_identities", (table) => {
      table.uuid("id").primary().defaultTo(knex.fn.uuid());
      table.uuid("user_id").notNullable().references("id").inTable("users").onDelete("CASCADE");
      table.string("provider", 50).notNullable(); // 'apple' | 'google' | 'facebook'
      table.string("provider_user_id", 255).notNullable(); // Provider unique user id (sub/id)
      table.string("email", 255).nullable();
      table.string("name", 255).nullable();
      table.text("avatar_url").nullable();
      table.jsonb("raw_profile").nullable();
      table.timestamp("created_at", { useTz: true }).notNullable().defaultTo(knex.fn.now());
      table.timestamp("updated_at", { useTz: true }).notNullable().defaultTo(knex.fn.now());

      table.unique(["provider", "provider_user_id"]);
      table.index(["user_id"]);
      table.index(["provider", "provider_user_id"]);
      table.index(["email"]);
    });
  }

  // Allow password_hash to be nullable for accounts created purely via social authentication
  await knex.schema.alterTable("users", (table) => {
    table.string("password_hash").nullable().alter();
  });
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists("user_identities");
  await knex.schema.alterTable("users", (table) => {
    table.string("password_hash").notNullable().alter();
  });
}
