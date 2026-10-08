"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
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
import {
  Users as UsersIcon,
  UserPlus,
  Search,
  KeyRound,
  Edit2,
  Trash2,
  Eye,
  ShieldCheck,
  UserCheck,
  RefreshCw,
  Ban,
  CheckCircle,
} from "lucide-react";
import { api, User } from "@/lib/api";
import PageLoader from "@/components/PageLoader";

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("All");
  const [roleFilter, setRoleFilter] = useState("All");

  // Modals state
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [resettingUser, setResettingUser] = useState<User | null>(null);

  // Form states
  const [formAdd, setFormAdd] = useState({
    name: "",
    email: "",
    password: "",
    role: "USER" as "USER" | "ADMIN",
    status: "ACTIVE" as "ACTIVE" | "PENDING" | "SUSPENDED",
    monthly_income: 0,
    currency: "INR",
    mobile_number: "",
  });

  const [formEdit, setFormEdit] = useState({
    name: "",
    email: "",
    role: "USER" as "USER" | "ADMIN",
    status: "ACTIVE" as "ACTIVE" | "PENDING" | "SUSPENDED" | "DISABLED",
    monthly_income: 0,
    currency: "INR",
    mobile_number: "",
  });

  const [newPassword, setNewPassword] = useState("");
  const [actionError, setActionError] = useState<string | null>(null);
  const [actionSuccess, setActionSuccess] = useState<string | null>(null);

  const loadUsers = async () => {
    setLoading(true);
    setActionError(null);
    try {
      const data = await api.getUsers();
      setUsers(data);
    } catch (err: unknown) {
      if (err instanceof Error) setActionError(err.message);
      else setActionError("Failed to load users");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setActionError(null);
    try {
      await api.createUser(formAdd);
      setIsAddOpen(false);
      setFormAdd({
        name: "",
        email: "",
        password: "",
        role: "USER",
        status: "ACTIVE",
        monthly_income: 0,
        currency: "INR",
        mobile_number: "",
      });
      setActionSuccess("User created successfully!");
      setTimeout(() => setActionSuccess(null), 3000);
      loadUsers();
    } catch (err: any) {
      setActionError(err.message || "Failed to create user");
    }
  };

  const handleUpdateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingUser) return;
    setActionError(null);
    try {
      await api.updateUser(editingUser.id, formEdit);
      setEditingUser(null);
      setActionSuccess("User updated successfully!");
      setTimeout(() => setActionSuccess(null), 3000);
      loadUsers();
    } catch (err: any) {
      setActionError(err.message || "Failed to update user");
    }
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!resettingUser) return;
    setActionError(null);
    try {
      await api.resetPassword(resettingUser.id, newPassword);
      setResettingUser(null);
      setNewPassword("");
      setActionSuccess("Password reset successfully!");
      setTimeout(() => setActionSuccess(null), 3000);
    } catch (err: any) {
      setActionError(err.message || "Failed to reset password");
    }
  };

  const handleToggleStatus = async (user: User) => {
    const nextStatus = user.status === "ACTIVE" ? "SUSPENDED" : "ACTIVE";
    try {
      await api.updateUser(user.id, { status: nextStatus });
      loadUsers();
    } catch (err: any) {
      alert("Failed to change user status: " + err.message);
    }
  };

  const handleDeleteUser = async (user: User) => {
    if (!confirm(`Are you sure you want to disable ${user.name}?`)) return;
    try {
      await api.deleteUser(user.id);
      loadUsers();
    } catch (err: any) {
      alert("Failed to delete user: " + err.message);
    }
  };

  const filteredUsers = users.filter((u) => {
    const q = search.toLowerCase();
    const matchesSearch =
      (u.name && u.name.toLowerCase().includes(q)) ||
      (u.email && u.email.toLowerCase().includes(q)) ||
      (u.mobile_number && u.mobile_number.includes(q));
    const matchesStatus = statusFilter === "All" || u.status === statusFilter;
    const matchesRole = roleFilter === "All" || u.role === roleFilter;
    return matchesSearch && matchesStatus && matchesRole;
  });

  const activeCount = users.filter((u) => u.status === "ACTIVE").length;
  const adminCount = users.filter((u) => u.role === "ADMIN").length;
  const suspendedCount = users.filter((u) => u.status === "SUSPENDED" || u.status === "DISABLED").length;

  if (loading && users.length === 0) {
    return (
      <div className="p-8 max-w-7xl mx-auto flex items-center justify-center min-h-[70vh]">
        <PageLoader
          title="Loading User Directory..."
          subtitle="Fetching verified accounts, access tiers, and credentials"
        />
      </div>
    );
  }

  return (
    <div className="p-8 max-w-7xl mx-auto space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-gray-200 dark:border-slate-800 pb-5">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100">User Management</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Manage registered accounts, roles, access status, and profile finances
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={loadUsers}
            disabled={loading}
            className="flex items-center gap-1.5"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${loading ? "animate-spin" : ""}`} /> Refresh
          </Button>
          <Button
            onClick={() => setIsAddOpen(true)}
            className="bg-emerald-600 hover:bg-emerald-500 text-white flex items-center gap-1.5 shadow-sm"
          >
            <UserPlus className="h-4 w-4" /> Add New User
          </Button>
        </div>
      </div>

      {actionSuccess && (
        <div className="rounded-xl border border-emerald-200 dark:border-emerald-800/60 bg-emerald-50 dark:bg-emerald-950/40 p-3.5 text-sm text-emerald-800 dark:text-emerald-300 flex items-center gap-2">
          <CheckCircle className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
          {actionSuccess}
        </div>
      )}

      {actionError && (
        <div className="rounded-xl border border-rose-200 dark:border-rose-800/60 bg-rose-50 dark:bg-rose-950/40 p-3.5 text-sm text-rose-800 dark:text-rose-300">
          {actionError}
        </div>
      )}

      {/* Mini Stat Summary */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Total Users</p>
              <p className="text-2xl font-bold text-slate-900 dark:text-slate-100 mt-0.5">{users.length}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-600 dark:text-slate-300">
              <UsersIcon className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Active Accounts</p>
              <p className="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-0.5">{activeCount}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
              <UserCheck className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Administrators</p>
              <p className="text-2xl font-bold text-purple-600 dark:text-purple-400 mt-0.5">{adminCount}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-purple-50 dark:bg-purple-950/40 flex items-center justify-center text-purple-600 dark:text-purple-400">
              <ShieldCheck className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>
        <Card className="border-slate-200 dark:border-slate-800 shadow-sm">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">Suspended / Disabled</p>
              <p className="text-2xl font-bold text-rose-600 dark:text-rose-400 mt-0.5">{suspendedCount}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-rose-50 dark:bg-rose-950/40 flex items-center justify-center text-rose-600 dark:text-rose-400">
              <Ban className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col md:flex-row md:items-center gap-3 bg-white dark:bg-slate-900 p-3.5 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
          <Input
            placeholder="Search users by name, email, or mobile..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9 text-xs"
          />
        </div>

        <div className="flex items-center gap-2">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="text-xs border border-slate-300 dark:border-slate-700 rounded-md px-3 py-2 bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-200 outline-none"
          >
            <option value="All">All Statuses</option>
            <option value="ACTIVE">Active</option>
            <option value="PENDING">Pending</option>
            <option value="SUSPENDED">Suspended</option>
            <option value="DISABLED">Disabled</option>
          </select>

          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="text-xs border border-slate-300 dark:border-slate-700 rounded-md px-3 py-2 bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-200 outline-none"
          >
            <option value="All">All Roles</option>
            <option value="USER">User</option>
            <option value="ADMIN">Admin</option>
          </select>
        </div>
      </div>

      {/* Users Table */}
      <div className="border border-slate-200 dark:border-slate-800 rounded-xl bg-white dark:bg-slate-900 shadow-sm overflow-hidden">
        <Table>
          <TableHeader className="bg-slate-50 dark:bg-slate-800/60">
            <TableRow>
              <TableHead className="font-semibold text-slate-700 dark:text-slate-300">User</TableHead>
              <TableHead className="font-semibold text-slate-700 dark:text-slate-300">Contact</TableHead>
              <TableHead className="font-semibold text-slate-700 dark:text-slate-300">Role</TableHead>
              <TableHead className="font-semibold text-slate-700 dark:text-slate-300">Status</TableHead>
              <TableHead className="font-semibold text-slate-700 dark:text-slate-300">Income</TableHead>
              <TableHead className="font-semibold text-slate-700 dark:text-slate-300">Joined</TableHead>
              <TableHead className="font-semibold text-slate-700 dark:text-slate-300 text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filteredUsers.map((user) => (
              <TableRow key={user.id} className="hover:bg-slate-50/80 dark:hover:bg-slate-800/50 transition-colors">
                {/* User avatar & name */}
                <TableCell>
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-200 font-bold flex items-center justify-center text-xs">
                      {user.name ? user.name.charAt(0).toUpperCase() : "U"}
                    </div>
                    <div>
                      <Link
                        href={`/users/${user.id}`}
                        className="font-semibold text-sm text-slate-900 dark:text-white hover:text-emerald-600 dark:hover:text-emerald-400 transition-colors"
                      >
                        {user.name || "Unnamed User"}
                      </Link>
                      <p className="text-[11px] text-slate-400 font-mono">ID: {user.id.slice(0, 8)}...</p>
                    </div>
                  </div>
                </TableCell>

                {/* Email / Mobile */}
                <TableCell>
                  <p className="text-xs text-slate-800 dark:text-slate-200">{user.email || "No email"}</p>
                  {user.mobile_number && (
                    <p className="text-[11px] text-slate-500 dark:text-slate-400">{user.mobile_number}</p>
                  )}
                </TableCell>

                {/* Role */}
                <TableCell>
                  <Badge
                    variant={user.role === "ADMIN" ? "default" : "secondary"}
                    className={
                      user.role === "ADMIN"
                        ? "bg-purple-100 text-purple-700 border-purple-200 dark:bg-purple-950/60 dark:text-purple-300 dark:border-purple-800"
                        : "bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:border-slate-700"
                    }
                  >
                    {user.role}
                  </Badge>
                </TableCell>

                {/* Status */}
                <TableCell>
                  <Badge
                    className={
                      user.status === "ACTIVE"
                        ? "bg-emerald-100 text-emerald-700 border-emerald-200 dark:bg-emerald-950/60 dark:text-emerald-300 dark:border-emerald-800"
                        : user.status === "PENDING"
                        ? "bg-amber-100 text-amber-700 border-amber-200 dark:bg-amber-950/60 dark:text-amber-300 dark:border-amber-800"
                        : "bg-rose-100 text-rose-700 border-rose-200 dark:bg-rose-950/60 dark:text-rose-300 dark:border-rose-800"
                    }
                  >
                    {user.status}
                  </Badge>
                </TableCell>

                {/* Monthly Income */}
                <TableCell className="text-xs font-semibold text-slate-700 dark:text-slate-200">
                  {new Intl.NumberFormat("en-IN", {
                    style: "currency",
                    currency: user.currency || "INR",
                    maximumFractionDigits: 0,
                  }).format(Number(user.monthly_income || 0))}
                </TableCell>

                {/* Joined Date */}
                <TableCell className="text-xs text-slate-500 dark:text-slate-400">
                  {new Date(user.created_at).toLocaleDateString("en-IN", {
                    day: "numeric",
                    month: "short",
                    year: "numeric",
                  })}
                </TableCell>

                {/* Action Buttons */}
                <TableCell className="text-right">
                  <div className="flex items-center justify-end gap-1">
                    {/* View Details */}
                    <Link href={`/users/${user.id}`}>
                      <Button variant="ghost" size="icon" className="h-8 w-8 text-slate-600 hover:text-emerald-600" title="View User Details">
                        <Eye className="h-4 w-4" />
                      </Button>
                    </Link>

                    {/* Edit Profile */}
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => {
                        setEditingUser(user);
                        setFormEdit({
                          name: user.name,
                          email: user.email,
                          role: user.role,
                          status: user.status,
                          monthly_income: Number(user.monthly_income) || 0,
                          currency: user.currency || "INR",
                          mobile_number: user.mobile_number || "",
                        });
                      }}
                      className="h-8 w-8 text-slate-600 hover:text-blue-600"
                      title="Edit User"
                    >
                      <Edit2 className="h-4 w-4" />
                    </Button>

                    {/* Reset Password */}
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => {
                        setResettingUser(user);
                        setNewPassword("");
                      }}
                      className="h-8 w-8 text-slate-600 hover:text-amber-600"
                      title="Reset Password"
                    >
                      <KeyRound className="h-4 w-4" />
                    </Button>

                    {/* Suspend / Activate Toggle */}
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleToggleStatus(user)}
                      className={`h-8 w-8 ${
                        user.status === "ACTIVE"
                          ? "text-slate-600 hover:text-rose-600"
                          : "text-slate-600 hover:text-emerald-600"
                      }`}
                      title={user.status === "ACTIVE" ? "Suspend Account" : "Activate Account"}
                    >
                      {user.status === "ACTIVE" ? <Ban className="h-4 w-4" /> : <CheckCircle className="h-4 w-4" />}
                    </Button>

                    {/* Delete */}
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleDeleteUser(user)}
                      className="h-8 w-8 text-slate-400 hover:text-rose-600"
                      title="Disable User"
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}

            {filteredUsers.length === 0 && !loading && (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-10 text-slate-500 text-sm">
                  No users found matching your filters.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {/* Modal: Add User */}
      <Dialog open={isAddOpen} onOpenChange={setIsAddOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Add New User</DialogTitle>
            <DialogDescription>
              Create a new user profile with initial credentials and configuration.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleCreateUser} className="space-y-4 pt-2">
            <div>
              <label className="text-xs font-semibold text-slate-700">Full Name *</label>
              <Input
                required
                value={formAdd.name}
                onChange={(e) => setFormAdd({ ...formAdd, name: e.target.value })}
                placeholder="Jane Doe"
                className="mt-1"
              />
            </div>
            <div>
              <label className="text-xs font-semibold text-slate-700">Email Address *</label>
              <Input
                required
                type="email"
                value={formAdd.email}
                onChange={(e) => setFormAdd({ ...formAdd, email: e.target.value })}
                placeholder="jane@example.com"
                className="mt-1"
              />
            </div>
            <div>
              <label className="text-xs font-semibold text-slate-700">Temporary Password *</label>
              <Input
                required
                type="password"
                value={formAdd.password}
                onChange={(e) => setFormAdd({ ...formAdd, password: e.target.value })}
                placeholder="••••••••"
                className="mt-1"
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold text-slate-700">Role</label>
                <select
                  value={formAdd.role}
                  onChange={(e) => setFormAdd({ ...formAdd, role: e.target.value as any })}
                  className="w-full mt-1 border border-slate-300 rounded-md px-3 py-2 text-xs bg-white"
                >
                  <option value="USER">USER</option>
                  <option value="ADMIN">ADMIN</option>
                </select>
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-700">Status</label>
                <select
                  value={formAdd.status}
                  onChange={(e) => setFormAdd({ ...formAdd, status: e.target.value as any })}
                  className="w-full mt-1 border border-slate-300 rounded-md px-3 py-2 text-xs bg-white"
                >
                  <option value="ACTIVE">ACTIVE</option>
                  <option value="PENDING">PENDING</option>
                  <option value="SUSPENDED">SUSPENDED</option>
                </select>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold text-slate-700">Monthly Income</label>
                <Input
                  type="number"
                  value={formAdd.monthly_income}
                  onChange={(e) => setFormAdd({ ...formAdd, monthly_income: Number(e.target.value) })}
                  placeholder="25000"
                  className="mt-1"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-700">Currency</label>
                <Input
                  value={formAdd.currency}
                  onChange={(e) => setFormAdd({ ...formAdd, currency: e.target.value })}
                  placeholder="INR"
                  className="mt-1"
                />
              </div>
            </div>
            <Button type="submit" className="w-full bg-emerald-600 hover:bg-emerald-500 text-white mt-2">
              Create User Profile
            </Button>
          </form>
        </DialogContent>
      </Dialog>

      {/* Modal: Edit User */}
      <Dialog open={!!editingUser} onOpenChange={() => setEditingUser(null)}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Edit User Profile</DialogTitle>
            <DialogDescription>Modify user role, status, and baseline financial settings.</DialogDescription>
          </DialogHeader>
          <form onSubmit={handleUpdateUser} className="space-y-4 pt-2">
            <div>
              <label className="text-xs font-semibold text-slate-700">Full Name</label>
              <Input
                required
                value={formEdit.name}
                onChange={(e) => setFormEdit({ ...formEdit, name: e.target.value })}
                className="mt-1"
              />
            </div>
            <div>
              <label className="text-xs font-semibold text-slate-700">Email Address</label>
              <Input
                required
                type="email"
                value={formEdit.email}
                onChange={(e) => setFormEdit({ ...formEdit, email: e.target.value })}
                className="mt-1"
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold text-slate-700">Role</label>
                <select
                  value={formEdit.role}
                  onChange={(e) => setFormEdit({ ...formEdit, role: e.target.value as any })}
                  className="w-full mt-1 border border-slate-300 rounded-md px-3 py-2 text-xs bg-white"
                >
                  <option value="USER">USER</option>
                  <option value="ADMIN">ADMIN</option>
                </select>
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-700">Status</label>
                <select
                  value={formEdit.status}
                  onChange={(e) => setFormEdit({ ...formEdit, status: e.target.value as any })}
                  className="w-full mt-1 border border-slate-300 rounded-md px-3 py-2 text-xs bg-white"
                >
                  <option value="ACTIVE">ACTIVE</option>
                  <option value="PENDING">PENDING</option>
                  <option value="SUSPENDED">SUSPENDED</option>
                  <option value="DISABLED">DISABLED</option>
                </select>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-xs font-semibold text-slate-700">Monthly Income</label>
                <Input
                  type="number"
                  value={formEdit.monthly_income}
                  onChange={(e) => setFormEdit({ ...formEdit, monthly_income: Number(e.target.value) })}
                  className="mt-1"
                />
              </div>
              <div>
                <label className="text-xs font-semibold text-slate-700">Currency</label>
                <Input
                  value={formEdit.currency}
                  onChange={(e) => setFormEdit({ ...formEdit, currency: e.target.value })}
                  className="mt-1"
                />
              </div>
            </div>
            <Button type="submit" className="w-full bg-blue-600 hover:bg-blue-500 text-white mt-2">
              Save Changes
            </Button>
          </form>
        </DialogContent>
      </Dialog>

      {/* Modal: Reset Password */}
      <Dialog open={!!resettingUser} onOpenChange={() => setResettingUser(null)}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Reset Password</DialogTitle>
            <DialogDescription>
              Assign a new password for <span className="font-semibold text-slate-900">{resettingUser?.name}</span>.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleResetPassword} className="space-y-4 pt-2">
            <div>
              <label className="text-xs font-semibold text-slate-700">New Password (min 6 characters)</label>
              <Input
                required
                type="password"
                minLength={6}
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="••••••••"
                className="mt-1"
              />
            </div>
            <Button type="submit" className="w-full bg-amber-600 hover:bg-amber-500 text-white mt-2">
              Confirm Password Reset
            </Button>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
