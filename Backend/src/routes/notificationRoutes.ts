import { Router } from "express";
import { authenticateToken } from "../middleware/auth";
import { getNotifications, markAsRead, deleteNotification } from "../controllers/notificationController";

const router = Router();

router.use(authenticateToken);

router.get("/", getNotifications);
router.patch("/:id/read", markAsRead);
router.delete("/:id", deleteNotification);

export default router;
