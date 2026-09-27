import { Router } from "express";
import { getCategories } from "../controllers/categoryController";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.get("/", authenticateToken as any, getCategories as any);

export default router;
