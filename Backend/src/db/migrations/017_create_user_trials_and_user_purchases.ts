import { Knex } from "knex";

export async function up(knex: Knex): Promise<void> {
  const hasTrialsTable = await knex.schema.hasTable("user_trials");
  if (!hasTrialsTable) {
    await knex.schema.createTable("user_trials", (table) => {
      table.uuid("id").primary().defaultTo(knex.fn.uuid());
      table.uuid("user_id").notNullable().references("id").inTable("users").onDelete("CASCADE");
      table.timestamp("trial_start_date", { useTz: true }).notNullable();
      table.timestamp("trial_end_date", { useTz: true }).notNullable();
      table.string("trial_status", 20).notNullable().defaultTo("ACTIVE"); // 'ACTIVE' | 'EXPIRED'
      table.timestamp("created_at", { useTz: true }).notNullable().defaultTo(knex.fn.now());
      table.timestamp("updated_at", { useTz: true }).notNullable().defaultTo(knex.fn.now());
      table.unique(["user_id"]);
      table.index(["trial_status"]);
    });
  }

  const hasPurchasesTable = await knex.schema.hasTable("user_purchases");
  if (!hasPurchasesTable) {
    await knex.schema.createTable("user_purchases", (table) => {
      table.uuid("id").primary().defaultTo(knex.fn.uuid());
      table.uuid("user_id").notNullable().references("id").inTable("users").onDelete("CASCADE");
      table.string("product_id", 100).notNullable().defaultTo("com.financy.lifetime");
      table.string("transaction_id", 150).notNullable().unique();
      table.string("original_transaction_id", 150).notNullable();
      table.timestamp("purchase_date", { useTz: true }).notNullable().defaultTo(knex.fn.now());
      table.string("environment", 50).notNullable().defaultTo("Xcode"); // 'Xcode' | 'Sandbox' | 'Production'
      table.string("status", 50).notNullable().defaultTo("PURCHASED");
      table.text("jws_representation").nullable();
      table.timestamp("created_at", { useTz: true }).notNullable().defaultTo(knex.fn.now());
      table.timestamp("updated_at", { useTz: true }).notNullable().defaultTo(knex.fn.now());
      table.index(["user_id"]);
      table.index(["product_id"]);
    });
  }

  // Backfill existing users with 7-day trial entitlement
  const hasTrialEndsCol = await knex.schema.hasColumn("users", "trial_ends_at");
  const hasSubscribedCol = await knex.schema.hasColumn("users", "is_subscribed");

  const selectCols = ["id", "created_at", "role"];
  if (hasTrialEndsCol) selectCols.push("trial_ends_at");
  if (hasSubscribedCol) selectCols.push("is_subscribed");

  const users = await knex("users").select(selectCols);
  const now = new Date();

  for (const user of users) {
    const existingTrial = await knex("user_trials").where({ user_id: user.id }).first();
    if (!existingTrial) {
      const createdAt = user.created_at ? new Date(user.created_at) : now;
      let trialEnd = (hasTrialEndsCol && (user as any).trial_ends_at)
        ? new Date((user as any).trial_ends_at)
        : new Date(createdAt.getTime() + 7 * 24 * 60 * 60 * 1000);
      const isExpired = now.getTime() >= trialEnd.getTime();
      const trialStatus = isExpired ? "EXPIRED" : "ACTIVE";

      await knex("user_trials").insert({
        user_id: user.id,
        trial_start_date: createdAt,
        trial_end_date: trialEnd,
        trial_status: trialStatus,
        created_at: now,
        updated_at: now
      });
    }

    // If user already had lifetime subscription in DB, ensure user_purchases record exists
    if (user.is_subscribed) {
      const existingPurchase = await knex("user_purchases").where({ user_id: user.id, product_id: "com.financy.lifetime" }).first();
      if (!existingPurchase) {
        await knex("user_purchases").insert({
          user_id: user.id,
          product_id: "com.financy.lifetime",
          transaction_id: `legacy_${user.id}_lifetime`,
          original_transaction_id: `legacy_${user.id}_lifetime`,
          purchase_date: now,
          environment: "Xcode",
          status: "PURCHASED",
          created_at: now,
          updated_at: now
        });
      }
    }
  }
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists("user_purchases");
  await knex.schema.dropTableIfExists("user_trials");
}
