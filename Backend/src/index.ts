import express, { NextFunction, Request, Response } from "express";
import path from "path";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import dotenv from "dotenv";
import { startRecurringJob } from "./jobs/recurringJob";

import authRoutes from "./routes/authRoutes";
import transactionRoutes from "./routes/transactionRoutes";
import accountRoutes from "./routes/accountRoutes";
import categoryRoutes from "./routes/categoryRoutes";
import budgetRoutes from "./routes/budgetRoutes";
import recurringRoutes from "./routes/recurringRoutes";
import savingsGoalRoutes from "./routes/savingsGoalRoutes";
import reportRoutes from "./routes/reportRoutes";
import insightRoutes from "./routes/insightRoutes";
import adminRoutes from "./routes/adminRoutes";
import userRoutes from "./routes/userRoutes";
import notificationRoutes from "./routes/notificationRoutes";
import settlementRoutes from "./routes/settlementRoutes";
import entitlementRoutes from "./routes/entitlementRoutes";
import db from "./db/db";

dotenv.config();
dotenv.config({ path: path.resolve(__dirname, "../.env") });
dotenv.config({ path: path.resolve(__dirname, "../../.env") });
dotenv.config({ path: path.resolve(process.cwd(), ".env") });
dotenv.config({ path: path.resolve(process.cwd(), "Backend/.env") });

const app = express();
const port = process.env.PORT || 3000;

// Enable reverse proxy trust (Cloudflare, AWS ALB, Render, Nginx)
app.set("trust proxy", 1);

// Security Headers
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: "cross-origin" },
  })
);

// Production-ready CORS configuration
const allowedOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(",").map((o) => o.trim())
  : [
      "http://localhost:3000",
      "http://localhost:3001",
      "http://127.0.0.1:3000",
      "http://127.0.0.1:3001",
    ];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow native mobile apps, curl, server-to-server or listed origins
      if (!origin || allowedOrigins.includes("*") || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(null, true);
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Static uploads with cross-origin caching
app.use("/uploads", express.static(path.join(process.cwd(), "uploads"), { maxAge: "7d" }));

// Rate limiter for authentication routes
const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 120, // 120 attempts per 15 min per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many authentication requests. Please try again later." },
});

// Mount Routes
app.use("/api/auth", authRateLimiter, authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/transactions", transactionRoutes);
app.use("/api/accounts", accountRoutes);
app.use("/api/categories", categoryRoutes);
app.use("/api/budgets", budgetRoutes);
app.use("/api/recurring", recurringRoutes);
app.use("/api/savings-goals", savingsGoalRoutes);
app.use("/api/settlement", settlementRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/insights", insightRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/entitlements", entitlementRoutes);
app.use("/api/purchases", entitlementRoutes);

// Health check endpoints for load balancers and orchestrators
app.get("/health", (req: Request, res: Response) => {
  res.status(200).json({
    status: "healthy",
    uptime: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || "development",
  });
});

app.get("/api/health", async (req: Request, res: Response) => {
  let dbStatus = "unknown";
  let dbError = null;
  try {
    await db.raw("SELECT 1");
    dbStatus = "connected";
  } catch (err: any) {
    dbStatus = "error";
    dbError = err.message || String(err);
  }

  res.status(200).json({
    status: dbStatus === "connected" ? "healthy" : "degraded",
    uptime: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || "development",
    database: {
      status: dbStatus,
      error: dbError,
    },
  });
});

// Global error handler
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  if (process.env.NODE_ENV !== "test") {
    console.error(`[Error] ${req.method} ${req.url}:`, err.message || err);
  }
  res.status(err.status || 500).json({
    error: {
      message: err.message || "Internal Server Error",
      ...(process.env.NODE_ENV === "development" && { stack: err.stack }),
    },
  });
});

// Start scheduled background jobs
startRecurringJob();

const server = app.listen(Number(port), "0.0.0.0", () => {
  console.log(`[Financy Server] Running on http://0.0.0.0:${port} (Env: ${process.env.NODE_ENV || "development"})`);
});

// Graceful shutdown handling
const shutdown = (signal: string) => {
  console.log(`[Financy Server] Received ${signal}. Closing gracefully...`);
  server.close(() => {
    console.log("[Financy Server] HTTP server closed.");
    process.exit(0);
  });
};

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));

export default app;
