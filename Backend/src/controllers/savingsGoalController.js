"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteSavingsGoal = exports.updateSavingsGoal = exports.createSavingsGoal = exports.getSavingsGoals = void 0;
const db_1 = __importDefault(require("../db/db"));
const rbacUtils_1 = require("../utils/rbacUtils");
const getSavingsGoals = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const scope = (0, rbacUtils_1.getQueryScope)(req);
        const goals = yield (0, db_1.default)("savings_goals").where(scope);
        res.json(goals);
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.getSavingsGoals = getSavingsGoals;
const createSavingsGoal = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    try {
        const { name, target_amount, current_amount, target_date } = req.body;
        const [goal] = yield (0, db_1.default)("savings_goals").insert({
            user_id: (_a = req.user) === null || _a === void 0 ? void 0 : _a.id,
            name,
            target_amount,
            current_amount: current_amount || 0,
            target_date
        }).returning("*");
        res.status(201).json(goal);
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.createSavingsGoal = createSavingsGoal;
const updateSavingsGoal = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    try {
        const { id } = req.params;
        const { name, target_amount, current_amount, target_date } = req.body;
        const [goal] = yield (0, db_1.default)("savings_goals")
            .where({ id, user_id: (_a = req.user) === null || _a === void 0 ? void 0 : _a.id })
            .update({ name, target_amount, current_amount, target_date, updated_at: db_1.default.fn.now() })
            .returning("*");
        if (!goal)
            return res.status(404).json({ error: "Not found" });
        res.json(goal);
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.updateSavingsGoal = updateSavingsGoal;
const deleteSavingsGoal = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    try {
        const { id } = req.params;
        const deleted = yield (0, db_1.default)("savings_goals").where({ id, user_id: (_a = req.user) === null || _a === void 0 ? void 0 : _a.id }).del();
        if (!deleted)
            return res.status(404).json({ error: "Not found" });
        res.json({ success: true });
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.deleteSavingsGoal = deleteSavingsGoal;
