import { Router } from "express";
import { getAccounts, createAccount } from "../controllers/accountController";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.get("/", authenticateToken as any, getAccounts as any);
router.post("/", authenticateToken as any, createAccount as any);

export default router;
