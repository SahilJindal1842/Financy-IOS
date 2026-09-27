import { Router } from "express";
import { getTopSpending, getDailySpending } from "../controllers/reportController";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.use(authenticateToken);

router.get("/top-spending", getTopSpending);
router.get("/daily-spending", getDailySpending);

export default router;
