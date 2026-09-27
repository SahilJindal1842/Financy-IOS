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
exports.getDailySpending = exports.getTopSpending = void 0;
const db_1 = __importDefault(require("../db/db"));
const rbacUtils_1 = require("../utils/rbacUtils");
const getTopSpending = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const scope = (0, rbacUtils_1.getQueryScope)(req);
        const userId = scope.user_id;
        const monthStr = req.query.month;
        if (!monthStr || !/^\d{4}-\d{2}$/.test(monthStr)) {
            return res.status(400).json({ error: "Invalid or missing month parameter. Format must be YYYY-MM" });
        }
        const startDate = `${monthStr}-01`;
        const [year, month] = monthStr.split("-").map(Number);
        const nextMonth = month === 12 ? 1 : month + 1;
        const nextYear = month === 12 ? year + 1 : year;
        const endDate = `${nextYear}-${String(nextMonth).padStart(2, "0")}-01`;
        let query = (0, db_1.default)("transactions")
            .join("categories", "transactions.category_id", "categories.id")
            .andWhere("transactions.type", "EXPENSE")
            .andWhere("transactions.date", ">=", startDate)
            .andWhere("transactions.date", "<", endDate);
        if (userId !== undefined) {
            query = query.where("transactions.user_id", userId);
        }
        const expenses = yield query
            .select("categories.name as category_name")
            .sum("transactions.amount as total_amount")
            .groupBy("categories.id")
            .orderBy("total_amount", "desc")
            .limit(5);
        // Ensure amount is parsed to number if driver returns string
        const formattedExpenses = expenses.map(e => ({
            category_name: e.category_name,
            total_amount: Number(e.total_amount)
        }));
        res.json(formattedExpenses);
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.getTopSpending = getTopSpending;
const getDailySpending = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const scope = (0, rbacUtils_1.getQueryScope)(req);
        const userId = scope.user_id;
        const monthStr = req.query.month;
        if (!monthStr || !/^\d{4}-\d{2}$/.test(monthStr)) {
            return res.status(400).json({ error: "Invalid or missing month parameter. Format must be YYYY-MM" });
        }
        const startDate = `${monthStr}-01`;
        const [year, month] = monthStr.split("-").map(Number);
        const nextMonth = month === 12 ? 1 : month + 1;
        const nextYear = month === 12 ? year + 1 : year;
        const endDate = `${nextYear}-${String(nextMonth).padStart(2, "0")}-01`;
        let query = (0, db_1.default)("transactions")
            .andWhere("type", "EXPENSE")
            .andWhere("date", ">=", startDate)
            .andWhere("date", "<", endDate);
        if (userId !== undefined) {
            query = query.where("user_id", userId);
        }
        const expenses = yield query.select("date", "amount");
        const dailyTotals = {};
        for (const exp of expenses) {
            // Handle date if it's Date object or string
            const dateStr = exp.date instanceof Date ? exp.date.toISOString().split("T")[0] : String(exp.date).split("T")[0];
            dailyTotals[dateStr] = (dailyTotals[dateStr] || 0) + Number(exp.amount);
        }
        const result = Object.entries(dailyTotals)
            .map(([date, total_amount]) => ({ date, total_amount }))
            .sort((a, b) => a.date.localeCompare(b.date));
        res.json(result);
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.getDailySpending = getDailySpending;
