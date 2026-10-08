import { Router } from "express";
import { authenticateToken } from "../middleware/auth";
import { getProfile, updateProfile, getDashboardStats, subscribe, deleteAccount } from "../controllers/userController";

const router = Router();

router.use(authenticateToken);

router.get("/profile", getProfile);
router.put("/profile", updateProfile);
router.delete("/profile", deleteAccount);
router.post("/subscribe", subscribe);
router.get("/dashboard", getDashboardStats);

export default router;
