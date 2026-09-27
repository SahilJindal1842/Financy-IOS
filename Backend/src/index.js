"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const authRoutes_1 = __importDefault(require("./routes/authRoutes"));
const transactionRoutes_1 = __importDefault(require("./routes/transactionRoutes"));
const accountRoutes_1 = __importDefault(require("./routes/accountRoutes"));
const categoryRoutes_1 = __importDefault(require("./routes/categoryRoutes"));
const budgetRoutes_1 = __importDefault(require("./routes/budgetRoutes"));
const recurringRoutes_1 = __importDefault(require("./routes/recurringRoutes"));
const savingsGoalRoutes_1 = __importDefault(require("./routes/savingsGoalRoutes"));
const reportRoutes_1 = __importDefault(require("./routes/reportRoutes"));
const insightRoutes_1 = __importDefault(require("./routes/insightRoutes"));
const adminRoutes_1 = __importDefault(require("./routes/adminRoutes"));
dotenv_1.default.config();
const app = (0, express_1.default)();
const port = process.env.PORT || 3000;
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.use("/api/auth", authRoutes_1.default);
app.use("/api/transactions", transactionRoutes_1.default);
app.use("/api/accounts", accountRoutes_1.default);
app.use("/api/categories", categoryRoutes_1.default);
app.use("/api/budgets", budgetRoutes_1.default);
app.use("/api/recurring", recurringRoutes_1.default);
app.use("/api/savings-goals", savingsGoalRoutes_1.default);
app.use("/api/reports", reportRoutes_1.default);
app.use("/api/insights", insightRoutes_1.default);
app.use("/api/admin", adminRoutes_1.default);
app.get("/health", (req, res) => {
    res.json({ status: "ok" });
});
// Global error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(err.status || 500).json({
        error: Object.assign({ message: err.message || "Internal Server Error" }, (process.env.NODE_ENV === "development" && { stack: err.stack })),
    });
});
app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});
exports.default = app;
