import { Router } from "express";
import { getSavingsGoals, createSavingsGoal, updateSavingsGoal, deleteSavingsGoal } from "../controllers/savingsGoalController";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.use(authenticateToken);

router.get("/", getSavingsGoals);
router.post("/", createSavingsGoal);
router.put("/:id", updateSavingsGoal);
router.delete("/:id", deleteSavingsGoal);

export default router;
