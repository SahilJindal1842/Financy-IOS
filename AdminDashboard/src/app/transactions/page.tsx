"use client";

import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Receipt,
  Search,
  Trash2,
  RefreshCw,
  TrendingUp,
  TrendingDown,
  DollarSign,
  Download,
  Calendar,
  Filter,
  XCircle,
} from "lucide-react";
import { api, TransactionItem, CategoryItem, User } from "@/lib/api";
import PageLoader from "@/components/PageLoader";

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState<TransactionItem[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [loading, setLoading] = useState(true);

  // Filters: User-wise, Month-wise, Date-wise, Category-wise, Type-wise, Search
  const [userFilter, setUserFilter] = useState("all");
  const [monthFilter, setMonthFilter] = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [specificDate, setSpecificDate] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [typeFilter, setTypeFilter] = useState("all");
  const [search, setSearch] = useState("");

  const loadData = async () => {
    setLoading(true);
    try {
      const [txs, userList, catList] = await Promise.all([
        api.getTransactions({
          user_id: userFilter === "all" ? undefined : userFilter,
          category_id: categoryFilter === "all" ? undefined : categoryFilter,
          type: typeFilter === "all" ? undefined : typeFilter,
          search: search.trim() || undefined,
          month: monthFilter || undefined,
          start_date: startDate || undefined,
          end_date: endDate || undefined,
          date: specificDate || undefined,
        }),
        api.getUsers(),
        api.getCategories(),
      ]);
      setTransactions(txs);
      setUsers(userList);
      setCategories(catList);
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [userFilter, categoryFilter, typeFilter, monthFilter, startDate, endDate, specificDate]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    loadData();
  };

  const handleResetFilters = () => {
    setUserFilter("all");
    setMonthFilter("");
    setStartDate("");
    setEndDate("");
    setSpecificDate("");
    setCategoryFilter("all");
    setTypeFilter("all");
    setSearch("");
  };

  const applyPreset = (preset: "today" | "this_month" | "last_month" | "all") => {
    const today = new Date();
    const todayStr = today.toISOString().slice(0, 10);
    const thisMonthStr = today.toISOString().slice(0, 7);

    if (preset === "today") {
      setMonthFilter("");
      setStartDate("");
      setEndDate("");
      setSpecificDate(todayStr);
    } else if (preset === "this_month") {
      setSpecificDate("");
      setStartDate("");
      setEndDate("");
      setMonthFilter(thisMonthStr);
    } else if (preset === "last_month") {
      setSpecificDate("");
      setStartDate("");
      setEndDate("");
      const lastMonth = new Date(today.getFullYear(), today.getMonth() - 1, 1);
      setMonthFilter(lastMonth.toISOString().slice(0, 7));
    } else {
      handleResetFilters();
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm("Are you sure you want to delete this transaction?")) return;
    try {
      await api.deleteTransaction(id);
      loadData();
    } catch (err: any) {
      alert("Error deleting transaction: " + err.message);
    }
  };

  const exportCSV = () => {
    if (transactions.length === 0) return;
    const headers = ["ID", "Date", "User", "Email", "Description", "Category", "Type", "Amount"];
    const rows = transactions.map((t) => [
      t.id,
      t.date,
      `"${t.user_name || ""}"`,
      `"${t.user_email || ""}"`,
      `"${t.description || ""}"`,
      `"${t.category_name || ""}"`,
      t.type,
      t.amount,
    ]);
    const csvContent = [headers.join(","), ...rows.map((r) => r.join(","))].join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.setAttribute("download", `transactions_filtered_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  // Aggregated KPIs
  const totalCount = transactions.length;
  let totalExpense = 0;
  let totalIncome = 0;
  for (const t of transactions) {
    const val = Math.abs(Number(t.amount || 0));
    if (t.type === "EXPENSE") totalExpense += val;
    else if (t.type === "INCOME") totalIncome += val;
  }
  const netFlow = totalIncome - totalExpense;

  const formatCurrency = (amt: number) => {
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: "INR",
      maximumFractionDigits: 0,
    }).format(amt);
  };

  if (loading && transactions.length === 0) {
    return (
      <div className="p-8 max-w-7xl mx-auto flex items-center justify-center min-h-[70vh]">
        <PageLoader
          title="Loading Ledger Transactions..."
          subtitle="Fetching verified transaction history, merchants, and categories"
        />
      </div>
    );
  }

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-gray-200 dark:border-slate-800 pb-5">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Transaction Ledger</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Filter transactions user-wise, date-wise, and month-wise across the platform
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={exportCSV}
            className="flex items-center gap-1.5"
            disabled={transactions.length === 0}
          >
            <Download className="h-3.5 w-3.5 text-slate-600 dark:text-slate-300" /> Export CSV
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={loadData}
            disabled={loading}
            className="flex items-center gap-1.5"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${loading ? "animate-spin" : ""}`} /> Refresh
          </Button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold uppercase">Matching Records</p>
              <p className="text-2xl font-bold text-slate-900 dark:text-slate-100 mt-0.5">{totalCount}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-600 dark:text-slate-300">
              <Receipt className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold uppercase">Total Outflow</p>
              <p className="text-2xl font-bold text-rose-600 dark:text-rose-400 mt-0.5">{formatCurrency(totalExpense)}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-rose-50 dark:bg-rose-950/40 flex items-center justify-center text-rose-600 dark:text-rose-400">
              <TrendingDown className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold uppercase">Total Inflow</p>
              <p className="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-0.5">{formatCurrency(totalIncome)}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
              <TrendingUp className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold uppercase">Net Inflow/Outflow</p>
              <p
                className={`text-2xl font-bold mt-0.5 ${
                  netFlow >= 0 ? "text-blue-600 dark:text-blue-400" : "text-rose-600 dark:text-rose-400"
                }`}
              >
                {formatCurrency(netFlow)}
              </p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-blue-50 dark:bg-blue-950/40 flex items-center justify-center text-blue-600 dark:text-blue-400">
              <DollarSign className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Super Admin Filter Panel: User, Month, Date Range, Category, Type */}
      <div className="bg-white dark:bg-slate-900 p-5 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4">
        {/* Quick Presets Bar */}
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 dark:border-slate-800 pb-3">
          <div className="flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300 font-semibold">
            <Filter className="h-3.5 w-3.5 text-emerald-600 dark:text-emerald-400" />
            <span>Quick Timeframes:</span>
            <div className="flex items-center gap-1 ml-2">
              <button
                type="button"
                onClick={() => applyPreset("today")}
                className="px-2.5 py-1 rounded-md text-xs font-medium bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 transition"
              >
                Today
              </button>
              <button
                type="button"
                onClick={() => applyPreset("this_month")}
                className="px-2.5 py-1 rounded-md text-xs font-medium bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 transition"
              >
                This Month
              </button>
              <button
                type="button"
                onClick={() => applyPreset("last_month")}
                className="px-2.5 py-1 rounded-md text-xs font-medium bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 transition"
              >
                Last Month
              </button>
              <button
                type="button"
                onClick={() => applyPreset("all")}
                className="px-2.5 py-1 rounded-md text-xs font-medium bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 transition"
              >
                All Time
              </button>
            </div>
          </div>

          {(userFilter !== "all" || monthFilter || startDate || endDate || specificDate || categoryFilter !== "all" || typeFilter !== "all" || search) && (
            <button
              onClick={handleResetFilters}
              className="text-xs text-rose-600 hover:text-rose-700 font-semibold flex items-center gap-1"
            >
              <XCircle className="h-3.5 w-3.5" /> Clear All Filters
            </button>
          )}
        </div>

        {/* Detailed Filter Inputs */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
          {/* 1. User Filter */}
          <div>
            <label className="text-[11px] font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider block mb-1">
              User Wise
            </label>
            <select
              value={userFilter}
              onChange={(e) => setUserFilter(e.target.value)}
              className="w-full text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-2.5 py-2 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 outline-none"
            >
              <option value="all">All Users</option>
              {users.map((u) => (
                <option key={u.id} value={u.id} className="dark:bg-slate-900">
                  {u.name}
                </option>
              ))}
            </select>
          </div>

          {/* 2. Month-Wise Filter */}
          <div>
            <label className="text-[11px] font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider block mb-1">
              Month Wise
            </label>
            <input
              type="month"
              value={monthFilter}
              onChange={(e) => {
                setMonthFilter(e.target.value);
                setSpecificDate("");
                setStartDate("");
                setEndDate("");
              }}
              className="w-full text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-2.5 py-2 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 outline-none"
            />
          </div>

          {/* 3. Date-Wise: Specific Date */}
          <div>
            <label className="text-[11px] font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider block mb-1">
              Specific Date
            </label>
            <input
              type="date"
              value={specificDate}
              onChange={(e) => {
                setSpecificDate(e.target.value);
                setMonthFilter("");
                setStartDate("");
                setEndDate("");
              }}
              className="w-full text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-2.5 py-2 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 outline-none"
            />
          </div>

          {/* 4. Category Wise */}
          <div>
            <label className="text-[11px] font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider block mb-1">
              Category
            </label>
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="w-full text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-2.5 py-2 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 outline-none"
            >
              <option value="all">All Categories</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id} className="dark:bg-slate-900">
                  {c.name} ({c.type})
                </option>
              ))}
            </select>
          </div>

          {/* 5. Type Wise */}
          <div>
            <label className="text-[11px] font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider block mb-1">
              Type
            </label>
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="w-full text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-2.5 py-2 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 outline-none"
            >
              <option value="all">All Types</option>
              <option value="EXPENSE">Expense Only</option>
              <option value="INCOME">Income Only</option>
            </select>
          </div>
        </div>

        {/* Date Range & Search Row */}
        <form onSubmit={handleSearchSubmit} className="flex flex-col md:flex-row items-center gap-3 pt-1">
          <div className="flex items-center gap-2 w-full md:w-auto">
            <span className="text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase">Range:</span>
            <input
              type="date"
              value={startDate}
              onChange={(e) => {
                setStartDate(e.target.value);
                setMonthFilter("");
                setSpecificDate("");
              }}
              placeholder="Start"
              className="text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-2.5 py-1.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 outline-none"
            />
            <span className="text-xs text-slate-400">to</span>
            <input
              type="date"
              value={endDate}
              onChange={(e) => {
                setEndDate(e.target.value);
                setMonthFilter("");
                setSpecificDate("");
              }}
              placeholder="End"
              className="text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-2.5 py-1.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 outline-none"
            />
          </div>

          <div className="relative flex-1 w-full">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
            <Input
              placeholder="Search description, merchant, notes, user name or email..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9 text-xs"
            />
          </div>

          <Button type="submit" size="sm" className="bg-slate-900 hover:bg-slate-800 dark:bg-emerald-600 dark:hover:bg-emerald-500 text-white text-xs px-4">
            Search
          </Button>
        </form>
      </div>

      {/* Transactions Table */}
      <div className="border border-slate-200 dark:border-slate-800 rounded-xl bg-white dark:bg-slate-900 shadow-sm overflow-hidden">
        <Table>
          <TableHeader className="bg-slate-50 dark:bg-slate-800/60">
            <TableRow>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">Date</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">User</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">Merchant / Description</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">Category</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">Type</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">Amount</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300 text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {transactions.map((tx) => (
              <TableRow key={tx.id} className="hover:bg-slate-50/80 dark:hover:bg-slate-800/50 transition-colors">
                <TableCell className="text-xs text-slate-600 dark:text-slate-400 font-medium">
                  {new Date(tx.date).toLocaleDateString("en-IN", {
                    day: "numeric",
                    month: "short",
                    year: "numeric",
                  })}
                </TableCell>
                <TableCell>
                  <p className="text-xs font-bold text-slate-900 dark:text-white">{tx.user_name || "Unknown"}</p>
                  <p className="text-[11px] text-slate-400">{tx.user_email}</p>
                </TableCell>
                <TableCell>
                  <p className="text-xs font-semibold text-slate-900 dark:text-white">{tx.description}</p>
                  {tx.notes && <p className="text-[11px] text-slate-400">{tx.notes}</p>}
                </TableCell>
                <TableCell className="text-xs font-medium text-slate-700 dark:text-slate-300">
                  {tx.category_name || "Uncategorized"}
                </TableCell>
                <TableCell>
                  <Badge
                    variant="secondary"
                    className={
                      tx.type === "EXPENSE"
                        ? "bg-rose-50 text-rose-700 border-rose-200 dark:bg-rose-950/60 dark:text-rose-300 dark:border-rose-800"
                        : "bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/60 dark:text-emerald-300 dark:border-emerald-800"
                    }
                  >
                    {tx.type}
                  </Badge>
                </TableCell>
                <TableCell
                  className={`text-xs font-bold ${
                    tx.type === "EXPENSE" ? "text-rose-600 dark:text-rose-400" : "text-emerald-600 dark:text-emerald-400"
                  }`}
                >
                  {tx.type === "EXPENSE" ? "-" : "+"}
                  {formatCurrency(Math.abs(Number(tx.amount)))}
                </TableCell>
                <TableCell className="text-right">
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => handleDelete(tx.id)}
                    className="h-8 w-8 text-slate-400 hover:text-rose-600"
                    title="Delete Transaction"
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </TableCell>
              </TableRow>
            ))}

            {transactions.length === 0 && !loading && (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-10 text-slate-500 text-sm">
                  No transactions found matching your criteria.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
