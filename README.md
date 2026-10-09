# Financy — Personal Finance Management & Wealth Tracking Ecosystem

[![Swift](https://img.shields.io/badge/Swift-5.10%2B-orange?logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0%2B-black?logo=apple&logoColor=white)](https://apple.com/ios)
[![Node.js](https://img.shields.io/badge/Node.js-20%2B-green?logo=node.js&logoColor=white)](https://nodejs.org)
[![Next.js](https://img.shields.io/badge/Next.js-14-black?logo=next.js&logoColor=white)](https://nextjs.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Supabase-blue?logo=postgresql&logoColor=white)](https://supabase.com)
[![Docker](https://img.shields.io/badge/Docker-Production%20Ready-2496ED?logo=docker&logoColor=white)](https://docker.com)

**Financy** is a complete, production-grade financial operating system designed for modern personal finance management, budget enforcement, subscription tracking, and platform administration.

---

## Architecture & Project Structure

The repository is organized into three unified modules:

```text
FinPilotAI/
├── iOS/                       # Native iOS Application
│   └── FinPilotAI/
│       ├── Sources/
│       │   ├── App/           # Lifecycle, Firebase & Root Coordinator
│       │   ├── Core/          # DesignSystem, Dynamic NetworkConfig, Components
│       │   ├── Features/      # Dashboard, Transactions, Budgets, Profile, Auth
│       │   ├── Models/        # Codable Domain & Entitlement Models
│       │   └── Services/      # StoreKit 2 Purchases & Entitlement Manager
│       └── FinancyProducts.storekit
│
├── Backend/                   # RESTful API & Scheduled Daemon
│   ├── src/
│   │   ├── controllers/       # Auth, Admin, Transactions, Budgets, Subscriptions
│   │   ├── db/                # Knex migrations & Supabase connection pool
│   │   ├── jobs/              # Daily recurring bills cron daemon
│   │   ├── middleware/        # JWT Authentication, RBAC, Rate Limiting
│   │   └── utils/             # Nodemailer OTP service, error handling
│   ├── Dockerfile             # Multi-stage production container
│   ├── Procfile               # Cloud deployment process file
│   └── .env.example
│
├── AdminDashboard/            # Super Admin Control Portal
│   ├── src/
│   │   ├── app/               # Next.js 14 App Router routes & streaming loaders
│   │   ├── components/        # PageLoader, ThemeProvider, Sidebar, UI primitives
│   │   └── lib/               # Typed API client & session manager
│   ├── tailwind.config.ts     # Dark mode & typography theme tokens
│   └── .env.example
│
├── render.yaml                # 1-Click Render.com Blueprint
├── railway.json               # Railway.app configuration
└── .gitignore                 # Multi-stack git ignore rules
```

---

## 1. Native iOS Application (`iOS/`)

* **Frameworks:** SwiftUI, Combine, Charts, StoreKit 2, Firebase Auth (Google & Facebook).
* **Key Features:**
  * Dynamic Month-over-Month Cash Flow (Inflow vs Outflow) & Balance Tracking.
  * Real-Time Category Budget Caps with Utilization Gauges and Over-Budget Alerts.
  * Automated Recurring Bills & Subscriptions Calendar.
  * End-of-Month Savings Settlement with Vault Allocation.
  * System/Light/Dark Adaptive Mode with High-Contrast Typography.
  * Native In-App Purchases (Lifetime Premium Unlock) via StoreKit 2.
  * Dynamic `NetworkConfig` with automatic local simulator and production HTTPS fallback.

### Running the iOS App:
1. Open `iOS/FinPilotAI/FinPilotAI.xcodeproj` in Xcode 16+.
2. Select target device **iPhone 16** (Simulator or Physical Device).
3. Press **Cmd + R** to build and run.

---

## 2. Backend API Service (`Backend/`)

* **Frameworks:** Node.js, Express.js 5, TypeScript, Knex.js, PostgreSQL (Supabase Pooler).
* **Security & Production Hardening:**
  * **Helmet:** Strict HTTP security headers with cross-origin asset policy.
  * **Rate Limiting:** IP-based brute-force throttling on authentication endpoints.
  * **Reverse Proxy Trust:** Enabled for cloud balancers (Cloudflare, AWS ALB, Render).
  * **Zero Vulnerabilities:** Fully audited dependencies (`npm audit` clean).
  * **Graceful Shutdown:** `SIGTERM` and `SIGINT` connection drain handling.

### Running Backend Locally:
```bash
cd Backend
npm install
npm run dev           # Hot-reloads at http://localhost:3000
npm run build         # Compiles TypeScript to dist/
npm start             # Runs compiled dist/index.js in production mode
```

---

## 3. Super Admin Dashboard (`AdminDashboard/`)

* **Frameworks:** Next.js 14 (App Router), React, Tailwind CSS, Lucide Icons, Recharts.
* **Features:**
  * Comprehensive User Directory, Account Impersonation & Suspend/Activate Controls.
  * Platform-Wide Transaction Monitoring & Custom Category Management.
  * System Diagnostics (PostgreSQL Connectivity, Migration Status, Node Engine Health).
  * 1-Click CSV Data Exports for Users & Financial Ledgers.
  * Theme Switcher (System, Light, Dark) with glowing Route Loaders.

### Running Admin Dashboard Locally:
```bash
cd AdminDashboard
npm install
npm run dev -- -p 3001 # Launches portal at http://localhost:3001
npm run build          # Builds production bundle (13 optimized routes)
```

---

## 100% Free Cloud Deployment Setup

You can host the entire system completely for **$0/month** using free tiers:

| Component | Free Platform | Plan | Monthly Cost |
| :--- | :--- | :--- | :--- |
| **Database** | [Supabase](https://supabase.com) | Free Tier (500MB Postgres, 50k MAU) | **$0.00** |
| **Backend API** | [Render](https://render.com) | Free Web Service (750 free hrs/mo, SSL) | **$0.00** |
| **Admin Dashboard** | [Vercel](https://vercel.com) | Free Hobby Plan (Next.js Edge CDN, SSL) | **$0.00** |

---

### Step 1: Database (Already Live on Supabase)
Your PostgreSQL database is already configured and running on Supabase:
* Connection String: Available in your Supabase Dashboard (`Database Settings` → `Connection Pooling`).

---

### Step 2: Deploy Backend to Render (Free)
Click the button below to deploy the Express API to Render:

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/SahilJindal1842/Financy-IOS)

1. Sign up/log in at [Render.com](https://render.com) (free, sign in with GitHub).
2. Click **Apply Blueprint** using `render.yaml`.
3. When prompted for `DATABASE_URL`, paste your Supabase PostgreSQL connection string.
4. Your API will build and go live at `https://financy-api.onrender.com` (with automatic SSL and `/health` check).

---

### Step 3: Deploy Admin Dashboard to Vercel (Free)
Click the button below to deploy the Next.js 14 Admin Dashboard to Vercel:

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2FSahilJindal1842%2FFinancy-IOS&root-directory=AdminDashboard&project-name=financy-admin&env=NEXT_PUBLIC_API_URL)

1. Sign up/log in at [Vercel.com](https://vercel.com) (free, sign in with GitHub).
2. It will automatically detect Next.js 14 and the `AdminDashboard/` root directory.
3. In the **Environment Variables** prompt, set:
   * `NEXT_PUBLIC_API_URL`: Your Render backend URL (e.g. `https://financy-api.onrender.com`).
4. Click **Deploy**. Your dashboard will be live on Vercel's global CDN at `https://financy-admin.vercel.app`.

---

## License

All rights reserved © 2026 Sahil Jindal.
