import { Router } from "express";
import { getCategories, updateCategory } from "../controllers/categoryController";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.get("/", authenticateToken as any, getCategories as any);
router.put("/:id", authenticateToken as any, updateCategory as any);

export default router;
