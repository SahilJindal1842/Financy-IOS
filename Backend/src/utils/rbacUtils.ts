import { AuthRequest } from "../middleware/auth";

export const getQueryScope = (req: AuthRequest) => {
  if (req.user?.role === "ADMIN") {
    const targetUserId = (req.query?.user_id as string) || (req.body?.user_id as string);
    if (targetUserId && targetUserId !== "all" && targetUserId.trim() !== "") {
      return { user_id: targetUserId.trim() };
    }
    return {};
  }
  return { user_id: req.user?.id };
};
