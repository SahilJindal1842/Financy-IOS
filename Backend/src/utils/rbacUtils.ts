import { AuthRequest } from "../middleware/auth";

export const getQueryScope = (req: AuthRequest) => {
  if (req.user?.role === "ADMIN") {
    if (req.query.user_id) {
      return { user_id: req.query.user_id };
    }
    return {};
  }
  return { user_id: req.user?.id };
};
