import { Router } from "express";
import { authenticateToken } from "../middleware/auth";
import { requireRole } from "../middleware/rbac";
import db from "../db/db";

const router = Router();

router.use(authenticateToken);
router.use(requireRole("ADMIN"));

router.get("/users", async (req, res) => {
  try {
    const users = await db("users").select("id", "email", "mobile_number", "name", "role", "status", "created_at");
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
});

export default router;
