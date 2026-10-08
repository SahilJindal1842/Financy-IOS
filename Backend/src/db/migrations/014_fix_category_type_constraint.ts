import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  await knex.raw(`
    ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_type_check;
    ALTER TABLE categories ADD CONSTRAINT categories_type_check CHECK (type IN ('income', 'expense', 'recurring'));
  `);
}

export async function down(knex: Knex): Promise<void> {
  await knex.raw(`
    ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_type_check;
    ALTER TABLE categories ADD CONSTRAINT categories_type_check CHECK (type IN ('income', 'expense'));
  `);
}
