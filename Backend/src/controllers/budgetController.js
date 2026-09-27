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
exports.getBudgetSummary = void 0;
const db_1 = __importDefault(require("../db/db"));
const rbacUtils_1 = require("../utils/rbacUtils");
const getBudgetSummary = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const scope = (0, rbacUtils_1.getQueryScope)(req);
        const userId = scope.user_id;
        const monthStr = req.query.month;
        if (!monthStr || !/^\d{4}-\d{2}$/.test(monthStr)) {
            return res.status(400).json({ error: "Invalid or missing month parameter. Format must be YYYY-MM" });
        }
        const startDate = `${monthStr}-01`;
        // Create an end date for the query (first day of next month)
        const [year, month] = monthStr.split("-").map(Number);
        const nextMonth = month === 12 ? 1 : month + 1;
        const nextYear = month === 12 ? year + 1 : year;
        const endDate = `${nextYear}-${String(nextMonth).padStart(2, "0")}-01`;
        // Fetch budgets for the user for this month
        const budgets = yield (0, db_1.default)("budgets")
            .where(scope)
            .andWhere("month", startDate);
        // Fetch all categories to build the hierarchy
        const categories = yield (0, db_1.default)("categories")
            .where(scope)
            .orWhereNull("user_id");
        // Fetch expenses for the month
        const expenses = yield (0, db_1.default)("transactions")
            .where(scope)
            .andWhere("type", "EXPENSE")
            .andWhere("date", ">=", startDate)
            .andWhere("date", "<", endDate);
        // Group expenses by category_id
        const expensesByCategory = {};
        for (const exp of expenses) {
            if (exp.category_id) {
                expensesByCategory[exp.category_id] = (expensesByCategory[exp.category_id] || 0) + Number(exp.amount);
            }
        }
        // Build subcategories map: parent_id -> array of child ids
        const childCategories = {};
        for (const cat of categories) {
            if (cat.parent_id) {
                if (!childCategories[cat.parent_id]) {
                    childCategories[cat.parent_id] = [];
                }
                childCategories[cat.parent_id].push(cat.id);
            }
        }
        const prevMonth = month === 1 ? 12 : month - 1;
        const prevYear = month === 1 ? year - 1 : year;
        const prevStartDate = `${prevYear}-${String(prevMonth).padStart(2, "0")}-01`;
        const prevBudgets = yield (0, db_1.default)("budgets")
            .where(scope)
            .andWhere("month", prevStartDate)
            .andWhere("rollover_enabled", true);
        const prevExpenses = yield (0, db_1.default)("transactions")
            .where(scope)
            .andWhere("type", "EXPENSE")
            .andWhere("date", ">=", prevStartDate)
            .andWhere("date", "<", startDate);
        const prevExpensesByCategory = {};
        for (const exp of prevExpenses) {
            if (exp.category_id) {
                prevExpensesByCategory[exp.category_id] = (prevExpensesByCategory[exp.category_id] || 0) + Number(exp.amount);
            }
        }
        const summary = budgets.map(budget => {
            let spent = expensesByCategory[budget.category_id] || 0;
            let prevSpent = prevExpensesByCategory[budget.category_id] || 0;
            // Add expenses from subcategories
            const children = childCategories[budget.category_id] || [];
            for (const childId of children) {
                spent += (expensesByCategory[childId] || 0);
                prevSpent += (prevExpensesByCategory[childId] || 0);
            }
            let amount = Number(budget.amount);
            if (budget.rollover_enabled) {
                const prevBudget = prevBudgets.find(b => b.category_id === budget.category_id);
                if (prevBudget) {
                    const prevRemaining = Number(prevBudget.amount) - prevSpent;
                    if (prevRemaining > 0) {
                        amount += prevRemaining;
                    }
                }
            }
            const remaining = amount - spent;
            const usage_percentage = amount > 0 ? (spent / amount) * 100 : 0;
            // Find category details for enrichment
            const category = categories.find(c => c.id === budget.category_id);
            return {
                id: budget.id,
                category_id: budget.category_id,
                category_name: category ? category.name : "Unknown",
                amount,
                spent,
                remaining,
                usage_percentage,
                month: budget.month,
                rollover_enabled: budget.rollover_enabled
            };
        });
        res.json(summary);
    }
    catch (error) {
        console.error("Error fetching budget summary:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.getBudgetSummary = getBudgetSummary;
