"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import {
  FileSpreadsheet,
  RefreshCw,
  TrendingUp,
  TrendingDown,
  Layers,
  Users,
} from "lucide-react";
import { api, ReportData, User } from "@/lib/api";
import { PageLoader } from "@/components/PageLoader";

export default function ReportsPage() {
  const [report, setReport] = useState<ReportData | null>(null);
  const [users, setUsers] = useState<User[]>([]);
  const [selectedUserFilter, setSelectedUserFilter] = useState("all");
  const [loading, setLoading] = useState(true);

  const loadReports = async () => {
    setLoading(true);
    try {
      const [data, userList] = await Promise.all([
        api.getReports({
          user_id: selectedUserFilter === "all" ? undefined : selectedUserFilter,
        }),
        api.getUsers(),
      ]);
      setReport(data);
      setUsers(userList);
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadReports();
  }, [selectedUserFilter]);

  const exportAllTransactionsCSV = async () => {
    try {
      const txs = await api.getTransactions({
        user_id: selectedUserFilter === "all" ? undefined : selectedUserFilter,
      });
      if (!txs || txs.length === 0) {
        alert("No transactions available to export.");
        return;
      }
      const headers = ["ID", "Date", "User Name", "User Email", "Type", "Amount", "Category", "Description", "Notes"];
      const rows = txs.map((t) => [
        t.id,
        t.date,
        `"${t.user_name || ""}"`,
        `"${t.user_email || ""}"`,
        t.type,
        t.amount,
        `"${t.category_name || ""}"`,
        `"${t.description || ""}"`,
        `"${t.notes || ""}"`,
      ]);
      const csvContent = [headers.join(","), ...rows.map((r) => r.join(","))].join("\n");
      const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `transactions_${selectedUserFilter}_${Date.now()}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
    } catch (err: any) {
      alert("Failed to export: " + err.message);
    }
  };

  const exportAllUsersCSV = async () => {
    try {
      const uList = await api.getUsers();
      if (!uList || uList.length === 0) {
        alert("No users available to export.");
        return;
      }
      const headers = ["ID", "Name", "Email", "Mobile", "Role", "Status", "Monthly Income", "Currency", "Joined Date"];
      const rows = uList.map((u) => [
        u.id,
        `"${u.name || ""}"`,
        `"${u.email || ""}"`,
        `"${u.mobile_number || ""}"`,
        u.role,
        u.status,
        u.monthly_income,
        u.currency,
        u.created_at,
      ]);
      const csvContent = [headers.join(","), ...rows.map((r) => r.join(","))].join("\n");
      const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `users_directory_${Date.now()}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
    } catch (err: any) {
      alert("Failed to export: " + err.message);
    }
  };

  const formatCurrency = (amt: number) => {
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: "INR",
      maximumFractionDigits: 0,
    }).format(amt);
  };

  const monthlyData = report?.monthlyTrends || [];
  const categoryData = report?.categoryBreakdown || [];

  const totalPeriodIncome = monthlyData.reduce((acc, m) => acc + m.income, 0);
  const totalPeriodExpense = monthlyData.reduce((acc, m) => acc + m.expense, 0);

  if (loading && !report) {
    return (
      <PageLoader
        title="Generating Reports & Analytics..."
        subtitle="Aggregating monthly cashflow, category expenditures, and financial summaries"
      />
    );
  }

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-gray-200 dark:border-slate-800 pb-5">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white">Reports & Analytics</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Historical inflow vs outflow, top category distributions, and data exports
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={exportAllTransactionsCSV}
            className="flex items-center gap-1.5"
          >
            <FileSpreadsheet className="h-4 w-4 text-emerald-600" /> Export Transactions CSV
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={exportAllUsersCSV}
            className="flex items-center gap-1.5"
          >
            <FileSpreadsheet className="h-4 w-4 text-blue-600" /> Export Users CSV
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={loadReports}
            disabled={loading}
            className="flex items-center gap-1.5"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${loading ? "animate-spin" : ""}`} /> Refresh
          </Button>
        </div>
      </div>

      {/* User Wise Filter Bar */}
      <div className="flex items-center gap-3 bg-white dark:bg-slate-900 p-3.5 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
        <label className="text-xs font-bold text-slate-700 dark:text-slate-300 uppercase flex items-center gap-1.5">
          <Users className="h-4 w-4 text-emerald-600" /> Target Analytics Scope:
        </label>
        <select
          value={selectedUserFilter}
          onChange={(e) => setSelectedUserFilter(e.target.value)}
          className="text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-3 py-1.5 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-100 outline-none max-w-md font-medium"
        >
          <option value="all">All Users (Consolidated System Metrics)</option>
          {users.map((u) => (
            <option key={u.id} value={u.id}>
              {u.name} ({u.email || u.mobile_number})
            </option>
          ))}
        </select>
      </div>

      {/* Aggregate Stat Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400">
              Total Inflow (Last 6 Months)
            </CardTitle>
            <TrendingUp className="h-4 w-4 text-emerald-600" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-slate-900 dark:text-white">{formatCurrency(totalPeriodIncome)}</div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
              {selectedUserFilter === "all" ? "Aggregated platform income" : "User total income in period"}
            </p>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400">
              Total Outflow (Last 6 Months)
            </CardTitle>
            <TrendingDown className="h-4 w-4 text-rose-600" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold text-slate-900 dark:text-white">{formatCurrency(totalPeriodExpense)}</div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
              {selectedUserFilter === "all" ? "Aggregated platform spending" : "User total spending in period"}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Monthly Trends Bar Chart */}
      <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
        <CardHeader>
          <CardTitle className="text-base font-bold text-slate-900 dark:text-white">
            Monthly Inflow vs Outflow Comparison
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-[360px] w-full">
            {monthlyData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={monthlyData} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#334155" opacity={0.3} />
                  <XAxis dataKey="month" stroke="#94a3b8" />
                  <YAxis stroke="#94a3b8" />
                  <Tooltip
                    formatter={(value: any) => formatCurrency(Number(value))}
                    contentStyle={{ backgroundColor: "#0f172a", borderColor: "#334155", color: "#fff", borderRadius: "8px" }}
                  />
                  <Legend />
                  <Bar dataKey="income" name="Income (₹)" fill="#10b981" radius={[4, 4, 0, 0]} />
                  <Bar dataKey="expense" name="Expense (₹)" fill="#f43f5e" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-full flex items-center justify-center text-slate-500 dark:text-slate-400 text-sm">
                No monthly transactions recorded for the selected scope.
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Category Breakdown & Exports */}
      <div className="grid gap-6 md:grid-cols-2">
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardHeader>
            <CardTitle className="text-base font-bold text-slate-900 dark:text-white">
              Top Expense Categories
            </CardTitle>
          </CardHeader>
          <CardContent>
            {categoryData.length > 0 ? (
              <div className="space-y-4">
                {categoryData.map((cat, i) => (
                  <div key={i} className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span
                        className="w-3.5 h-3.5 rounded-full"
                        style={{ backgroundColor: cat.color || "#10b981" }}
                      />
                      <span className="text-xs font-bold text-slate-800 dark:text-slate-200">{cat.name}</span>
                    </div>
                    <span className="text-xs font-bold text-slate-900 dark:text-white">
                      {formatCurrency(cat.amount)}
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-slate-500 dark:text-slate-400 py-8 text-center">No categorized expenses.</p>
            )}
          </CardContent>
        </Card>

        {/* Data Exports Card */}
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardHeader>
            <CardTitle className="text-base font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <Layers className="h-5 w-5 text-emerald-600" /> Export Platform Data
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-xs text-slate-600 dark:text-slate-300">
              Generate instant CSV downloads of all financial data stored in PostgreSQL for audits, tax reporting, or offline analysis.
            </p>
            <div className="space-y-2">
              <div className="flex items-center justify-between p-3 border border-slate-200 dark:border-slate-800 rounded-lg bg-slate-50 dark:bg-slate-800/60">
                <div>
                  <p className="text-xs font-bold text-slate-900 dark:text-white">Transactions Export</p>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400">
                    {selectedUserFilter === "all" ? "All users transactions" : "Current user transactions"}
                  </p>
                </div>
                <Button size="sm" onClick={exportAllTransactionsCSV} className="bg-emerald-600 hover:bg-emerald-500 text-xs">
                  Download
                </Button>
              </div>

              <div className="flex items-center justify-between p-3 border border-slate-200 dark:border-slate-800 rounded-lg bg-slate-50 dark:bg-slate-800/60">
                <div>
                  <p className="text-xs font-bold text-slate-900 dark:text-white">Users Directory Export</p>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400">All registered user credentials, roles, and status</p>
                </div>
                <Button size="sm" onClick={exportAllUsersCSV} className="bg-blue-600 hover:bg-blue-500 text-xs">
                  Download
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
