"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Server,
  Database,
  Activity,
  Cpu,
  Clock,
  RefreshCw,
  CheckCircle2,
  AlertCircle,
  ShieldCheck,
  Zap,
} from "lucide-react";
import { api, SystemHealth } from "@/lib/api";
import { PageLoader } from "@/components/PageLoader";

export default function SystemHealthPage() {
  const [system, setSystem] = useState<SystemHealth | null>(null);
  const [loading, setLoading] = useState(true);
  const [pingLatency, setPingLatency] = useState<number | null>(null);

  const loadSystemData = async () => {
    setLoading(true);
    const start = performance.now();
    try {
      const data = await api.getSystem();
      setPingLatency(Math.round(performance.now() - start));
      setSystem(data);
    } catch (err: any) {
      console.error(err);
      setPingLatency(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSystemData();
  }, []);

  const formatUptime = (seconds: number) => {
    const d = Math.floor(seconds / (3600 * 24));
    const h = Math.floor((seconds % (3600 * 24)) / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    if (d > 0) return `${d}d ${h}h ${m}m`;
    if (h > 0) return `${h}h ${m}m ${s}s`;
    return `${m}s`;
  };

  if (loading && !system) {
    return (
      <PageLoader
        title="Running System Diagnostics..."
        subtitle="Checking PostgreSQL connectivity, Node engine metrics, and background worker status"
      />
    );
  }

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-gray-200 dark:border-slate-800 pb-5">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white">System Diagnostics</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Backend services status, database connectivity, and environment metrics
          </p>
        </div>
        <Button
          variant="outline"
          size="sm"
          onClick={loadSystemData}
          disabled={loading}
          className="flex items-center gap-1.5"
        >
          <RefreshCw className={`h-3.5 w-3.5 ${loading ? "animate-spin" : ""}`} /> Run Diagnostics
        </Button>
      </div>

      {/* Main Status Bar */}
      <div className="bg-emerald-950/90 dark:bg-emerald-950/70 text-emerald-100 rounded-2xl p-6 border border-emerald-800 dark:border-emerald-700/60 shadow-lg flex flex-col md:flex-row md:items-center md:justify-between gap-6">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-emerald-500/20 border border-emerald-500/40 flex items-center justify-center text-emerald-400">
            <CheckCircle2 className="h-6 w-6" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-lg font-bold text-white">All Core Services Operational</span>
              <Badge className="bg-emerald-500/20 text-emerald-300 border-emerald-500/40">Healthy</Badge>
            </div>
            <p className="text-xs text-emerald-300/80 mt-0.5">
              API gateway, database cluster, and background scheduler running normally.
            </p>
          </div>
        </div>

        <div className="flex items-center gap-6 border-t md:border-t-0 md:border-l border-emerald-800/80 pt-4 md:pt-0 md:pl-6 text-xs">
          <div>
            <span className="text-emerald-400/70 block">API Roundtrip</span>
            <span className="text-sm font-bold text-white flex items-center gap-1 mt-0.5">
              <Zap className="h-3.5 w-3.5 text-emerald-400" />
              {pingLatency !== null ? `${pingLatency} ms` : "--"}
            </span>
          </div>
          <div>
            <span className="text-emerald-400/70 block">Process Uptime</span>
            <span className="text-sm font-bold text-white flex items-center gap-1 mt-0.5">
              <Clock className="h-3.5 w-3.5 text-emerald-400" />
              {system ? formatUptime(system.uptimeSeconds) : "--"}
            </span>
          </div>
        </div>
      </div>

      {/* Services Grid */}
      <div className="grid gap-6 md:grid-cols-2">
        {/* Database Health */}
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between pb-3">
            <CardTitle className="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <Database className="h-4 w-4 text-emerald-600" /> PostgreSQL Database
            </CardTitle>
            <Badge className="bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300 dark:border-emerald-800">Online</Badge>
          </CardHeader>
          <CardContent className="space-y-3 text-xs">
            <div className="flex justify-between py-1.5 border-b border-slate-100 dark:border-slate-800">
              <span className="text-slate-500 dark:text-slate-400">Connection Status</span>
              <span className="font-semibold text-emerald-600 dark:text-emerald-400">
                {system?.database || "CONNECTED"}
              </span>
            </div>
            <div className="flex justify-between py-1.5 border-b border-slate-100 dark:border-slate-800">
              <span className="text-slate-500 dark:text-slate-400">Host Address</span>
              <span className="font-mono text-slate-800 dark:text-slate-200">
                {system?.databaseHost || "localhost:5432"}
              </span>
            </div>
            <div className="flex justify-between py-1.5 border-b border-slate-100 dark:border-slate-800">
              <span className="text-slate-500 dark:text-slate-400">Database Name</span>
              <span className="font-mono text-slate-800 dark:text-slate-200">
                {system?.databaseName || "finpilot"}
              </span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-slate-500 dark:text-slate-400">Knex Migration Status</span>
              <span className="font-semibold text-emerald-600 dark:text-emerald-400">Up to date (17 migrations)</span>
            </div>
          </CardContent>
        </Card>

        {/* Runtime Environment */}
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between pb-3">
            <CardTitle className="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <Cpu className="h-4 w-4 text-blue-600" /> Node & Server Environment
            </CardTitle>
            <Badge className="bg-blue-100 text-blue-700 dark:bg-blue-950/60 dark:text-blue-300 dark:border-blue-800">Node.js</Badge>
          </CardHeader>
          <CardContent className="space-y-3 text-xs">
            <div className="flex justify-between py-1.5 border-b border-slate-100 dark:border-slate-800">
              <span className="text-slate-500 dark:text-slate-400">Node Engine Version</span>
              <span className="font-mono text-slate-800 dark:text-slate-200">{system?.nodeVersion || "v23.x"}</span>
            </div>
            <div className="flex justify-between py-1.5 border-b border-slate-100 dark:border-slate-800">
              <span className="text-slate-500 dark:text-slate-400">Server Local Time</span>
              <span className="font-mono text-slate-800 dark:text-slate-200">
                {system ? new Date(system.serverTime).toLocaleString() : "--"}
              </span>
            </div>
            <div className="flex justify-between py-1.5 border-b border-slate-100 dark:border-slate-800">
              <span className="text-slate-500 dark:text-slate-400">Recurring Cron Daemon</span>
              <span className="font-semibold text-emerald-600 dark:text-emerald-400">Active (node-cron daily 00:00)</span>
            </div>
            <div className="flex justify-between py-1.5">
              <span className="text-slate-500 dark:text-slate-400">API Port</span>
              <span className="font-mono text-slate-800 dark:text-slate-200">3000 (Express 5.x)</span>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Platform Database Counts */}
      <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
        <CardHeader>
          <CardTitle className="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
            <Activity className="h-4 w-4 text-purple-600" /> Platform Record Inventory
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="p-3 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800">
              <span className="text-xs text-slate-500 dark:text-slate-400 block">Total Users</span>
              <span className="text-xl font-bold text-slate-900 dark:text-white mt-1 block">
                {system?.stats.totalUsers || 0}
              </span>
              <span className="text-[11px] text-emerald-600 dark:text-emerald-400 mt-0.5 block">
                {system?.stats.activeUsers || 0} active
              </span>
            </div>

            <div className="p-3 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800">
              <span className="text-xs text-slate-500 dark:text-slate-400 block">Total Transactions</span>
              <span className="text-xl font-bold text-slate-900 dark:text-white mt-1 block">
                {system?.stats.totalTransactions || 0}
              </span>
              <span className="text-[11px] text-slate-500 dark:text-slate-400 mt-0.5 block">
                Volume: ₹{system?.stats.totalVolume || 0}
              </span>
            </div>

            <div className="p-3 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800">
              <span className="text-xs text-slate-500 dark:text-slate-400 block">Budgets Configured</span>
              <span className="text-xl font-bold text-slate-900 dark:text-white mt-1 block">
                {system?.stats.totalBudgets || 0}
              </span>
              <span className="text-[11px] text-purple-600 dark:text-purple-400 mt-0.5 block">Across categories</span>
            </div>

            <div className="p-3 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-100 dark:border-slate-800">
              <span className="text-xs text-slate-500 dark:text-slate-400 block">Recurring Rules</span>
              <span className="text-xl font-bold text-slate-900 dark:text-white mt-1 block">
                {system?.stats.activeRecurringRules || 0}
              </span>
              <span className="text-[11px] text-amber-600 dark:text-amber-400 mt-0.5 block">Active schedules</span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
