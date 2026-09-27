import { Response } from "express";
import db from "../db/db";
import { AuthRequest } from "../middleware/auth";
import { getQueryScope } from "../utils/rbacUtils";

export const getSavingsGoals = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const goals = await db("savings_goals").where(scope);
    res.json(goals);
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
};

export const createSavingsGoal = async (req: AuthRequest, res: Response) => {
  try {
    const { name, target_amount, current_amount, target_date } = req.body;
    const [goal] = await db("savings_goals").insert({
      user_id: req.user?.id,
      name,
      target_amount,
      current_amount: current_amount || 0,
      target_date
    }).returning("*");
    res.status(201).json(goal);
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
};

export const updateSavingsGoal = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { name, target_amount, current_amount, target_date } = req.body;
    const [goal] = await db("savings_goals")
      .where({ id, user_id: req.user?.id })
      .update({ name, target_amount, current_amount, target_date, updated_at: db.fn.now() })
      .returning("*");
    
    if (!goal) return res.status(404).json({ error: "Not found" });
    res.json(goal);
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
};

export const deleteSavingsGoal = async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const deleted = await db("savings_goals").where({ id, user_id: req.user?.id }).del();
    if (!deleted) return res.status(404).json({ error: "Not found" });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
};
