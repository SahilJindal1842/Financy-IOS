import db from "../db/db";

export type EntitlementState = "TRIAL_ACTIVE" | "TRIAL_EXPIRED" | "PREMIUM_ACTIVE";

export interface EntitlementResult {
  entitlement: EntitlementState;
  userId: string;
  isPremium: boolean;
  trial: {
    startDate: string;
    endDate: string;
    daysRemaining: number;
    isExpired: boolean;
    status: string;
  };
  purchase: {
    productId: string;
    transactionId: string;
    originalTransactionId: string;
    purchaseDate: string;
    environment: string;
    status: string;
  } | null;
  serverTime: string;
}

export class EntitlementService {
  static async getEntitlement(userId: string): Promise<EntitlementResult> {
    const user = await db("users").where({ id: userId }).first();
    if (!user) {
      throw new Error("User not found");
    }

    const now = new Date();

    // 1. Check if user is an ADMIN (Admins have permanent full access)
    if (user.role?.toUpperCase() === "ADMIN") {
      return {
        entitlement: "PREMIUM_ACTIVE",
        userId,
        isPremium: true,
        trial: {
          startDate: user.created_at ? new Date(user.created_at).toISOString() : now.toISOString(),
          endDate: now.toISOString(),
          daysRemaining: 0,
          isExpired: false,
          status: "ADMIN_BYPASS"
        },
        purchase: {
          productId: "com.financy.lifetime",
          transactionId: "admin_permanent_entitlement",
          originalTransactionId: "admin_permanent_entitlement",
          purchaseDate: now.toISOString(),
          environment: "Production",
          status: "ADMIN"
        },
        serverTime: now.toISOString()
      };
    }

    // 2. Check for active Lifetime purchase in user_purchases
    const purchase = await db("user_purchases")
      .where({ user_id: userId, product_id: "com.financy.lifetime" })
      .orderBy("created_at", "desc")
      .first();

    if (purchase || user.is_subscribed) {
      return {
        entitlement: "PREMIUM_ACTIVE",
        userId,
        isPremium: true,
        trial: {
          startDate: user.created_at ? new Date(user.created_at).toISOString() : now.toISOString(),
          endDate: user.trial_ends_at ? new Date(user.trial_ends_at).toISOString() : now.toISOString(),
          daysRemaining: 0,
          isExpired: false,
          status: "LIFETIME_PURCHASED"
        },
        purchase: purchase
          ? {
              productId: purchase.product_id,
              transactionId: purchase.transaction_id,
              originalTransactionId: purchase.original_transaction_id,
              purchaseDate: new Date(purchase.purchase_date).toISOString(),
              environment: purchase.environment,
              status: purchase.status
            }
          : {
              productId: "com.financy.lifetime",
              transactionId: `user_${user.id}_legacy`,
              originalTransactionId: `user_${user.id}_legacy`,
              purchaseDate: now.toISOString(),
              environment: "Xcode",
              status: "PURCHASED"
            },
        serverTime: now.toISOString()
      };
    }

    // 3. Check or create server-backed trial in user_trials
    let trial = await db("user_trials").where({ user_id: userId }).first();

    if (!trial) {
      const createdAt = user.created_at ? new Date(user.created_at) : now;
      const trialEnd = new Date(createdAt.getTime() + 7 * 24 * 60 * 60 * 1000);
      const isExpired = now.getTime() >= trialEnd.getTime();
      const status = isExpired ? "EXPIRED" : "ACTIVE";

      [trial] = await db("user_trials")
        .insert({
          user_id: userId,
          trial_start_date: createdAt,
          trial_end_date: trialEnd,
          trial_status: status,
          created_at: now,
          updated_at: now
        })
        .returning("*");
    }

    const trialStart = new Date(trial.trial_start_date);
    const trialEnd = new Date(trial.trial_end_date);
    const msRemaining = trialEnd.getTime() - now.getTime();
    const daysRemaining = Math.max(0, Math.ceil(msRemaining / (1000 * 60 * 60 * 24)));
    const isExpired = msRemaining <= 0;

    // Keep trial_status synchronized in DB
    const expectedStatus = isExpired ? "EXPIRED" : "ACTIVE";
    if (trial.trial_status !== expectedStatus) {
      await db("user_trials")
        .where({ id: trial.id })
        .update({
          trial_status: expectedStatus,
          updated_at: now
        });
    }

    const entitlementState: EntitlementState = isExpired ? "TRIAL_EXPIRED" : "TRIAL_ACTIVE";

    return {
      entitlement: entitlementState,
      userId,
      isPremium: false,
      trial: {
        startDate: trialStart.toISOString(),
        endDate: trialEnd.toISOString(),
        daysRemaining: isExpired ? 0 : daysRemaining,
        isExpired,
        status: expectedStatus
      },
      purchase: null,
      serverTime: now.toISOString()
    };
  }

  static async recordPurchase(params: {
    userId: string;
    productId: string;
    transactionId: string;
    originalTransactionId: string;
    purchaseDate?: string | Date;
    environment?: string;
    jwsRepresentation?: string;
  }): Promise<EntitlementResult> {
    const {
      userId,
      productId,
      transactionId,
      originalTransactionId,
      purchaseDate,
      environment = "Xcode",
      jwsRepresentation
    } = params;

    const now = new Date();
    const pDate = purchaseDate ? new Date(purchaseDate) : now;

    // Idempotent insertion: Check if transaction ID already recorded
    const existing = await db("user_purchases")
      .where({ transaction_id: transactionId })
      .first();

    if (!existing) {
      await db("user_purchases").insert({
        user_id: userId,
        product_id: productId,
        transaction_id: transactionId,
        original_transaction_id: originalTransactionId,
        purchase_date: pDate,
        environment,
        status: "PURCHASED",
        jws_representation: jwsRepresentation || null,
        created_at: now,
        updated_at: now
      });
    }

    // Update user record
    await db("users")
      .where({ id: userId })
      .update({
        is_subscribed: true,
        subscription_status: "ACTIVE_LIFETIME",
        updated_at: now
      });

    return this.getEntitlement(userId);
  }

  // Development helper to expire trial for testing paywall
  static async setTrialExpiredForDev(userId: string): Promise<EntitlementResult> {
    const now = new Date();
    const pastStart = new Date(now.getTime() - 8 * 24 * 60 * 60 * 1000);
    const pastEnd = new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000);

    // Remove any existing purchases so trial state can be tested
    await db("user_purchases").where({ user_id: userId }).delete();
    await db("users").where({ id: userId }).update({ is_subscribed: false, subscription_status: "EXPIRED" });

    const trial = await db("user_trials").where({ user_id: userId }).first();
    if (trial) {
      await db("user_trials").where({ id: trial.id }).update({
        trial_start_date: pastStart,
        trial_end_date: pastEnd,
        trial_status: "EXPIRED",
        updated_at: now
      });
    } else {
      await db("user_trials").insert({
        user_id: userId,
        trial_start_date: pastStart,
        trial_end_date: pastEnd,
        trial_status: "EXPIRED",
        created_at: now,
        updated_at: now
      });
    }

    return this.getEntitlement(userId);
  }

  // Development helper to reset active trial (7 days)
  static async resetTrialForDev(userId: string): Promise<EntitlementResult> {
    const now = new Date();
    const trialEnd = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    await db("user_purchases").where({ user_id: userId }).delete();
    await db("users").where({ id: userId }).update({ is_subscribed: false, subscription_status: "TRIAL" });

    const trial = await db("user_trials").where({ user_id: userId }).first();
    if (trial) {
      await db("user_trials").where({ id: trial.id }).update({
        trial_start_date: now,
        trial_end_date: trialEnd,
        trial_status: "ACTIVE",
        updated_at: now
      });
    } else {
      await db("user_trials").insert({
        user_id: userId,
        trial_start_date: now,
        trial_end_date: trialEnd,
        trial_status: "ACTIVE",
        created_at: now,
        updated_at: now
      });
    }

    return this.getEntitlement(userId);
  }
}
