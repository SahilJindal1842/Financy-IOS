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
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Plus,
  Trash2,
  PieChart,
  RefreshCw,
  Users,
  Layers,
  Calendar,
  AlertTriangle,
  CheckCircle,
} from "lucide-react";
import { api, BudgetItem, CategoryItem, User } from "@/lib/api";
import PageLoader from "@/components/PageLoader";

export default function BudgetsPage() {
  const [budgets, setBudgets] = useState<BudgetItem[]>([]);
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [users, setUsers] = useState<User[]>([]);

  // Super Admin Filters: User-wise, Month-wise, Category-wise, Status-wise
  const [selectedUserFilter, setSelectedUserFilter] = useState("all");
  const [selectedMonthFilter, setSelectedMonthFilter] = useState(() => {
    return new Date().toISOString().slice(0, 7);
  });
  const [selectedCategoryFilter, setSelectedCategoryFilter] = useState("all");
  const [selectedStatusFilter, setSelectedStatusFilter] = useState("all");

  const [loading, setLoading] = useState(true);

  // Dialog state
  const [isOpen, setIsOpen] = useState(false);
  const [form, setForm] = useState({
    user_id: "",
    category_id: "",
    amount: "",
    month: new Date().toISOString().slice(0, 7) + "-01",
  });
  const [error, setError] = useState<string | null>(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const [budgetList, catList, userList] = await Promise.all([
        api.getBudgets({
          user_id: selectedUserFilter === "all" ? undefined : selectedUserFilter,
          category_id: selectedCategoryFilter === "all" ? undefined : selectedCategoryFilter,
          month: selectedMonthFilter === "all" ? undefined : selectedMonthFilter,
        }),
        api.getCategories(),
        api.getUsers(),
      ]);
      setBudgets(budgetList);
      setCategories(catList);
      setUsers(userList);
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [selectedUserFilter, selectedMonthFilter, selectedCategoryFilter]);

  const handleCreateBudget = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    if (!form.user_id || !form.category_id || !form.amount) {
      setError("Please fill all required fields");
      return;
    }
    try {
      await api.createBudget({
        user_id: form.user_id,
        category_id: form.category_id,
        amount: Number(form.amount),
        month: form.month,
      });
      setIsOpen(false);
      setForm({
        user_id: "",
        category_id: "",
        amount: "",
        month: new Date().toISOString().slice(0, 7) + "-01",
      });
      loadData();
    } catch (err: any) {
      setError(err.message || "Failed to create budget");
    }
  };

  const handleDeleteBudget = async (id: string) => {
    if (!confirm("Are you sure you want to delete this budget rule?")) return;
    try {
      await api.deleteBudget(id);
      loadData();
    } catch (err: any) {
      alert("Error deleting budget: " + err.message);
    }
  };

  // Filter in memory for status
  const filteredBudgets = budgets.filter((b) => {
    if (selectedStatusFilter === "all") return true;
    return b.status === selectedStatusFilter;
  });

  const totalAllocated = filteredBudgets.reduce((acc, b) => acc + Number(b.amount || 0), 0);
  const totalSpent = filteredBudgets.reduce((acc, b) => acc + Number(b.spent_amount || 0), 0);
  const overBudgetCount = filteredBudgets.filter((b) => b.status === "OVER_BUDGET").length;

  const formatCurrency = (amt: number) => {
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: "INR",
      maximumFractionDigits: 0,
    }).format(amt);
  };

  if (loading && budgets.length === 0) {
    return (
      <div className="p-8 max-w-7xl mx-auto flex items-center justify-center min-h-[70vh]">
        <PageLoader
          title="Loading Budget Rules..."
          subtitle="Calculating category limits, expense burn rates, and allowances"
        />
      </div>
    );
  }

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-gray-200 dark:border-slate-800 pb-5">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Budget Analytics & Rules</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            User-wise & Month-wise category expenditure thresholds vs actual burn
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={loadData}
            disabled={loading}
            className="flex items-center gap-1.5"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${loading ? "animate-spin" : ""}`} /> Refresh
          </Button>
          <Button
            onClick={() => setIsOpen(true)}
            className="bg-emerald-600 hover:bg-emerald-500 text-white flex items-center gap-1.5 shadow-sm"
          >
            <Plus className="h-4 w-4" /> Add Budget Limit
          </Button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold uppercase">Total Allocated Limit</p>
              <p className="text-2xl font-bold text-slate-900 dark:text-slate-100 mt-0.5">{formatCurrency(totalAllocated)}</p>
              <p className="text-[11px] text-slate-400 mt-0.5">{filteredBudgets.length} configured rules</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-purple-50 dark:bg-purple-950/40 flex items-center justify-center text-purple-600 dark:text-purple-400">
              <PieChart className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold uppercase">Actual Spend Burn</p>
              <p className="text-2xl font-bold text-rose-600 dark:text-rose-400 mt-0.5">{formatCurrency(totalSpent)}</p>
              <p className="text-[11px] text-slate-400 mt-0.5">
                {totalAllocated > 0
                  ? `${Math.round((totalSpent / totalAllocated) * 100)}% overall utilization`
                  : "0%"}
              </p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-rose-50 dark:bg-rose-950/40 flex items-center justify-center text-rose-600 dark:text-rose-400">
              <Layers className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-semibold uppercase">Over-Budget Alerts</p>
              <p className="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-0.5">{overBudgetCount}</p>
              <p className="text-[11px] text-slate-400 mt-0.5">Exceeded category caps</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-amber-50 dark:bg-amber-950/40 flex items-center justify-center text-amber-600 dark:text-amber-400">
              <AlertTriangle className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Super Admin Comprehensive Filter Bar */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
        {/* User Filter */}
        <div>
          <label className="text-[11px] font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider block mb-1">
            Filter By User
          </label>
          <select
            value={selectedUserFilter}
            onChange={(e) => setSelectedUserFilter(e.target.value)}
            className="w-full text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-3 py-2 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 outline-none focus:ring-1 focus:ring-emerald-500"
          >
            <option value="all">All Users</option>
            {users.map((u) => (
              <option key={u.id} value={u.id} className="dark:bg-slate-900">
                {u.name} ({u.email || u.mobile_number})
              </option>
            ))}
          </select>
        </div>

        {/* Month Filter */}
        <div>
          <label className="text-[11px] font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider block mb-1">
            Filter By Month
          </label>
          <div className="flex items-center gap-1.5">
            <input
              type="month"
              value={selectedMonthFilter === "all" ? "" : selectedMonthFilter}
              onChange={(e) => setSelectedMonthFilter(e.target.value || "all")}
              className="w-full text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-3 py-2 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 outline-none focus:ring-1 focus:ring-emerald-500"
            />
            {selectedMonthFilter !== "all" && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setSelectedMonthFilter("all")}
                className="text-[10px] text-slate-500 dark:text-slate-400 px-2 h-8"
              >
                All
              </Button>
            )}
          </div>
        </div>

        {/* Category Filter */}
        <div>
          <label className="text-[11px] font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider block mb-1">
            Filter By Category
          </label>
          <select
            value={selectedCategoryFilter}
            onChange={(e) => setSelectedCategoryFilter(e.target.value)}
            className="w-full text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-3 py-2 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 outline-none focus:ring-1 focus:ring-emerald-500"
          >
            <option value="all">All Categories</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id} className="dark:bg-slate-900">
                {c.name}
              </option>
            ))}
          </select>
        </div>

        {/* Status Filter */}
        <div>
          <label className="text-[11px] font-bold text-slate-600 dark:text-slate-400 uppercase tracking-wider block mb-1">
            Filter By Status
          </label>
          <select
            value={selectedStatusFilter}
            onChange={(e) => setSelectedStatusFilter(e.target.value)}
            className="w-full text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-3 py-2 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200 outline-none focus:ring-1 focus:ring-emerald-500"
          >
            <option value="all">All Statuses</option>
            <option value="UNDER">Under Budget (&lt;80%)</option>
            <option value="NEAR_LIMIT">Near Limit (80% - 100%)</option>
            <option value="OVER_BUDGET">Over Budget (&gt;100%)</option>
          </select>
        </div>
      </div>

      {/* Budgets Table */}
      <div className="border border-slate-200 dark:border-slate-800 rounded-xl bg-white dark:bg-slate-900 shadow-sm overflow-hidden">
        <Table>
          <TableHeader className="bg-slate-50 dark:bg-slate-800/60">
            <TableRow>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">User</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">Category</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">Month</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">Budget Limit</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">Actual Spent</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">Burn Utilization</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300">Status</TableHead>
              <TableHead className="font-bold text-slate-700 dark:text-slate-300 text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredBudgets.map((b) => (
              <TableRow key={b.id} className="hover:bg-slate-50/80 dark:hover:bg-slate-800/50 transition-colors">
                <TableCell>
                  <p className="text-xs font-bold text-slate-900 dark:text-white">{b.user_name || "Unknown"}</p>
                  <p className="text-[11px] text-slate-400">{b.user_email}</p>
                </TableCell>
                <TableCell className="text-xs font-semibold text-slate-800 dark:text-slate-200">
                  {b.category_name || "General"}
                </TableCell>
                <TableCell className="text-xs font-medium text-slate-600 dark:text-slate-400">
                  {b.month ? b.month.slice(0, 7) : "Default"}
                </TableCell>
                <TableCell className="text-xs font-bold text-slate-900 dark:text-white">
                  {formatCurrency(Number(b.amount))}
                </TableCell>
                <TableCell className="text-xs font-bold text-slate-700 dark:text-slate-200">
                  {formatCurrency(Number(b.spent_amount || 0))}
                </TableCell>
                <TableCell className="w-48">
                  <div className="space-y-1">
                    <div className="flex justify-between text-[11px] text-slate-600 dark:text-slate-300 font-semibold">
                      <span>{b.percentage_used || 0}%</span>
                      <span>Left: {formatCurrency(Number(b.remaining_amount || 0))}</span>
                    </div>
                    <div className="h-2 w-full bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                      <div
                        className={`h-full rounded-full transition-all duration-300 ${
                          (b.percentage_used || 0) > 100
                            ? "bg-rose-500"
                            : (b.percentage_used || 0) >= 80
                            ? "bg-amber-500"
                            : "bg-emerald-500"
                        }`}
                        style={{ width: `${Math.min(100, b.percentage_used || 0)}%` }}
                      />
                    </div>
                  </div>
                </TableCell>
                <TableCell>
                  <Badge
                    className={
                      b.status === "OVER_BUDGET"
                        ? "bg-rose-100 text-rose-700 border-rose-200"
                        : b.status === "NEAR_LIMIT"
                        ? "bg-amber-100 text-amber-700 border-amber-200"
                        : "bg-emerald-100 text-emerald-700 border-emerald-200"
                    }
                  >
                    {b.status === "OVER_BUDGET"
                      ? "Over Budget"
                      : b.status === "NEAR_LIMIT"
                      ? "Near Limit"
                      : "Under Budget"}
                  </Badge>
                </TableCell>
                <TableCell className="text-right">
                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => handleDeleteBudget(b.id)}
                    className="h-8 w-8 text-slate-400 hover:text-rose-600"
                    title="Delete Budget"
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </TableCell>
              </TableRow>
            ))}

            {filteredBudgets.length === 0 && !loading && (
              <TableRow>
                <TableCell colSpan={8} className="text-center py-10 text-slate-500 text-sm">
                  No budgets found matching the selected user, month, or category.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {/* Modal: Add Budget */}
      <Dialog open={isOpen} onOpenChange={setIsOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Configure User Budget</DialogTitle>
            <DialogDescription>
              Set a monthly spending threshold for a user and category.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleCreateBudget} className="space-y-4 pt-2">
            {error && <div className="text-xs text-rose-600 bg-rose-50 p-2 rounded">{error}</div>}
            <div>
              <label className="text-xs font-semibold text-slate-700">Select User *</label>
              <select
                required
                value={form.user_id}
                onChange={(e) => setForm({ ...form, user_id: e.target.value })}
                className="w-full mt-1 border border-slate-300 rounded-md px-3 py-2 text-xs bg-white text-slate-800"
              >
                <option value="">-- Choose User --</option>
                {users.map((u) => (
                  <option key={u.id} value={u.id}>
                    {u.name} ({u.email || u.mobile_number})
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700">Select Category *</label>
              <select
                required
                value={form.category_id}
                onChange={(e) => setForm({ ...form, category_id: e.target.value })}
                className="w-full mt-1 border border-slate-300 rounded-md px-3 py-2 text-xs bg-white text-slate-800"
              >
                <option value="">-- Choose Category --</option>
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name} ({c.type})
                  </option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold text-slate-700">Monthly Limit Amount *</label>
                <Input
                  required
                  type="number"
                  placeholder="5000"
                  value={form.amount}
                  onChange={(e) => setForm({ ...form, amount: e.target.value })}
                  className="mt-1"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-700">Effective Month</label>
                <Input
                  type="date"
                  value={form.month}
                  onChange={(e) => setForm({ ...form, month: e.target.value })}
                  className="mt-1 text-xs"
                />
              </div>
            </div>

            <Button type="submit" className="w-full bg-emerald-600 hover:bg-emerald-500 text-white mt-2">
              Save Budget Rule
            </Button>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
