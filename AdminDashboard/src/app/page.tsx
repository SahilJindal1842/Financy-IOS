"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Users,
  DollarSign,
  TrendingDown,
  TrendingUp,
  CreditCard,
  PiggyBank,
  RefreshCw,
  Calendar,
  UserCheck,
  ArrowRight,
  Clock,
  Layers,
} from "lucide-react";
import { api, clearAuthSession, DashboardStats, User } from "@/lib/api";
import PageLoader from "@/components/PageLoader";

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [users, setUsers] = useState<User[]>([]);
  const [selectedUserId, setSelectedUserId] = useState<string>("all");
  const [selectedMonth, setSelectedMonth] = useState<string>(() => {
    return new Date().toISOString().slice(0, 7);
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDashboardData = async () => {
    setLoading(true);
    setError(null);
    try {
      const [dashData, userList] = await Promise.all([
        api.getDashboard(selectedMonth, selectedUserId),
        api.getUsers(),
      ]);
      setStats(dashData);
      setUsers(userList);
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError("Failed to load dashboard data");
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, [selectedUserId, selectedMonth]);

  const formatCurrency = (amount: number, curr = stats?.currency || "INR") => {
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: curr,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  if (loading && !stats) {
    return (
      <div className="p-8 max-w-7xl mx-auto flex items-center justify-center min-h-[70vh]">
        <PageLoader
          title="Loading Platform Overview..."
          subtitle="Compiling real-time financial metrics, cashflow, and budgets"
        />
      </div>
    );
  }

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-8">
      {/* Header and Controls */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-gray-200 dark:border-slate-800 pb-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Platform Overview</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Real-time analytics and financial health across all users
          </p>
        </div>

        {/* Global Super Admin Filter Bar */}
        <div className="flex flex-wrap items-center gap-3">
          {/* Quick presets */}
          <div className="flex items-center gap-1 bg-slate-100 dark:bg-slate-800/80 p-1 rounded-lg border border-transparent dark:border-slate-700">
            <button
              type="button"
              onClick={() => setSelectedMonth(new Date().toISOString().slice(0, 7))}
              className={`px-2.5 py-1 rounded-md text-xs font-semibold transition ${
                selectedMonth === new Date().toISOString().slice(0, 7)
                  ? "bg-white dark:bg-slate-900 text-emerald-700 dark:text-emerald-400 shadow-sm"
                  : "text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white"
              }`}
            >
              This Month
            </button>
            <button
              type="button"
              onClick={() => {
                const now = new Date();
                const last = new Date(now.getFullYear(), now.getMonth() - 1, 1);
                setSelectedMonth(last.toISOString().slice(0, 7));
              }}
              className="px-2.5 py-1 rounded-md text-xs font-semibold text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white transition"
            >
              Last Month
            </button>
          </div>

          {/* User Selector Dropdown */}
          <div className="flex items-center gap-1.5 bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-lg px-3 py-1.5 shadow-sm">
            <Users className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
            <select
              value={selectedUserId}
              onChange={(e) => setSelectedUserId(e.target.value)}
              className="text-xs font-semibold text-slate-900 dark:text-slate-100 bg-white dark:bg-slate-900 outline-none cursor-pointer pr-2"
            >
              <option value="all">All Users (Consolidated)</option>
              {users.map((u) => (
                <option key={u.id} value={u.id} className="dark:bg-slate-900">
                  {u.name} ({u.email || u.mobile_number})
                </option>
              ))}
            </select>
          </div>

          {/* Month Selector */}
          <div className="flex items-center gap-1.5 bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-lg px-3 py-1.5 shadow-sm">
            <Calendar className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
            <input
              type="month"
              value={selectedMonth}
              onChange={(e) => setSelectedMonth(e.target.value)}
              className="text-xs font-semibold text-slate-900 dark:text-slate-100 bg-white dark:bg-slate-900 outline-none cursor-pointer"
            />
          </div>

          {/* Refresh Button */}
          <Button
            variant="outline"
            size="sm"
            onClick={fetchDashboardData}
            disabled={loading}
            className="flex items-center gap-1.5 shadow-sm font-semibold text-xs"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${loading ? "animate-spin" : ""}`} />
            Refresh
          </Button>
        </div>
      </div>

      {error && (
        <div className="rounded-xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700 flex flex-wrap items-center justify-between gap-3 shadow-sm">
          <div className="flex items-center gap-2">
            <span className="font-medium">{error}</span>
          </div>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                clearAuthSession();
                window.location.href = "/login";
              }}
              className="text-xs bg-white text-rose-700 border-rose-300 hover:bg-rose-100 font-semibold"
            >
              Sign In Again
            </Button>
            <Button variant="outline" size="sm" onClick={fetchDashboardData} className="text-xs">
              Retry
            </Button>
          </div>
        </div>
      )}

      {/* Target User Banner if specific user selected */}
      {stats && !stats.isConsolidated && (
        <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-4 flex items-center justify-between shadow-sm">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-emerald-600 text-white font-bold flex items-center justify-center text-sm shadow">
              {stats.userName.charAt(0).toUpperCase()}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="font-semibold text-slate-900 dark:text-white">{stats.userName}</span>
                <Badge variant="outline" className="border-emerald-300 text-emerald-700 bg-emerald-100/50 dark:bg-emerald-950/60 dark:text-emerald-300 dark:border-emerald-800">
                  User View
                </Badge>
              </div>
              <span className="text-xs text-slate-500 dark:text-slate-400">{stats.userEmail}</span>
            </div>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setSelectedUserId("all")}
            className="text-xs text-emerald-700 dark:text-emerald-400 hover:text-emerald-800 dark:hover:text-emerald-300"
          >
            Switch to All Users
          </Button>
        </div>
      )}

      {/* KPI Cards */}
      <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {/* Total Income */}
        <Card className="shadow-sm border-slate-200 dark:border-slate-800">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Total Inflow
            </CardTitle>
            <div className="h-8 w-8 rounded-lg bg-emerald-100 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <TrendingUp className="h-4 w-4" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-900 dark:text-white">
              {stats ? formatCurrency(stats.totalIncome) : "--"}
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
              Base: {stats ? formatCurrency(stats.monthlyIncome) : "--"}
            </p>
          </CardContent>
        </Card>

        {/* Total Expenses */}
        <Card className="shadow-sm border-slate-200 dark:border-slate-800">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Total Expenses
            </CardTitle>
            <div className="h-8 w-8 rounded-lg bg-rose-100 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 flex items-center justify-center">
              <TrendingDown className="h-4 w-4" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-900 dark:text-white">
              {stats ? formatCurrency(stats.totalExpenses) : "--"}
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
              Budget: {stats ? formatCurrency(stats.totalBudget) : "--"}
            </p>
          </CardContent>
        </Card>

        {/* Net Balance / Surplus */}
        <Card className="shadow-sm border-slate-200 dark:border-slate-800">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Available Balance
            </CardTitle>
            <div className="h-8 w-8 rounded-lg bg-blue-100 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <DollarSign className="h-4 w-4" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-900 dark:text-white">
              {stats ? formatCurrency(stats.availableMoney) : "--"}
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
              Surplus for {selectedMonth}
            </p>
          </CardContent>
        </Card>

        {/* Accumulated Savings */}
        <Card className="shadow-sm border-slate-200 dark:border-slate-800">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Total Savings Vault
            </CardTitle>
            <div className="h-8 w-8 rounded-lg bg-purple-100 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <PiggyBank className="h-4 w-4" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-900 dark:text-white">
              {stats ? formatCurrency(stats.savings) : "--"}
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
              Accumulated + current month
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Budget Utilization Meter */}
      {stats && stats.totalBudget > 0 && (
        <Card className="shadow-sm border-slate-200 dark:border-slate-800">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <Layers className="h-4 w-4 text-slate-500 dark:text-slate-400" />
                <span className="text-sm font-semibold text-slate-800 dark:text-slate-200">
                  Budget Utilization ({selectedMonth})
                </span>
              </div>
              <span className="text-sm font-bold text-slate-800 dark:text-slate-100">
                {stats.budgetUsedPercentage}% used ({formatCurrency(stats.totalExpenses)} of{" "}
                {formatCurrency(stats.totalBudget)})
              </span>
            </div>
            <div className="h-3 w-full bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all duration-500 rounded-full ${
                  stats.budgetUsedPercentage > 90
                    ? "bg-rose-500"
                    : stats.budgetUsedPercentage > 75
                    ? "bg-amber-500"
                    : "bg-emerald-500"
                }`}
                style={{ width: `${Math.min(100, stats.budgetUsedPercentage)}%` }}
              />
            </div>
            <div className="flex justify-between items-center text-xs text-slate-500 dark:text-slate-400 mt-2">
              <span>Remaining limit: {formatCurrency(stats.remainingBudget)}</span>
              <span>Settlement cycle: {stats.endOfMonthDate}</span>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Main Grid: Recent Transactions & Upcoming Bills */}
      <div className="grid gap-8 lg:grid-cols-3">
        {/* Recent Transactions Table (2 cols) */}
        <div className="lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">Recent Transactions</h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">Live transaction stream across accounts</p>
            </div>
            <Link href="/transactions">
              <Button variant="ghost" size="sm" className="text-emerald-700 dark:text-emerald-400 hover:text-emerald-800 dark:hover:text-emerald-300 text-xs">
                View All <ArrowRight className="ml-1 h-3.5 w-3.5" />
              </Button>
            </Link>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-sm">
            {stats && stats.transactions.length > 0 ? (
              <div className="divide-y divide-slate-100 dark:divide-slate-800">
                {stats.transactions.map((tx) => (
                  <div key={tx.id} className="p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800/60 transition-colors">
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-9 h-9 rounded-xl flex items-center justify-center font-bold text-xs ${
                          tx.type === "expense"
                            ? "bg-rose-50 dark:bg-rose-950/60 text-rose-600 dark:text-rose-400 border border-rose-100 dark:border-rose-900"
                            : "bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900"
                        }`}
                      >
                        <CreditCard className="h-4 w-4" />
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-slate-900 dark:text-white truncate max-w-xs md:max-w-md">
                          {tx.merchant}
                        </p>
                        <p className="text-xs text-slate-500 dark:text-slate-400">
                          {new Date(tx.date).toLocaleDateString("en-IN", {
                            day: "numeric",
                            month: "short",
                            year: "numeric",
                          })}
                          {tx.note ? ` • ${tx.note}` : ""}
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <span
                        className={`text-sm font-bold block ${
                          tx.type === "expense" ? "text-rose-600 dark:text-rose-400" : "text-emerald-600 dark:text-emerald-400"
                        }`}
                      >
                        {tx.type === "expense" ? "-" : "+"}
                        {formatCurrency(Math.abs(tx.amount))}
                      </span>
                      <Badge
                        variant="secondary"
                        className="text-[10px] px-1.5 py-0 uppercase font-semibold"
                      >
                        {tx.type}
                      </Badge>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="p-8 text-center text-sm text-slate-500 dark:text-slate-400">
                No transactions recorded for this period.
              </div>
            )}
          </div>
        </div>

        {/* Upcoming Recurring Bills (1 col) */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-bold text-slate-900 dark:text-slate-100">Upcoming Bills</h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">Active automated subscriptions</p>
            </div>
            <Link href="/recurring">
              <Button variant="ghost" size="sm" className="text-emerald-700 dark:text-emerald-400 hover:text-emerald-800 dark:hover:text-emerald-300 text-xs">
                Manage <ArrowRight className="ml-1 h-3.5 w-3.5" />
              </Button>
            </Link>
          </div>

          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-4 shadow-sm space-y-3">
            {stats && stats.upcomingBills.length > 0 ? (
              stats.upcomingBills.map((bill) => (
                <div
                  key={bill.id}
                  className="p-3 rounded-lg border border-slate-100 dark:border-slate-800 bg-slate-50/60 dark:bg-slate-800/40 hover:bg-slate-50 dark:hover:bg-slate-800/80 transition-colors flex items-center justify-between"
                >
                  <div className="space-y-1">
                    <p className="text-xs font-semibold text-slate-800 dark:text-slate-200">{bill.merchant}</p>
                    {bill.userName && (
                      <span className="text-[11px] text-slate-500 dark:text-slate-400 block">User: {bill.userName}</span>
                    )}
                    <span className="text-[10px] text-slate-400 dark:text-slate-400 flex items-center gap-1">
                      <Clock className="h-3 w-3" /> Due:{" "}
                      {new Date(bill.nextDueDate).toLocaleDateString("en-IN", {
                        day: "numeric",
                        month: "short",
                      })}
                    </span>
                  </div>
                  <div className="text-right">
                    <span className="text-xs font-bold text-slate-900 dark:text-white block">
                      {formatCurrency(bill.amount)}
                    </span>
                    <Badge variant="outline" className="text-[10px] capitalize">
                      {bill.frequency}
                    </Badge>
                  </div>
                </div>
              ))
            ) : (
              <div className="py-8 text-center text-xs text-slate-400">
                No upcoming bills scheduled within next 14 days.
              </div>
            )}
          </div>

          {/* Quick Management Shortcuts */}
          <div className="bg-slate-900 text-white rounded-xl p-5 shadow-sm space-y-3">
            <h3 className="text-sm font-bold flex items-center gap-2 text-emerald-400">
              <UserCheck className="h-4 w-4" /> Quick Admin Operations
            </h3>
            <p className="text-xs text-slate-300">
              Registered users: <strong className="text-white">{users.length}</strong> active members
            </p>
            <div className="grid grid-cols-2 gap-2 pt-1">
              <Link href="/users">
                <Button size="sm" className="w-full bg-slate-800 hover:bg-slate-700 text-xs border border-slate-700">
                  Manage Users
                </Button>
              </Link>
              <Link href="/budgets">
                <Button size="sm" className="w-full bg-slate-800 hover:bg-slate-700 text-xs border border-slate-700">
                  Set Budgets
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
