import { Router } from "express";
import { authenticateToken } from "../middleware/auth";
import {
  getEntitlement,
  verifyPurchase,
  restorePurchases,
  devExpireTrial,
  devResetTrial
} from "../controllers/entitlementController";

const router = Router();

// Entitlement status
router.get("/", authenticateToken, getEntitlement);

// StoreKit purchase verification & restore
router.post("/verify", authenticateToken, verifyPurchase);
router.post("/restore", authenticateToken, restorePurchases);

// Development helpers for quick trial testing
router.post("/dev/expire-trial", authenticateToken, devExpireTrial);
router.post("/dev/reset-trial", authenticateToken, devResetTrial);

export default router;
