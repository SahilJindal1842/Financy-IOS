"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { api } from "@/lib/api";
import { Wallet, ShieldCheck, Lock, Mail, Loader2, KeyRound } from "lucide-react";

export default function LoginPage() {
  const [email, setEmail] = useState("admin@financy.app");
  const [password, setPassword] = useState("Admin@123");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const res = await api.login(email.trim(), password);
      if (res.user?.role !== "ADMIN") {
        throw new Error("Access denied. Admin credentials required.");
      }
      router.push("/");
    } catch (err: unknown) {
      if (err instanceof Error) {
        setError(err.message || "Failed to log in");
      } else {
        setError("Invalid credentials or server unavailable");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleDemoFill = () => {
    setEmail("admin@financy.app");
    setPassword("Admin@123");
    setError("");
  };

  return (
    <div className="flex min-h-screen w-full items-center justify-center bg-slate-950 p-4">
      {/* Background radial glow */}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,_var(--tw-gradient-stops))] from-emerald-900/20 via-slate-950 to-slate-950 pointer-events-none" />

      <Card className="w-full max-w-md relative z-10 border-slate-800 bg-slate-900/90 backdrop-blur-xl shadow-2xl text-slate-100">
        <CardHeader className="text-center pb-2">
          <div className="mx-auto mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400">
            <Wallet className="h-7 w-7" />
          </div>
          <CardTitle className="text-2xl font-bold tracking-tight text-white flex items-center justify-center gap-2">
            Financy Admin
          </CardTitle>
          <CardDescription className="text-slate-400 text-sm">
            Sign in with administrative privileges to manage platform operations
          </CardDescription>
        </CardHeader>

        <CardContent className="pt-4">
          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-1.5">
              <label htmlFor="email" className="text-xs font-semibold text-slate-300 flex items-center gap-1.5">
                <Mail className="h-3.5 w-3.5 text-slate-400" /> Admin Email
              </label>
              <Input
                id="email"
                type="email"
                placeholder="admin@financy.app"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="bg-slate-950 border-slate-700 text-slate-100 placeholder:text-slate-500 focus:border-emerald-500 focus:ring-emerald-500"
              />
            </div>

            <div className="space-y-1.5">
              <label htmlFor="password" className="text-xs font-semibold text-slate-300 flex items-center gap-1.5">
                <Lock className="h-3.5 w-3.5 text-slate-400" /> Password
              </label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="bg-slate-950 border-slate-700 text-slate-100 placeholder:text-slate-500 focus:border-emerald-500 focus:ring-emerald-500"
              />
            </div>

            {error && (
              <div className="rounded-lg bg-rose-500/10 border border-rose-500/30 p-3 text-xs text-rose-300">
                {error}
              </div>
            )}

            <Button
              type="submit"
              disabled={loading}
              className="w-full bg-emerald-600 hover:bg-emerald-500 text-white font-semibold shadow-lg shadow-emerald-600/20 transition-all duration-150"
            >
              {loading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" /> Verifying...
                </>
              ) : (
                <>
                  <ShieldCheck className="mr-2 h-4 w-4" /> Secure Admin Login
                </>
              )}
            </Button>
          </form>

          {/* Quick Demo Credentials Assistant */}
          <div className="mt-6 pt-5 border-t border-slate-800 text-center">
            <p className="text-xs text-slate-400 mb-2">Default Development Credentials</p>
            <div className="bg-slate-950/70 border border-slate-800 rounded-lg p-2.5 text-xs text-slate-300 flex items-center justify-between">
              <span className="font-mono text-emerald-400">admin@financy.app / Admin@123</span>
              <button
                type="button"
                onClick={handleDemoFill}
                className="inline-flex items-center gap-1 text-[11px] font-medium text-emerald-400 hover:text-emerald-300 underline"
              >
                <KeyRound className="h-3 w-3" /> Auto-fill
              </button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
