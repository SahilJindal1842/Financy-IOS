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
exports.createAccount = exports.getAccounts = void 0;
const db_1 = __importDefault(require("../db/db"));
const rbacUtils_1 = require("../utils/rbacUtils");
const getAccounts = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const scope = (0, rbacUtils_1.getQueryScope)(req);
        // Fetch all accounts for user
        const accounts = yield (0, db_1.default)("accounts").where(scope);
        // Fetch all transactions for user
        const transactions = yield (0, db_1.default)("transactions").where(scope);
        // Calculate balances
        const accountsWithBalances = accounts.map((account) => {
            let balance = 0;
            for (const tx of transactions) {
                const amount = Number(tx.amount);
                if (tx.account_id === account.id) {
                    if (tx.type === "INCOME")
                        balance += amount;
                    if (tx.type === "EXPENSE")
                        balance -= amount;
                    if (tx.type === "TRANSFER")
                        balance -= amount;
                }
                if (tx.destination_account_id === account.id && tx.type === "TRANSFER") {
                    balance += amount;
                }
            }
            return Object.assign(Object.assign({}, account), { balance });
        });
        res.json(accountsWithBalances);
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.getAccounts = getAccounts;
const createAccount = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    try {
        const { name, type, currency_code } = req.body;
        const [account] = yield (0, db_1.default)("accounts").insert({
            user_id: (_a = req.user) === null || _a === void 0 ? void 0 : _a.id,
            name,
            type,
            currency_code: currency_code || "USD",
        }).returning("*");
        res.status(201).json(Object.assign(Object.assign({}, account), { balance: 0 }));
    }
    catch (error) {
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.createAccount = createAccount;
