import { Router } from "express";
import { authenticateToken } from "../middleware/auth";
import { getProfile, updateProfile, getDashboardStats } from "../controllers/userController";

const router = Router();

router.use(authenticateToken);

router.get("/profile", getProfile);
router.put("/profile", updateProfile);
router.get("/dashboard", getDashboardStats);

export default router;
