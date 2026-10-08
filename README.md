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

## Cloud Deployment

### 1-Click Deploy to [Render.com](https://render.com)
The included [`render.yaml`](render.yaml) automatically builds and provisions the API service:
1. Connect your repository to **Render**.
2. Select **Blueprint** (`render.yaml`).
3. Set your `DATABASE_URL` environment variable (Supabase connection string).
4. Deploy! Your API will be live at `https://<service-name>.onrender.com`.

---

## License

All rights reserved © 2026 Sahil Jindal.
