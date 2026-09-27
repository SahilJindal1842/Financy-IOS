import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  return knex.schema.createTable('recurring_transactions', (table) => {
    table.uuid('id').primary().defaultTo(knex.fn.uuid());
    table.uuid('user_id').references('id').inTable('users').onDelete('CASCADE').notNullable();
    table.string('type').notNullable();
    table.decimal('amount', 12, 2).notNullable();
    table.uuid('category_id').references('id').inTable('categories').onDelete('SET NULL').nullable();
    table.uuid('account_id').references('id').inTable('accounts').onDelete('CASCADE').notNullable();
    table.string('frequency').notNullable();
    table.date('next_due_date').notNullable();
    table.timestamps(true, true);
  });
}

export async function down(knex: Knex): Promise<void> {
  return knex.schema.dropTable('recurring_transactions');
}
