"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
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
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  ArrowLeft,
  KeyRound,
  Trash2,
  Ban,
  CheckCircle,
  CreditCard,
  PieChart,
  CalendarClock,
  Landmark,
  DollarSign,
  Receipt,
  Filter,
  RefreshCw,
  XCircle,
} from "lucide-react";
import { api, User } from "@/lib/api";
import PageLoader from "@/components/PageLoader";

export default function UserDetailPage() {
  const params = useParams();
  const router = useRouter();
  const userId = params.id as string;

  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // User-specific date & month filters
  const [monthFilter, setMonthFilter] = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");

  // Password reset modal
  const [isResetOpen, setIsResetOpen] = useState(false);
  const [newPassword, setNewPassword] = useState("");

  const loadUserDetails = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await api.getUser(userId, {
        month: monthFilter || undefined,
        start_date: startDate || undefined,
        end_date: endDate || undefined,
      });
      setData(res);
    } catch (err: unknown) {
      if (err instanceof Error) setError(err.message);
      else setError("Failed to fetch user");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (userId) loadUserDetails();
  }, [userId, monthFilter, startDate, endDate]);

  const handleToggleStatus = async () => {
    if (!data?.user) return;
    const nextStatus = data.user.status === "ACTIVE" ? "SUSPENDED" : "ACTIVE";
    try {
      await api.updateUser(userId, { status: nextStatus });
      loadUserDetails();
    } catch (err: any) {
      alert("Error updating status: " + err.message);
    }
  };

  const handleDeleteUser = async () => {
    if (!confirm("Are you sure you want to disable this user account?")) return;
    try {
      await api.deleteUser(userId);
      router.push("/users");
    } catch (err: any) {
      alert("Error deleting user: " + err.message);
    }
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api.resetPassword(userId, newPassword);
      setIsResetOpen(false);
      setNewPassword("");
      alert("Password updated successfully!");
    } catch (err: any) {
      alert("Error: " + err.message);
    }
  };

  const handleDeleteTx = async (txId: string) => {
    if (!confirm("Delete this transaction?")) return;
    try {
      await api.deleteTransaction(txId);
      loadUserDetails();
    } catch (err: any) {
      alert("Error: " + err.message);
    }
  };

  const handleDeleteBudget = async (budgetId: string) => {
    if (!confirm("Delete this budget rule?")) return;
    try {
      await api.deleteBudget(budgetId);
      loadUserDetails();
    } catch (err: any) {
      alert("Error: " + err.message);
    }
  };

  if (loading && !data) {
    return (
      <div className="p-8 max-w-7xl mx-auto flex items-center justify-center min-h-[70vh]">
        <PageLoader
          title="Loading Account Profile..."
          subtitle="Fetching transaction ledger, budget allotments, and recurring bills"
        />
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="p-8 max-w-4xl mx-auto space-y-4">
        <Button variant="outline" size="sm" onClick={() => router.back()}>
          <ArrowLeft className="mr-2 h-4 w-4" /> Back to Users
        </Button>
        <div className="rounded-xl border border-rose-200 bg-rose-50 p-6 text-rose-800">
          {error || "User could not be found."}
        </div>
      </div>
    );
  }

  const { user, recentTransactions, budgets, recurring, accounts, transactionCount } = data;

  const formatCurrency = (amt: number) => {
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: user.currency || "INR",
      maximumFractionDigits: 0,
    }).format(amt);
  };

  // Calculate filtered totals for this user
  let userFilteredExpense = 0;
  let userFilteredIncome = 0;
  for (const t of recentTransactions) {
    const val = Math.abs(Number(t.amount || 0));
    if (t.type === "EXPENSE") userFilteredExpense += val;
    else if (t.type === "INCOME") userFilteredIncome += val;
  }

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-8">
      {/* Top Navigation & Profile Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-gray-200 dark:border-slate-800 pb-6">
        <div className="flex items-center gap-4">
          <Button variant="outline" size="icon" onClick={() => router.back()} className="h-9 w-9">
            <ArrowLeft className="h-4 w-4" />
          </Button>

          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-full bg-slate-900 dark:bg-slate-800 text-white font-bold flex items-center justify-center text-lg shadow border border-transparent dark:border-slate-700">
              {user.name ? user.name.charAt(0).toUpperCase() : "U"}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{user.name}</h1>
                <Badge
                  className={
                    user.role === "ADMIN"
                      ? "bg-purple-100 text-purple-700 dark:bg-purple-950/60 dark:text-purple-300 dark:border-purple-800"
                      : "bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:border-slate-700"
                  }
                >
                  {user.role}
                </Badge>
                <Badge
                  className={
                    user.status === "ACTIVE"
                      ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300 dark:border-emerald-800"
                      : "bg-rose-100 text-rose-700 dark:bg-rose-950/60 dark:text-rose-300 dark:border-rose-800"
                  }
                >
                  {user.status}
                </Badge>
              </div>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                {user.email} {user.mobile_number ? `• ${user.mobile_number}` : ""} • Member since{" "}
                {new Date(user.created_at).toLocaleDateString()}
              </p>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setIsResetOpen(true)}
            className="flex items-center gap-1.5"
          >
            <KeyRound className="h-3.5 w-3.5 text-amber-600" /> Reset Password
          </Button>

          <Button
            variant="outline"
            size="sm"
            onClick={handleToggleStatus}
            className={`flex items-center gap-1.5 ${
              user.status === "ACTIVE" ? "text-rose-600" : "text-emerald-600"
            }`}
          >
            {user.status === "ACTIVE" ? (
              <>
                <Ban className="h-3.5 w-3.5" /> Suspend
              </>
            ) : (
              <>
                <CheckCircle className="h-3.5 w-3.5" /> Activate
              </>
            )}
          </Button>

          <Button
            variant="destructive"
            size="sm"
            onClick={handleDeleteUser}
            className="flex items-center gap-1.5"
          >
            <Trash2 className="h-3.5 w-3.5" /> Disable User
          </Button>
        </div>
      </div>

      {/* Profile Overview Metric Cards */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400">
              Monthly Base Income
            </CardTitle>
            <DollarSign className="h-4 w-4 text-emerald-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-900 dark:text-white">
              {formatCurrency(Number(user.monthly_income || 0))}
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Configured baseline monthly cashflow</p>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400">
              Recorded Transactions
            </CardTitle>
            <Receipt className="h-4 w-4 text-blue-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-900 dark:text-white">{transactionCount}</div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
              Expense: {formatCurrency(userFilteredExpense)} | Inflow: {formatCurrency(userFilteredIncome)}
            </p>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400">
              Active Budgets
            </CardTitle>
            <PieChart className="h-4 w-4 text-purple-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-900 dark:text-white">{budgets.length}</div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Category allocation rules</p>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-xs font-semibold uppercase text-slate-500 dark:text-slate-400">
              Recurring Subscriptions
            </CardTitle>
            <CalendarClock className="h-4 w-4 text-amber-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-900 dark:text-white">{recurring.length}</div>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">Scheduled automated bills</p>
          </CardContent>
        </Card>
      </div>

      {/* Date & Month Filter Toolbar for this specific user */}
      <div className="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-1.5 text-xs text-slate-700 dark:text-slate-300 font-semibold">
            <Filter className="h-3.5 w-3.5 text-emerald-600" />
            <span>Filter User Activity:</span>
          </div>

          <div className="flex items-center gap-2">
            <span className="text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase">Month:</span>
            <input
              type="month"
              value={monthFilter}
              onChange={(e) => {
                setMonthFilter(e.target.value);
                setStartDate("");
                setEndDate("");
              }}
              className="text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-2.5 py-1.5 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-100"
            />
          </div>

          <div className="flex items-center gap-2">
            <span className="text-[11px] font-bold text-slate-500 dark:text-slate-400 uppercase">Range:</span>
            <input
              type="date"
              value={startDate}
              onChange={(e) => {
                setStartDate(e.target.value);
                setMonthFilter("");
              }}
              className="text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-2 py-1 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-100"
            />
            <span className="text-xs text-slate-400">to</span>
            <input
              type="date"
              value={endDate}
              onChange={(e) => {
                setEndDate(e.target.value);
                setMonthFilter("");
              }}
              className="text-xs border border-slate-300 dark:border-slate-700 rounded-lg px-2 py-1 bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-100"
            />
          </div>
        </div>

        <div className="flex items-center gap-2">
          {(monthFilter || startDate || endDate) && (
            <button
              onClick={() => {
                setMonthFilter("");
                setStartDate("");
                setEndDate("");
              }}
              className="text-xs text-rose-600 dark:text-rose-400 hover:text-rose-700 dark:hover:text-rose-300 font-semibold flex items-center gap-1"
            >
              <XCircle className="h-3.5 w-3.5" /> Clear Filters
            </button>
          )}
          <Button variant="outline" size="sm" onClick={loadUserDetails} className="h-8 text-xs">
            <RefreshCw className={`h-3 w-3 mr-1 ${loading ? "animate-spin" : ""}`} /> Refresh
          </Button>
        </div>
      </div>

      {/* Detailed Tabs */}
      <Tabs defaultValue="transactions" className="w-full">
        <TabsList className="bg-slate-100 dark:bg-slate-800/80 p-1 rounded-xl">
          <TabsTrigger value="transactions" className="rounded-lg text-xs font-semibold">
            Transactions ({recentTransactions.length})
          </TabsTrigger>
          <TabsTrigger value="budgets" className="rounded-lg text-xs font-semibold">
            Budgets ({budgets.length})
          </TabsTrigger>
          <TabsTrigger value="recurring" className="rounded-lg text-xs font-semibold">
            Recurring Bills ({recurring.length})
          </TabsTrigger>
          <TabsTrigger value="accounts" className="rounded-lg text-xs font-semibold">
            Accounts ({accounts.length})
          </TabsTrigger>
        </TabsList>

        {/* Transactions Tab */}
        <TabsContent value="transactions" className="mt-6">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-sm">
            <Table>
              <TableHeader className="bg-slate-50 dark:bg-slate-800/60">
                <TableRow>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Date</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Merchant / Description</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Category</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Type</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Amount</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300 text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {recentTransactions.map((tx: any) => (
                  <TableRow key={tx.id}>
                    <TableCell className="text-xs text-slate-600 dark:text-slate-400 font-medium">
                      {new Date(tx.date).toLocaleDateString("en-IN", {
                        day: "numeric",
                        month: "short",
                        year: "numeric",
                      })}
                    </TableCell>
                    <TableCell>
                      <p className="text-xs font-bold text-slate-900 dark:text-white">{tx.description}</p>
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
                        onClick={() => handleDeleteTx(tx.id)}
                        className="h-8 w-8 text-slate-400 hover:text-rose-600"
                        title="Delete Transaction"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}

                {recentTransactions.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center py-8 text-xs text-slate-500 dark:text-slate-400">
                      No transactions recorded for this user under selected filters.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        </TabsContent>

        {/* Budgets Tab */}
        <TabsContent value="budgets" className="mt-6">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-sm">
            <Table>
              <TableHeader className="bg-slate-50 dark:bg-slate-800/60">
                <TableRow>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Category</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Monthly Limit</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Applicable Month</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300 text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {budgets.map((b: any) => (
                  <TableRow key={b.id}>
                    <TableCell className="text-xs font-bold text-slate-900 dark:text-white">
                      {b.category_name || "General"}
                    </TableCell>
                    <TableCell className="text-xs font-bold text-slate-900 dark:text-white">
                      {formatCurrency(Number(b.amount))}
                    </TableCell>
                    <TableCell className="text-xs font-medium text-slate-600 dark:text-slate-400">
                      {b.month ? b.month.slice(0, 7) : "Default"}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleDeleteBudget(b.id)}
                        className="h-8 w-8 text-slate-400 hover:text-rose-600"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}

                {budgets.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={4} className="text-center py-8 text-xs text-slate-500 dark:text-slate-400">
                      No budget limits configured for this user.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        </TabsContent>

        {/* Recurring Bills Tab */}
        <TabsContent value="recurring" className="mt-6">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-sm">
            <Table>
              <TableHeader className="bg-slate-50 dark:bg-slate-800/60">
                <TableRow>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Merchant</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Amount</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Frequency</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Next Due Date</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {recurring.map((rec: any) => (
                  <TableRow key={rec.id}>
                    <TableCell className="text-xs font-bold text-slate-900 dark:text-white">
                      {rec.merchant}
                    </TableCell>
                    <TableCell className="text-xs font-bold text-slate-900 dark:text-white">
                      {formatCurrency(Number(rec.amount))}
                    </TableCell>
                    <TableCell className="text-xs capitalize font-medium text-slate-700 dark:text-slate-300">{rec.frequency}</TableCell>
                    <TableCell className="text-xs text-slate-600 dark:text-slate-400 font-medium">
                      {new Date(rec.next_due_date).toLocaleDateString()}
                    </TableCell>
                    <TableCell>
                      <Badge
                        variant="outline"
                        className={
                          rec.status === "active"
                            ? "bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/60 dark:text-emerald-300 dark:border-emerald-800"
                            : "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-700"
                        }
                      >
                        {rec.status}
                      </Badge>
                    </TableCell>
                  </TableRow>
                ))}

                {recurring.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center py-8 text-xs text-slate-500 dark:text-slate-400">
                      No recurring expenses registered.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        </TabsContent>

        {/* Accounts Tab */}
        <TabsContent value="accounts" className="mt-6">
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-sm">
            <Table>
              <TableHeader className="bg-slate-50 dark:bg-slate-800/60">
                <TableRow>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Account Name</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Type</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Currency</TableHead>
                  <TableHead className="text-xs font-bold text-slate-700 dark:text-slate-300">Created</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {accounts.map((acc: any) => (
                  <TableRow key={acc.id}>
                    <TableCell className="text-xs font-bold text-slate-900 dark:text-white flex items-center gap-2">
                      <Landmark className="h-4 w-4 text-slate-500" />
                      {acc.name}
                    </TableCell>
                    <TableCell className="text-xs uppercase font-medium text-slate-700 dark:text-slate-300">{acc.type}</TableCell>
                    <TableCell className="text-xs font-medium text-slate-600 dark:text-slate-400">{acc.currency_code}</TableCell>
                    <TableCell className="text-xs text-slate-500 dark:text-slate-400">
                      {new Date(acc.created_at).toLocaleDateString()}
                    </TableCell>
                  </TableRow>
                ))}

                {accounts.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={4} className="text-center py-8 text-xs text-slate-500 dark:text-slate-400">
                      No accounts linked.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>
        </TabsContent>
      </Tabs>

      {/* Password Reset Modal */}
      <Dialog open={isResetOpen} onOpenChange={setIsResetOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Reset Password</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleResetPassword} className="space-y-4 pt-2">
            <div>
              <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">New Password</label>
              <Input
                required
                type="password"
                minLength={6}
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="••••••••"
                className="mt-1 text-xs"
              />
            </div>
            <Button type="submit" className="w-full bg-amber-600 hover:bg-amber-500 text-white">
              Update Password
            </Button>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
