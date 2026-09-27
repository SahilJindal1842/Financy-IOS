"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getQueryScope = void 0;
const getQueryScope = (req) => {
    var _a, _b;
    if (((_a = req.user) === null || _a === void 0 ? void 0 : _a.role) === "ADMIN") {
        if (req.query.user_id) {
            return { user_id: req.query.user_id };
        }
        return {};
    }
    return { user_id: (_b = req.user) === null || _b === void 0 ? void 0 : _b.id };
};
exports.getQueryScope = getQueryScope;
