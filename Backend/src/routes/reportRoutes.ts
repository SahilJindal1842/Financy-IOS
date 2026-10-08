import { Router } from "express";
import { getTopSpending, getDailySpending, getMonthlyExpenseReport } from "../controllers/reportController";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.use(authenticateToken);

router.get("/top-spending", getTopSpending);
router.get("/daily-spending", getDailySpending);
router.get("/monthly-expense", getMonthlyExpenseReport);

export default router;
