import { Router } from "express";
import { getRecurringTransactions, createRecurringTransaction, updateRecurringTransaction, deleteRecurringTransaction } from "../controllers/recurringController";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.use(authenticateToken);

router.get("/", getRecurringTransactions);
router.post("/", createRecurringTransaction);
router.put("/:id", updateRecurringTransaction);
router.delete("/:id", deleteRecurringTransaction);

export default router;
