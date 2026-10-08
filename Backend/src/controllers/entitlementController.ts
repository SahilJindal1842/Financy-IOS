import { Response } from "express";
import { AuthRequest } from "../middleware/auth";
import { EntitlementService } from "../services/entitlementService";

export const getEntitlement = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const entitlement = await EntitlementService.getEntitlement(userId);
    return res.json(entitlement);
  } catch (error: any) {
    console.error("Error fetching entitlement:", error);
    return res.status(500).json({ error: error.message || "Failed to fetch entitlement" });
  }
};

export const verifyPurchase = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const {
      productId,
      transactionId,
      originalTransactionId,
      purchaseDate,
      environment,
      jwsRepresentation
    } = req.body;

    if (!productId || !transactionId) {
      return res.status(400).json({ error: "Missing required purchase fields (productId, transactionId)" });
    }

    // Supported product IDs
    const allowedProducts = ["com.financy.lifetime", "com.finpilotai.lifetime"];
    if (!allowedProducts.includes(productId)) {
      return res.status(400).json({ error: `Unsupported product ID: ${productId}` });
    }

    const result = await EntitlementService.recordPurchase({
      userId,
      productId,
      transactionId: String(transactionId),
      originalTransactionId: String(originalTransactionId || transactionId),
      purchaseDate: purchaseDate ? new Date(purchaseDate) : new Date(),
      environment: environment || "Xcode",
      jwsRepresentation
    });

    return res.json({
      success: true,
      message: "Purchase verified and entitlement granted",
      entitlement: result
    });
  } catch (error: any) {
    console.error("Error verifying purchase:", error);
    return res.status(500).json({ error: error.message || "Failed to verify purchase" });
  }
};

export const restorePurchases = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const { transactions } = req.body;
    if (Array.isArray(transactions) && transactions.length > 0) {
      for (const tx of transactions) {
        if (tx.productId && tx.transactionId) {
          await EntitlementService.recordPurchase({
            userId,
            productId: tx.productId,
            transactionId: String(tx.transactionId),
            originalTransactionId: String(tx.originalTransactionId || tx.transactionId),
            purchaseDate: tx.purchaseDate ? new Date(tx.purchaseDate) : new Date(),
            environment: tx.environment || "Xcode",
            jwsRepresentation: tx.jwsRepresentation
          });
        }
      }
    }

    const result = await EntitlementService.getEntitlement(userId);
    return res.json({
      success: true,
      message: "Purchases restored",
      entitlement: result
    });
  } catch (error: any) {
    console.error("Error restoring purchases:", error);
    return res.status(500).json({ error: error.message || "Failed to restore purchases" });
  }
};

export const devExpireTrial = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const result = await EntitlementService.setTrialExpiredForDev(userId);
    return res.json({
      success: true,
      message: "Trial expired for development testing",
      entitlement: result
    });
  } catch (error: any) {
    console.error("Error expiring trial:", error);
    return res.status(500).json({ error: error.message || "Failed to expire trial" });
  }
};

export const devResetTrial = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const result = await EntitlementService.resetTrialForDev(userId);
    return res.json({
      success: true,
      message: "Trial reset to 7 days for development testing",
      entitlement: result
    });
  } catch (error: any) {
    console.error("Error resetting trial:", error);
    return res.status(500).json({ error: error.message || "Failed to reset trial" });
  }
};
