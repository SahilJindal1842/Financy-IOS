import { Response } from "express";
import db from "../db/db";
import { AuthRequest } from "../middleware/auth";
import { getQueryScope } from "../utils/rbacUtils";

export const getSavingsGoals = async (req: AuthRequest, res: Response) => {
  try {
    const scope = getQueryScope(req);
    const query = db("savings_goals")
      .leftJoin("users", "savings_goals.user_id", "users.id")
      .whereNull("savings_goals.deleted_at")
      .select(
        "savings_goals.*",
        "users.name as user_name",
        "users.email as user_email"
      );
    if (scope.user_id) {
      query.where("savings_goals.user_id", scope.user_id);
    }
    const goals = await query;
    const formatted = goals.map(g => ({
      id: g.id,
      userId: g.user_id,
      user_id: g.user_id,
      userName: g.user_name || "User",
      user_name: g.user_name || "User",
      userEmail: g.user_email || "",
      user_email: g.user_email || "",
      name: g.name,
      targetAmount: Number(g.target_amount || 0),
      target_amount: Number(g.target_amount || 0),
      currentAmount: Number(g.current_amount || 0),
      current_amount: Number(g.current_amount || 0),
      deadline: g.target_date,
      targetDate: g.target_date,
      target_date: g.target_date,
      createdAt: g.created_at,
      created_at: g.created_at,
      updatedAt: g.updated_at,
      updated_at: g.updated_at
    }));
    res.json(formatted);
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
};

export const createSavingsGoal = async (req: AuthRequest, res: Response) => {
  try {
    const { name, target_amount, targetAmount, current_amount, currentAmount, target_date, deadline, user_id, userId } = req.body;
    const targetUserId = (req.user?.role === "ADMIN" && (user_id || userId)) ? (user_id || userId) : req.user?.id;
    const [goal] = await db("savings_goals").insert({
      user_id: targetUserId,
      name,
      target_amount: target_amount || targetAmount || 0,
      current_amount: current_amount || currentAmount || 0,
      target_date: target_date || deadline
    }).returning("*");
    
    res.status(201).json({
      id: goal.id,
      userId: goal.user_id,
      user_id: goal.user_id,
      name: goal.name,
      targetAmount: Number(goal.target_amount || 0),
      target_amount: Number(goal.target_amount || 0),
      currentAmount: Number(goal.current_amount || 0),
      current_amount: Number(goal.current_amount || 0),
      deadline: goal.target_date,
      targetDate: goal.target_date,
      target_date: goal.target_date,
      createdAt: goal.created_at,
      created_at: goal.created_at,
      updatedAt: goal.updated_at,
      updated_at: goal.updated_at
    });
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
    const deleted = await db("savings_goals").where({ id, user_id: req.user?.id }).update({ deleted_at: db.fn.now() });
    if (!deleted) return res.status(404).json({ error: "Not found" });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: "Internal server error" });
  }
};
