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
exports.deleteRecurringTransaction = exports.updateRecurringTransaction = exports.createRecurringTransaction = exports.getRecurringTransactions = void 0;
const db_1 = __importDefault(require("../db/db"));
const rbacUtils_1 = require("../utils/rbacUtils");
const getRecurringTransactions = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const scope = (0, rbacUtils_1.getQueryScope)(req);
        const transactions = yield (0, db_1.default)("recurring_transactions").where(scope);
        res.json(transactions);
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.getRecurringTransactions = getRecurringTransactions;
const createRecurringTransaction = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    try {
        const { type, amount, category_id, account_id, frequency, next_due_date } = req.body;
        const [transaction] = yield (0, db_1.default)("recurring_transactions").insert({
            user_id: (_a = req.user) === null || _a === void 0 ? void 0 : _a.id,
            type,
            amount,
            category_id,
            account_id,
            frequency,
            next_due_date
        }).returning("*");
        res.status(201).json(transaction);
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.createRecurringTransaction = createRecurringTransaction;
const updateRecurringTransaction = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    try {
        const { id } = req.params;
        const { type, amount, category_id, account_id, frequency, next_due_date } = req.body;
        const [transaction] = yield (0, db_1.default)("recurring_transactions")
            .where({ id, user_id: (_a = req.user) === null || _a === void 0 ? void 0 : _a.id })
            .update({ type, amount, category_id, account_id, frequency, next_due_date, updated_at: db_1.default.fn.now() })
            .returning("*");
        if (!transaction)
            return res.status(404).json({ error: "Not found" });
        res.json(transaction);
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.updateRecurringTransaction = updateRecurringTransaction;
const deleteRecurringTransaction = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    try {
        const { id } = req.params;
        const deleted = yield (0, db_1.default)("recurring_transactions").where({ id, user_id: (_a = req.user) === null || _a === void 0 ? void 0 : _a.id }).del();
        if (!deleted)
            return res.status(404).json({ error: "Not found" });
        res.json({ success: true });
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.deleteRecurringTransaction = deleteRecurringTransaction;
