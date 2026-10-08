import { Router } from "express";
import { getBudgetSummary, setBudget, setBulkBudgets } from "../controllers/budgetController";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.use(authenticateToken as any);
router.get("/summary", getBudgetSummary as any);
router.post("/set", setBudget as any);
router.post("/", setBudget as any);
router.post("/set-bulk", setBulkBudgets as any);

export default router;
