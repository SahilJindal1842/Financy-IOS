"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  CreditCard,
  PieChart,
  Tags,
  CalendarClock,
  BarChart3,
  Server,
  LogOut,
  Wallet,
  ShieldCheck,
  Sun,
  Moon,
  Monitor,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { clearAuthSession, getCurrentUser, isAuthenticated } from "@/lib/api";
import { useTheme } from "@/components/ThemeProvider";

const navigation = [
  { name: "Dashboard", href: "/", icon: LayoutDashboard },
  { name: "Users", href: "/users", icon: Users },
  { name: "Transactions", href: "/transactions", icon: CreditCard },
  { name: "Budgets", href: "/budgets", icon: PieChart },
  { name: "Categories", href: "/categories", icon: Tags },
  { name: "Recurring Bills", href: "/recurring", icon: CalendarClock },
  { name: "Reports & Analytics", href: "/reports", icon: BarChart3 },
  { name: "System Health", href: "/system", icon: Server },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const [currentUser, setCurrentUser] = useState<any>(null);
  const { theme, setTheme } = useTheme();

  useEffect(() => {
    if (pathname !== "/login") {
      if (!isAuthenticated()) {
        router.push("/login");
      } else {
        setCurrentUser(getCurrentUser());
      }
    }
  }, [pathname, router]);

  if (pathname === "/login") return null;

  const handleLogout = () => {
    clearAuthSession();
    router.push("/login");
  };

  return (
    <aside className="flex h-screen w-64 flex-col bg-slate-900 text-slate-200 border-r border-slate-800 shadow-xl">
      {/* Brand Header */}
      <div className="flex h-16 shrink-0 items-center px-6 border-b border-slate-800 gap-3">
        <div className="w-9 h-9 rounded-xl bg-emerald-500/20 border border-emerald-500/40 flex items-center justify-center text-emerald-400">
          <Wallet className="h-5 w-5" />
        </div>
        <div>
          <span className="text-base font-bold text-white tracking-wide block">Financy</span>
          <span className="text-xs text-emerald-400 font-medium flex items-center gap-1">
            <ShieldCheck className="h-3 w-3 inline" /> Admin Control
          </span>
        </div>
      </div>

      {/* Navigation Links */}
      <div className="flex flex-1 flex-col overflow-y-auto px-3 py-4">
        <nav className="space-y-1">
          {navigation.map((item) => {
            const isActive = item.href === "/" ? pathname === "/" : pathname.startsWith(item.href);
            return (
              <Link
                key={item.name}
                href={item.href}
                className={cn(
                  isActive
                    ? "bg-emerald-600/20 text-emerald-400 border-r-4 border-emerald-500 font-semibold"
                    : "text-slate-400 hover:bg-slate-800/80 hover:text-slate-200 font-medium",
                  "group flex items-center rounded-lg px-3 py-2.5 text-sm transition-all duration-150"
                )}
              >
                <item.icon
                  className={cn(
                    isActive ? "text-emerald-400" : "text-slate-400 group-hover:text-slate-200",
                    "mr-3 h-5 w-5 flex-shrink-0 transition-colors"
                  )}
                  aria-hidden="true"
                />
                {item.name}
              </Link>
            );
          })}
        </nav>
      </div>

      {/* Theme Mode Switcher */}
      <div className="px-4 py-3 border-t border-slate-800 bg-slate-950/40">
        <div className="flex items-center justify-between bg-slate-900 p-1 rounded-xl border border-slate-800 text-xs">
          <button
            type="button"
            onClick={() => setTheme("light")}
            className={cn(
              "flex-1 flex items-center justify-center gap-1.5 py-1.5 rounded-lg transition-all font-medium",
              theme === "light"
                ? "bg-slate-800 text-amber-300 shadow-sm"
                : "text-slate-400 hover:text-slate-200"
            )}
            title="Light Mode"
          >
            <Sun className="h-3.5 w-3.5" />
            <span>Light</span>
          </button>
          <button
            type="button"
            onClick={() => setTheme("system")}
            className={cn(
              "flex-1 flex items-center justify-center gap-1.5 py-1.5 rounded-lg transition-all font-medium",
              theme === "system"
                ? "bg-slate-800 text-emerald-400 shadow-sm"
                : "text-slate-400 hover:text-slate-200"
            )}
            title="System Theme"
          >
            <Monitor className="h-3.5 w-3.5" />
            <span>Auto</span>
          </button>
          <button
            type="button"
            onClick={() => setTheme("dark")}
            className={cn(
              "flex-1 flex items-center justify-center gap-1.5 py-1.5 rounded-lg transition-all font-medium",
              theme === "dark"
                ? "bg-slate-800 text-indigo-400 shadow-sm"
                : "text-slate-400 hover:text-slate-200"
            )}
            title="Dark Mode"
          >
            <Moon className="h-3.5 w-3.5" />
            <span>Dark</span>
          </button>
        </div>
      </div>

      {/* Admin User Footer & Logout */}
      <div className="border-t border-slate-800 p-4 bg-slate-950/60">
        <div className="flex items-center gap-3 mb-3 px-1">
          <div className="w-8 h-8 rounded-full bg-emerald-600 text-white font-bold flex items-center justify-center text-xs shadow">
            {currentUser?.name ? currentUser.name.charAt(0).toUpperCase() : "A"}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-semibold text-slate-200 truncate">
              {currentUser?.name || "System Admin"}
            </p>
            <p className="text-[11px] text-slate-400 truncate">
              {currentUser?.email || "admin@financy.app"}
            </p>
          </div>
        </div>

        <button
          onClick={handleLogout}
          className="w-full flex items-center justify-center gap-2 rounded-lg px-3 py-2 text-xs font-medium text-rose-400 hover:bg-rose-500/10 hover:text-rose-300 transition-colors border border-rose-500/20"
        >
          <LogOut className="h-4 w-4" />
          Sign Out
        </button>
      </div>
    </aside>
  );
}
