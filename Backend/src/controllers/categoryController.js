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
exports.getCategories = void 0;
const db_1 = __importDefault(require("../db/db"));
const rbacUtils_1 = require("../utils/rbacUtils");
const getCategories = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const scope = (0, rbacUtils_1.getQueryScope)(req);
        // Fetch global categories (user_id is null) and user-specific categories
        const categories = yield (0, db_1.default)("categories")
            .whereNull("user_id")
            .orWhere(scope);
        // Build tree
        const categoryMap = new Map();
        const roots = [];
        categories.forEach(cat => {
            categoryMap.set(cat.id, Object.assign(Object.assign({}, cat), { subcategories: [] }));
        });
        categories.forEach(cat => {
            const node = categoryMap.get(cat.id);
            if (cat.parent_id) {
                const parent = categoryMap.get(cat.parent_id);
                if (parent) {
                    parent.subcategories.push(node);
                }
                else {
                    // If parent is not found, treat as root
                    roots.push(node);
                }
            }
            else {
                roots.push(node);
            }
        });
        res.json(roots);
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: "Internal server error" });
    }
});
exports.getCategories = getCategories;
