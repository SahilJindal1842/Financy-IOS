export const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000";

export interface User {
  id: string;
  name: string;
  email: string;
  mobile_number: string | null;
  role: "ADMIN" | "USER";
  status: "ACTIVE" | "PENDING" | "SUSPENDED" | "DISABLED";
  avatar: string | null;
  monthly_income: string | number;
  currency: string;
  created_at: string;
  updated_at?: string;
}

export interface DashboardStats {
  isAdmin: boolean;
  isConsolidated: boolean;
  totalUsers?: number;
  userName: string;
  userEmail: string;
  currency: string;
  monthlyIncome: number;
  totalIncome: number;
  totalExpenses: number;
  balance: number;
  availableMoney: number;
  savings: number;
  budget: number;
  totalBudget: number;
  remainingBudget: number;
  budgetUsedPercentage: number;
  isSettled: boolean;
  isEndOfMonth: boolean;
  endOfMonthDate: string;
  settlementMonth: string;
  leftoverSavings: number;
  totalAccumulatedSavings: number;
  transactions: Array<{
    id: string;
    accountId?: string;
    categoryId?: string;
    amount: number;
    type: "expense" | "income";
    date: string;
    note?: string;
    merchant: string;
  }>;
  upcomingBills: Array<{
    id: string;
    merchant: string;
    amount: number;
    nextDueDate: string;
    frequency: string;
    type: string;
    userName?: string;
  }>;
}

export interface TransactionItem {
  id: string;
  user_id: string;
  user_name?: string;
  user_email?: string;
  category_id?: string;
  category_name?: string;
  category_icon?: string;
  type: "EXPENSE" | "INCOME" | "TRANSFER";
  amount: string | number;
  date: string;
  description?: string;
  notes?: string;
  created_at: string;
}

export interface BudgetItem {
  id: string;
  user_id: string;
  user_name?: string;
  user_email?: string;
  category_id: string;
  category_name?: string;
  category_icon?: string;
  amount: string | number;
  month: string;
  created_at: string;
  spent_amount?: number;
  remaining_amount?: number;
  percentage_used?: number;
  status?: "UNDER" | "NEAR_LIMIT" | "OVER_BUDGET";
}

export interface CategoryItem {
  id: string;
  name: string;
  type: "income" | "expense";
  icon?: string;
  color?: string;
  isSystem?: boolean;
  userId?: string | null;
}

export interface RecurringItem {
  id: string;
  user_id: string;
  user_name?: string;
  user_email?: string;
  category_name?: string;
  merchant: string;
  amount: string | number;
  frequency: string;
  next_due_date: string;
  status: "active" | "paused" | "cancelled";
  type: string;
}

export interface SystemHealth {
  database: string;
  databaseHost: string;
  databaseName: string;
  nodeVersion: string;
  uptimeSeconds: number;
  serverTime: string;
  stats: {
    totalUsers: number;
    activeUsers: number;
    adminUsers: number;
    totalTransactions: number;
    totalVolume: number;
    totalBudgets: number;
    activeRecurringRules: number;
  };
}

export interface ReportData {
  monthlyTrends: Array<{
    month: string;
    income: number;
    expense: number;
    transactions: number;
  }>;
  categoryBreakdown: Array<{
    name: string;
    color: string;
    amount: number;
  }>;
}

// Token & Storage helpers
export function getAuthToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("financy_admin_token");
}

export function getCurrentUser(): any {
  if (typeof window === "undefined") return null;
  const data = localStorage.getItem("financy_admin_user");
  try {
    return data ? JSON.parse(data) : null;
  } catch {
    return null;
  }
}

export function setAuthSession(token: string, user: any) {
  if (typeof window === "undefined") return;
  localStorage.setItem("financy_admin_token", token);
  localStorage.setItem("financy_admin_user", JSON.stringify(user));
}

export function clearAuthSession() {
  if (typeof window === "undefined") return;
  localStorage.removeItem("financy_admin_token");
  localStorage.removeItem("financy_admin_user");
}

export function isAuthenticated(): boolean {
  return !!getAuthToken();
}

async function request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const token = getAuthToken();
  const headers = new Headers(options.headers || {});
  headers.set("Content-Type", "application/json");

  if (token) {
    headers.set("Authorization", `Bearer ${token}`);
  }

  const url = `${API_BASE_URL}${endpoint}`;
  const response = await fetch(url, { ...options, headers });

  if (response.status === 401 || response.status === 403) {
    let errorMsg = "Session expired or unauthorized. Please log in.";
    try {
      const cloned = response.clone();
      const errJson = await cloned.json();
      if (errJson?.error) {
        errorMsg = errJson.error;
      }
    } catch {}

    if (
      response.status === 401 ||
      errorMsg.toLowerCase().includes("token") ||
      errorMsg.toLowerCase().includes("access denied") ||
      errorMsg.toLowerCase().includes("unauthorized")
    ) {
      clearAuthSession();
      if (typeof window !== "undefined" && window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
      throw new Error("Session expired or invalid token. Please log in.");
    }
  }

  if (!response.ok) {
    let errorMsg = `Request failed: ${response.statusText}`;
    try {
      const errJson = await response.json();
      if (errJson?.error) errorMsg = errJson.error;
    } catch {}
    throw new Error(errorMsg);
  }

  return response.json() as Promise<T>;
}

export const api = {
  // Auth
  login: async (email: string, password: string) => {
    const res = await request<{ token: string; user: any }>("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });
    setAuthSession(res.token, res.user);
    return res;
  },

  // Dashboard
  getDashboard: (month?: string, userId?: string) => {
    const params = new URLSearchParams();
    if (month) params.append("month", month);
    if (userId) params.append("user_id", userId);
    const qs = params.toString();
    return request<DashboardStats>(`/api/admin/dashboard${qs ? `?${qs}` : ""}`);
  },

  // Users
  getUsers: () => request<User[]>("/api/admin/users"),
  getUser: (id: string, params?: { month?: string; start_date?: string; end_date?: string }) => {
    const p = new URLSearchParams();
    if (params?.month) p.append("month", params.month);
    if (params?.start_date) p.append("start_date", params.start_date);
    if (params?.end_date) p.append("end_date", params.end_date);
    const qs = p.toString();
    return request<any>(`/api/admin/users/${id}${qs ? `?${qs}` : ""}`);
  },
  createUser: (data: Partial<User> & { password: string }) =>
    request<User>("/api/admin/users", {
      method: "POST",
      body: JSON.stringify(data),
    }),
  updateUser: (id: string, data: Partial<User>) =>
    request<User>(`/api/admin/users/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    }),
  deleteUser: (id: string) =>
    request<{ message: string }>(`/api/admin/users/${id}`, {
      method: "DELETE",
    }),
  resetPassword: (id: string, newPassword: string) =>
    request<{ message: string }>(`/api/admin/users/${id}/reset-password`, {
      method: "POST",
      body: JSON.stringify({ newPassword }),
    }),

  // Transactions
  getTransactions: (filters?: {
    user_id?: string;
    category_id?: string;
    type?: string;
    search?: string;
    month?: string;
    start_date?: string;
    end_date?: string;
    date?: string;
    limit?: number;
    offset?: number;
  }) => {
    const params = new URLSearchParams();
    if (filters?.user_id) params.append("user_id", filters.user_id);
    if (filters?.category_id) params.append("category_id", filters.category_id);
    if (filters?.type) params.append("type", filters.type);
    if (filters?.search) params.append("search", filters.search);
    if (filters?.month) params.append("month", filters.month);
    if (filters?.start_date) params.append("start_date", filters.start_date);
    if (filters?.end_date) params.append("end_date", filters.end_date);
    if (filters?.date) params.append("date", filters.date);
    if (filters?.limit) params.append("limit", String(filters.limit));
    if (filters?.offset) params.append("offset", String(filters.offset));
    const qs = params.toString();
    return request<TransactionItem[]>(`/api/admin/transactions${qs ? `?${qs}` : ""}`);
  },
  deleteTransaction: (id: string) =>
    request<{ message: string }>(`/api/admin/transactions/${id}`, {
      method: "DELETE",
    }),

  // Budgets
  getBudgets: (filters?: { user_id?: string; category_id?: string; month?: string }) => {
    const params = new URLSearchParams();
    if (filters?.user_id) params.append("user_id", filters.user_id);
    if (filters?.category_id) params.append("category_id", filters.category_id);
    if (filters?.month) params.append("month", filters.month);
    const qs = params.toString();
    return request<BudgetItem[]>(`/api/admin/budgets${qs ? `?${qs}` : ""}`);
  },
  createBudget: (data: { user_id: string; category_id: string; amount: number; month?: string }) =>
    request<BudgetItem>("/api/admin/budgets", {
      method: "POST",
      body: JSON.stringify(data),
    }),
  deleteBudget: (id: string) =>
    request<{ message: string }>(`/api/admin/budgets/${id}`, {
      method: "DELETE",
    }),

  // Categories
  getCategories: () => request<CategoryItem[]>("/api/categories"),
  createCategory: (data: { name: string; type: "expense" | "income"; icon?: string; color?: string }) =>
    request<CategoryItem>("/api/categories", {
      method: "POST",
      body: JSON.stringify(data),
    }),
  updateCategory: (id: string, data: Partial<CategoryItem>) =>
    request<CategoryItem>(`/api/categories/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    }),
  deleteCategory: (id: string) =>
    request<{ message: string }>(`/api/categories/${id}`, {
      method: "DELETE",
    }),

  // Recurring
  getRecurring: () => request<RecurringItem[]>("/api/admin/recurring"),
  updateRecurringStatus: (id: string, status: "active" | "paused" | "cancelled") =>
    request<RecurringItem>(`/api/admin/recurring/${id}/status`, {
      method: "PUT",
      body: JSON.stringify({ status }),
    }),

  // System & Diagnostics
  getSystem: () => request<SystemHealth>("/api/admin/system"),

  // Reports
  getReports: (params?: { user_id?: string }) => {
    const p = new URLSearchParams();
    if (params?.user_id) p.append("user_id", params.user_id);
    const qs = p.toString();
    return request<ReportData>(`/api/admin/reports${qs ? `?${qs}` : ""}`);
  },
};
