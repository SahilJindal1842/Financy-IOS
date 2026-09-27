"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.enforceOwnership = exports.requireRole = void 0;
const requireRole = (role) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ error: "Unauthorized" });
        }
        if (req.user.role !== role) {
            return res.status(403).json({ error: "Forbidden: insufficient permissions" });
        }
        next();
    };
};
exports.requireRole = requireRole;
const enforceOwnership = (req, res, next) => {
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
exports.enforceOwnership = enforceOwnership;
