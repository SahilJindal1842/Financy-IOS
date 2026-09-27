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
exports.createTransaction = exports.getTransactions = void 0;
const db_1 = __importDefault(require("../db/db"));
const rbacUtils_1 = require("../utils/rbacUtils");
const zod_1 = require("zod");
const transactionSchema = zod_1.z.object({
    type: zod_1.z.enum(["INCOME", "EXPENSE", "TRANSFER"]),
    amount: zod_1.z.number().positive("Amount must be greater than 0"),
    date: zod_1.z.string().refine((val) => !isNaN(Date.parse(val)), { message: "Invalid date format" }),
    account_id: zod_1.z.string().uuid("Invalid account_id UUID"),
    destination_account_id: zod_1.z.string().uuid("Invalid destination_account_id UUID").optional().nullable(),
    category_id: zod_1.z.string().uuid("Invalid category_id UUID").optional().nullable(),
    description: zod_1.z.string().optional().nullable(),
    notes: zod_1.z.string().optional().nullable()
});
const getTransactions = (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const scope = (0, rbacUtils_1.getQueryScope)(req);
        const transactions = yield (0, db_1.default)("transactions")
            .where(scope)
            .orderBy("date", "desc");
        res.json(transactions);
    }
    catch (error) {
        next(error);
    }
});
exports.getTransactions = getTransactions;
const createTransaction = (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    try {
        const validatedData = transactionSchema.parse(req.body);
        const { type, amount, date, account_id, destination_account_id, category_id, description, notes } = validatedData;
        if (type === "TRANSFER" && (!destination_account_id || destination_account_id === account_id)) {
            res.status(400).json({ error: "Valid destination_account_id is required for transfers" });
            return;
        }
        const [transaction] = yield (0, db_1.default)("transactions").insert({
            user_id: (_a = req.user) === null || _a === void 0 ? void 0 : _a.id,
            type,
            amount,
            date,
            account_id,
            destination_account_id: type === "TRANSFER" ? destination_account_id : null,
            category_id: type === "TRANSFER" ? null : category_id,
            description,
            notes
        }).returning("*");
        res.status(201).json(transaction);
    }
    catch (error) {
        if (error instanceof zod_1.z.ZodError) {
            res.status(400).json({ error: error.errors });
            return;
        }
        next(error);
    }
});
exports.createTransaction = createTransaction;
