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
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Plus, Trash2, Edit2, Tags, RefreshCw, Layers } from "lucide-react";
import { api, CategoryItem } from "@/lib/api";
import PageLoader from "@/components/PageLoader";

export default function CategoriesPage() {
  const [categories, setCategories] = useState<CategoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [typeFilter, setTypeFilter] = useState("all");

  // Modals
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [editingCat, setEditingCat] = useState<CategoryItem | null>(null);

  const [form, setForm] = useState<{
    name: string;
    type: "expense" | "income";
    icon: string;
    color: string;
  }>({
    name: "",
    type: "expense",
    icon: "tag",
    color: "#10b981",
  });

  const [error, setError] = useState<string | null>(null);

  const loadCategories = async () => {
    setLoading(true);
    try {
      const data = await api.getCategories();
      setCategories(data);
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCategories();
  }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    if (!form.name.trim()) {
      setError("Category name is required");
      return;
    }
    try {
      await api.createCategory(form);
      setIsAddOpen(false);
      setForm({ name: "", type: "expense", icon: "tag", color: "#10b981" });
      loadCategories();
    } catch (err: any) {
      setError(err.message || "Failed to create category");
    }
  };

  const handleUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingCat) return;
    setError(null);
    try {
      await api.updateCategory(editingCat.id, form);
      setEditingCat(null);
      loadCategories();
    } catch (err: any) {
      setError(err.message || "Failed to update category");
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm("Are you sure you want to delete this category?")) return;
    try {
      await api.deleteCategory(id);
      loadCategories();
    } catch (err: any) {
      alert("Error deleting category: " + err.message);
    }
  };

  const filtered = categories.filter((c) => {
    if (typeFilter === "all") return true;
    return c.type === typeFilter;
  });

  const expenseCount = categories.filter((c) => c.type === "expense").length;
  const incomeCount = categories.filter((c) => c.type === "income").length;

  if (loading && categories.length === 0) {
    return (
      <div className="p-8 max-w-7xl mx-auto flex items-center justify-center min-h-[70vh]">
        <PageLoader
          title="Loading Categories..."
          subtitle="Fetching system taxonomy, custom user labels, and color palettes"
        />
      </div>
    );
  }

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-gray-200 dark:border-slate-800 pb-5">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Categories Manager</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Standard and custom expense and income taxonomy
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={loadCategories}
            disabled={loading}
            className="flex items-center gap-1.5"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${loading ? "animate-spin" : ""}`} /> Refresh
          </Button>
          <Button
            onClick={() => {
              setForm({ name: "", type: "expense", icon: "tag", color: "#10b981" });
              setIsAddOpen(true);
            }}
            className="bg-emerald-600 hover:bg-emerald-500 text-white flex items-center gap-1.5"
          >
            <Plus className="h-4 w-4" /> Add Category
          </Button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Total Categories</p>
              <p className="text-2xl font-bold text-slate-900 dark:text-slate-100 mt-0.5">{categories.length}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-600 dark:text-slate-300">
              <Tags className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Expense Categories</p>
              <p className="text-2xl font-bold text-rose-600 dark:text-rose-400 mt-0.5">{expenseCount}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-rose-50 dark:bg-rose-950/40 flex items-center justify-center text-rose-600 dark:text-rose-400">
              <Layers className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Income Categories</p>
              <p className="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-0.5">{incomeCount}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
              <Layers className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filter */}
      <div className="flex items-center gap-3 bg-white dark:bg-slate-900 p-3 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
        <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">Filter Type:</label>
        <select
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="text-xs border border-slate-300 dark:border-slate-700 rounded-md px-3 py-1.5 bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-200 outline-none"
        >
          <option value="all">All Categories</option>
          <option value="expense">Expense Only</option>
          <option value="income">Income Only</option>
        </select>
      </div>

      {/* Categories Table */}
      <div className="border border-slate-200 dark:border-slate-800 rounded-xl bg-white dark:bg-slate-900 shadow-sm overflow-hidden">
        <Table>
          <TableHeader className="bg-slate-50 dark:bg-slate-800/60">
            <TableRow className="border-b border-slate-200 dark:border-slate-800">
              <TableHead className="text-xs font-semibold dark:text-slate-300">Color / Icon</TableHead>
              <TableHead className="text-xs font-semibold dark:text-slate-300">Name</TableHead>
              <TableHead className="text-xs font-semibold dark:text-slate-300">Type</TableHead>
              <TableHead className="text-xs font-semibold dark:text-slate-300">Scope</TableHead>
              <TableHead className="text-xs font-semibold text-right dark:text-slate-300">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filtered.map((cat) => (
              <TableRow key={cat.id} className="hover:bg-slate-50/80 dark:hover:bg-slate-800/50 border-b border-slate-100 dark:border-slate-800 transition-colors">
                <TableCell>
                  <div className="flex items-center gap-2">
                    <span
                      className="w-4 h-4 rounded-full border border-slate-300 dark:border-slate-600 shadow-inner"
                      style={{ backgroundColor: cat.color || "#10b981" }}
                    />
                    <span className="font-mono text-xs text-slate-500 dark:text-slate-400">{cat.icon || "tag"}</span>
                  </div>
                </TableCell>
                <TableCell className="text-xs font-semibold text-slate-900 dark:text-white">{cat.name}</TableCell>
                <TableCell>
                  <Badge
                    variant="secondary"
                    className={
                      cat.type === "expense"
                        ? "bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 uppercase"
                        : "bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 uppercase"
                    }
                  >
                    {cat.type}
                  </Badge>
                </TableCell>
                <TableCell>
                  <Badge variant="outline" className="text-[10px] dark:border-slate-700 dark:text-slate-300">
                    {cat.isSystem ? "System Default" : "User Custom"}
                  </Badge>
                </TableCell>
                <TableCell className="text-right">
                  <div className="flex items-center justify-end gap-1">
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => {
                        setEditingCat(cat);
                        setForm({
                          name: cat.name,
                          type: cat.type,
                          icon: cat.icon || "tag",
                          color: cat.color || "#10b981",
                        });
                      }}
                      className="h-8 w-8 text-slate-600 hover:text-blue-600"
                    >
                      <Edit2 className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleDelete(cat.id)}
                      className="h-8 w-8 text-slate-400 hover:text-rose-600"
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      {/* Add / Edit Dialog */}
      <Dialog
        open={isAddOpen || !!editingCat}
        onOpenChange={(open) => {
          if (!open) {
            setIsAddOpen(false);
            setEditingCat(null);
          }
        }}
      >
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>{editingCat ? "Edit Category" : "Add New Category"}</DialogTitle>
            <DialogDescription>
              Configure category label, classification, icon and color code.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={editingCat ? handleUpdate : handleCreate} className="space-y-4 pt-2">
            {error && <div className="text-xs text-rose-600 bg-rose-50 p-2 rounded">{error}</div>}
            <div>
              <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">Category Name *</label>
              <Input
                required
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="e.g., Dining Out, Groceries, Rent"
                className="mt-1 text-xs dark:bg-slate-900 dark:border-slate-700 dark:text-white"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">Category Type</label>
                <select
                  value={form.type}
                  onChange={(e) => setForm({ ...form, type: e.target.value as any })}
                  className="w-full mt-1 border border-slate-300 dark:border-slate-700 rounded-md px-3 py-2 text-xs bg-white dark:bg-slate-900 text-slate-900 dark:text-white"
                >
                  <option value="expense">Expense</option>
                  <option value="income">Income</option>
                </select>
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">Icon Key</label>
                <Input
                  value={form.icon}
                  onChange={(e) => setForm({ ...form, icon: e.target.value })}
                  placeholder="tag, cart, home, car"
                  className="mt-1 text-xs dark:bg-slate-900 dark:border-slate-700 dark:text-white"
                />
              </div>
            </div>

            <div>
              <label className="text-xs font-semibold text-slate-700 dark:text-slate-300">Accent Color</label>
              <div className="flex items-center gap-3 mt-1">
                <input
                  type="color"
                  value={form.color}
                  onChange={(e) => setForm({ ...form, color: e.target.value })}
                  className="w-10 h-9 p-0 border border-slate-300 dark:border-slate-700 rounded cursor-pointer bg-transparent"
                />
                <Input
                  value={form.color}
                  onChange={(e) => setForm({ ...form, color: e.target.value })}
                  className="text-xs font-mono dark:bg-slate-900 dark:border-slate-700 dark:text-white"
                />
              </div>
            </div>

            <Button type="submit" className="w-full bg-emerald-600 hover:bg-emerald-500 text-white mt-2">
              {editingCat ? "Save Category Changes" : "Create Category"}
            </Button>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
