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
import { CalendarClock, Search, RefreshCw, Play, Pause, DollarSign, Layers } from "lucide-react";
import { api, RecurringItem } from "@/lib/api";
import PageLoader from "@/components/PageLoader";

export default function RecurringPage() {
  const [recurring, setRecurring] = useState<RecurringItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await api.getRecurring();
      setRecurring(data);
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleToggleStatus = async (item: RecurringItem) => {
    const nextStatus = item.status === "active" ? "paused" : "active";
    try {
      await api.updateRecurringStatus(item.id, nextStatus);
      loadData();
    } catch (err: any) {
      alert("Error updating status: " + err.message);
    }
  };

  const filtered = recurring.filter((item) => {
    const q = search.toLowerCase();
    const matchesSearch =
      (item.merchant && item.merchant.toLowerCase().includes(q)) ||
      (item.user_name && item.user_name.toLowerCase().includes(q)) ||
      (item.user_email && item.user_email.toLowerCase().includes(q));
    const matchesStatus = statusFilter === "all" || item.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const activeBills = recurring.filter((r) => r.status === "active");
  const totalMonthlyCommitment = activeBills.reduce((acc, r) => {
    const amt = Number(r.amount || 0);
    if (r.frequency === "weekly") return acc + amt * 4;
    if (r.frequency === "yearly") return acc + amt / 12;
    return acc + amt;
  }, 0);

  const formatCurrency = (amt: number) => {
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: "INR",
      maximumFractionDigits: 0,
    }).format(amt);
  };

  if (loading && recurring.length === 0) {
    return (
      <div className="p-8 max-w-7xl mx-auto flex items-center justify-center min-h-[70vh]">
        <PageLoader
          title="Loading Recurring Schedules..."
          subtitle="Compiling automated bills, periodic commitments, and subscription rules"
        />
      </div>
    );
  }

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-gray-200 dark:border-slate-800 pb-5">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Recurring Bills & Subscriptions</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Track automated schedules and recurrent bill commitments across all user accounts
          </p>
        </div>
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

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Active Subscriptions</p>
              <p className="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-0.5">{activeBills.length}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
              <CalendarClock className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Est. Monthly Platform Volume</p>
              <p className="text-2xl font-bold text-slate-900 dark:text-slate-100 mt-0.5">{formatCurrency(totalMonthlyCommitment)}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-blue-50 dark:bg-blue-950/40 flex items-center justify-center text-blue-600 dark:text-blue-400">
              <DollarSign className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Paused Schedules</p>
              <p className="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-0.5">
                {recurring.filter((r) => r.status === "paused").length}
              </p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-amber-50 dark:bg-amber-950/40 flex items-center justify-center text-amber-600 dark:text-amber-400">
              <Layers className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search and Filters */}
      <div className="flex flex-col md:flex-row md:items-center gap-3 bg-white dark:bg-slate-900 p-3.5 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
          <Input
            placeholder="Search merchant, subscriber name or email..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9 text-xs"
          />
        </div>

        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="text-xs border border-slate-300 dark:border-slate-700 rounded-md px-3 py-2 bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-200 outline-none"
        >
          <option value="all">All Statuses</option>
          <option value="active">Active</option>
          <option value="paused">Paused</option>
          <option value="cancelled">Cancelled</option>
        </select>
      </div>

      {/* Table */}
      <div className="border border-slate-200 dark:border-slate-800 rounded-xl bg-white dark:bg-slate-900 shadow-sm overflow-hidden">
        <Table>
          <TableHeader className="bg-slate-50 dark:bg-slate-800/60">
            <TableRow>
              <TableHead className="text-xs font-semibold text-slate-700 dark:text-slate-300">User</TableHead>
              <TableHead className="text-xs font-semibold text-slate-700 dark:text-slate-300">Merchant / Service</TableHead>
              <TableHead className="text-xs font-semibold text-slate-700 dark:text-slate-300">Amount</TableHead>
              <TableHead className="text-xs font-semibold text-slate-700 dark:text-slate-300">Frequency</TableHead>
              <TableHead className="text-xs font-semibold text-slate-700 dark:text-slate-300">Next Due Date</TableHead>
              <TableHead className="text-xs font-semibold text-slate-700 dark:text-slate-300">Status</TableHead>
              <TableHead className="text-xs font-semibold text-slate-700 dark:text-slate-300 text-right">Action</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filtered.map((item) => (
              <TableRow key={item.id} className="hover:bg-slate-50/80 dark:hover:bg-slate-800/50 transition-colors">
                <TableCell>
                  <p className="text-xs font-semibold text-slate-900 dark:text-white">{item.user_name || "Unknown"}</p>
                  <p className="text-[11px] text-slate-400">{item.user_email}</p>
                </TableCell>
                <TableCell className="text-xs font-semibold text-slate-900 dark:text-white">{item.merchant}</TableCell>
                <TableCell className="text-xs font-bold text-slate-900 dark:text-white">
                  {formatCurrency(Number(item.amount))}
                </TableCell>
                <TableCell className="text-xs capitalize text-slate-600 dark:text-slate-300">{item.frequency}</TableCell>
                <TableCell className="text-xs text-slate-500 dark:text-slate-400">
                  {new Date(item.next_due_date).toLocaleDateString("en-IN", {
                    day: "numeric",
                    month: "short",
                    year: "numeric",
                  })}
                </TableCell>
                <TableCell>
                  <Badge
                    variant="outline"
                    className={
                      item.status === "active"
                        ? "bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/60 dark:text-emerald-300 dark:border-emerald-800"
                        : "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400 dark:border-slate-700"
                    }
                  >
                    {item.status}
                  </Badge>
                </TableCell>
                <TableCell className="text-right">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleToggleStatus(item)}
                    className="text-xs h-7 px-2"
                  >
                    {item.status === "active" ? (
                      <>
                        <Pause className="h-3 w-3 mr-1 text-amber-600" /> Pause
                      </>
                    ) : (
                      <>
                        <Play className="h-3 w-3 mr-1 text-emerald-600" /> Resume
                      </>
                    )}
                  </Button>
                </TableCell>
              </TableRow>
            ))}

            {filtered.length === 0 && !loading && (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-10 text-slate-500 text-sm">
                  No recurring items found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
