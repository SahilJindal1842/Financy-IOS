import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  const hasMerchant = await knex.schema.hasColumn('recurring_transactions', 'merchant');
  
  if (!hasMerchant) {
    await knex.schema.alterTable('recurring_transactions', (table) => {
      table.string('merchant').nullable();
      table.date('start_date').nullable();
      table.date('end_date').nullable();
      table.text('notes').nullable();
      table.integer('reminder_days').defaultTo(3);
      table.boolean('auto_create').defaultTo(true);
      table.string('status').defaultTo('active');
      table.boolean('variable_amount').defaultTo(false);
    });
  }
}

export async function down(knex: Knex): Promise<void> {
  return knex.schema.alterTable('recurring_transactions', (table) => {
    table.dropColumns('merchant', 'start_date', 'end_date', 'notes', 'reminder_days', 'auto_create', 'status', 'variable_amount');
  });
}
