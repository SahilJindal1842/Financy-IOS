import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  const hasType = await knex.schema.hasColumn('categories', 'type');
  
  if (!hasType) {
    await knex.schema.alterTable('categories', (table) => {
      table.string('type').defaultTo('expense');
    });
  }
}

export async function down(knex: Knex): Promise<void> {
  return knex.schema.alterTable('categories', (table) => {
    table.dropColumn('type');
  });
}
