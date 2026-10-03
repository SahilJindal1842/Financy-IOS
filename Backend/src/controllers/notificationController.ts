import { Response, NextFunction } from "express";
import { AuthRequest } from "../middleware/auth";
import db from "../db/db";

export const getNotifications = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: "Unauthorized" });
    }
    
    const notifications = await db("notifications")
      .where({ user_id: userId })
      .whereNull("deleted_at")
      .orderBy("created_at", "desc");
      
    res.json(notifications);
  } catch (error) {
    next(error);
  }
};

export const markAsRead = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user?.id;
    const { id } = req.params;
    
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    if (id === "all") {
      await db("notifications")
        .where({ user_id: userId })
        .whereNull("deleted_at")
        .update({ is_read: true });
    } else {
      await db("notifications")
        .where({ id, user_id: userId })
        .whereNull("deleted_at")
        .update({ is_read: true });
    }
    
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
};

export const deleteNotification = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user?.id;
    const { id } = req.params;
    
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    await db("notifications")
      .where({ id, user_id: userId })
      .whereNull("deleted_at")
      .update({ deleted_at: db.fn.now() }); // Using soft delete here too!
      
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
};
