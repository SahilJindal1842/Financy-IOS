import { Router } from "express";
import { getTransactions, createTransaction, deleteTransaction } from "../controllers/transactionController";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.use(authenticateToken as any);
router.get("/", getTransactions as any);
router.post("/", createTransaction as any);
router.delete("/:id", deleteTransaction as any);

export default router;
