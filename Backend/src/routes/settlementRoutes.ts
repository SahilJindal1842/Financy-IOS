import { Router } from "express";
import { authenticateToken } from "../middleware/auth";
import { getSettlementStatus, settleMonth, getSavingsHistory } from "../controllers/settlementController";

const router = Router();

router.get("/status", authenticateToken, getSettlementStatus);
router.post("/settle", authenticateToken, settleMonth);
router.get("/history", authenticateToken, getSavingsHistory);

export default router;
