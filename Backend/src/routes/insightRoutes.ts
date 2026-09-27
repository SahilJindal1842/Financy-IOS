import { Router } from "express";
import { getInsights, getBudgetAlerts } from "../controllers/insightController";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.use(authenticateToken);

router.get("/", getInsights);
router.get("/alerts", getBudgetAlerts);

export default router;
