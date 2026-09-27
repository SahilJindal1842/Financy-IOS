import { Response, NextFunction } from "express";
import { AuthRequest } from "./auth";

export const requireRole = (role: string) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized" });
    }
    if (req.user.role !== role) {
      return res.status(403).json({ error: "Forbidden: insufficient permissions" });
    }
    next();
  };
};

export const enforceOwnership = (req: AuthRequest, res: Response, next: NextFunction) => {
  if (!req.user) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  
  if (req.user.role === "ADMIN") {
    return next();
  }
  
  const resourceUserId = req.params.userId || req.params.id; // Check common param names for user IDs

  if (resourceUserId && req.user.id !== resourceUserId) {
    return res.status(403).json({ error: "Forbidden: resource does not belong to user" });
  }
  
  next();
};
