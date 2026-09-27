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
exports.getBudgetAlerts = exports.getInsights = void 0;
const db_1 = __importDefault(require("../db/db"));
const rbacUtils_1 = require("../utils/rbacUtils");
const getInsights = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    try {
        const scope = (0, rbacUtils_1.getQueryScope)(req);
        const userId = scope.user_id;
        if (!userId && !((_a = req.user) === null || _a === void 0 ? void 0 : _a.role))
            return res.status(401).json({ error: "Unauthorized" });
        const insights = [];
        // Determine current and previous month
        const now = new Date();
        const currentYear = now.getFullYear();
        const currentMonth = now.getMonth() + 1; // 1-12
        const currentMonthStr = `${currentYear}-${String(currentMonth).padStart(2, "0")}`;
        const startOfCurrentMonth = `${currentMonthStr}-01`;
        const prevMonth = currentMonth === 1 ? 12 : currentMonth - 1;
        const prevYear = currentMonth === 1 ? currentYear - 1 : currentYear;
        const prevMonthStr = `${prevYear}-${String(prevMonth).padStart(2, "0")}`;
        const startOfPrevMonth = `${prevMonthStr}-01`;
        const nextMonth = currentMonth === 12 ? 1 : currentMonth + 1;
        const nextYear = currentMonth === 12 ? currentYear + 1 : currentYear;
        const startOfNextMonth = `${nextYear}-${String(nextMonth).padStart(2, "0")}-01`;
        // 1. Check if any budget is > 90% used
        const budgets = yield (0, db_1.default)("budgets")
            .where(scope)
            .andWhere("month", startOfCurrentMonth);
        const categories = yield (0, db_1.default)("categories").where(scope).orWhereNull("user_id");
        const expensesCurrent = yield (0, db_1.default)("transactions")
            .where(scope)
            .andWhere("type", "EXPENSE")
            .andWhere("date", ">=", startOfCurrentMonth)
            .andWhere("date", "<", startOfNextMonth);
        const expensesByCategory = {};
        let totalSpentCurrent = 0;
        for (const exp of expensesCurrent) {
            if (exp.category_id) {
                expensesByCategory[exp.category_id] = (expensesByCategory[exp.category_id] || 0) + Number(exp.amount);
            }
            totalSpentCurrent += Number(exp.amount);
        }
        let totalBudget = 0;
        for (const budget of budgets) {
            const amount = Number(budget.amount);
            totalBudget += amount;
            const spent = expensesByCategory[budget.category_id] || 0;
            if (amount > 0) {
                const percentage = (spent / amount) * 100;
                if (percentage > 90) {
                    const category = categories.find(c => c.id === budget.category_id);
                    const catName = category ? category.name : "A category";
                    insights.push(`${catName} has used ${percentage.toFixed(0)}% of its monthly budget.`);
                }
            }
        }
        // 2. Compare current month spending with previous month
        const expensesPrev = yield (0, db_1.default)("transactions")
            .where(scope)
            .andWhere("type", "EXPENSE")
            .andWhere("date", ">=", startOfPrevMonth)
            .andWhere("date", "<", startOfCurrentMonth);
        const prevExpensesByCategory = {};
        let totalSpentPrev = 0;
        for (const exp of expensesPrev) {
            if (exp.category_id) {
                prevExpensesByCategory[exp.category_id] = (prevExpensesByCategory[exp.category_id] || 0) + Number(exp.amount);
            }
            totalSpentPrev += Number(exp.amount);
        }
        for (const catId of Object.keys(expensesByCategory)) {
            const currentSpent = expensesByCategory[catId];
            const prevSpent = prevExpensesByCategory[catId] || 0;
            if (currentSpent > prevSpent && prevSpent > 0) {
                const diff = currentSpent - prevSpent;
                if (diff > 50) { // arbitrary threshold to avoid noise
                    const category = categories.find(c => String(c.id) === String(catId));
                    const catName = category ? category.name : "a category";
                    insights.push(`You spent $${diff.toFixed(2)} more on ${catName} this month compared to last month.`);
                }
            }
        }
        // 3. Calculate remaining overall budget
        if (totalBudget > 0) {
            const remainingOverall = totalBudget - totalSpentCurrent;
            if (remainingOverall > 0) {
                insights.push(`You have $${remainingOverall.toFixed(2)} remaining in your overall budget.`);
            }
            else {
                insights.push(`You have exceeded your overall budget by $${Math.abs(remainingOverall).toFixed(2)}.`);
            }
        }
        // Return insights
        res.json({ insights });
    }
    catch (error) {
        console.error("Error generating insights:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.getInsights = getInsights;
const getBudgetAlerts = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    try {
        const scope = (0, rbacUtils_1.getQueryScope)(req);
        const userId = scope.user_id;
        if (!userId && !((_a = req.user) === null || _a === void 0 ? void 0 : _a.role))
            return res.status(401).json({ error: "Unauthorized" });
        // Mock alerts
        const alerts = [
            { id: 1, type: 'WARNING', message: 'You are approaching your dining budget limit.' },
            { id: 2, type: 'CRITICAL', message: 'You have exceeded your shopping budget.' }
        ];
        res.json(alerts);
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.getBudgetAlerts = getBudgetAlerts;
