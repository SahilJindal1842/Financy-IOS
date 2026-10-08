"use client";

import React from "react";
import { Sparkles, Wallet } from "lucide-react";

interface PageLoaderProps {
  title?: string;
  subtitle?: string;
  fullScreen?: boolean;
}

export function PageLoader({
  title = "Loading data...",
  subtitle = "Syncing latest records from database",
  fullScreen = false,
}: PageLoaderProps) {
  return (
    <div
      className={`flex flex-col items-center justify-center transition-all animate-in fade-in duration-300 ${
        fullScreen
          ? "fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-md"
          : "min-h-[60vh] w-full p-8"
      }`}
    >
      <div className="relative flex items-center justify-center mb-6">
        {/* Ambient emerald blur glow */}
        <div className="absolute h-24 w-24 rounded-full bg-emerald-500/20 blur-xl animate-pulse" />
        
        {/* Outer spinning ring */}
        <div className="h-16 w-16 rounded-full border-2 border-emerald-500/20 border-t-emerald-500 animate-spin" />
        
        {/* Inner reverse spinner */}
        <div
          className="absolute h-10 w-10 rounded-full border-2 border-emerald-400/30 border-b-emerald-400 animate-spin"
          style={{ animationDirection: "reverse", animationDuration: "1.5s" }}
        />
        
        {/* Center icon */}
        <div className="absolute flex items-center justify-center w-8 h-8 rounded-full bg-emerald-500/10 text-emerald-500 dark:text-emerald-400">
          <Wallet className="h-4 w-4 animate-bounce" style={{ animationDuration: "2s" }} />
        </div>
      </div>

      <div className="text-center space-y-1.5 max-w-sm">
        <h3 className="text-sm font-bold text-slate-800 dark:text-slate-100 flex items-center justify-center gap-1.5">
          <span>{title}</span>
          <Sparkles className="h-3.5 w-3.5 text-emerald-500 animate-pulse" />
        </h3>
        {subtitle && (
          <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
            {subtitle}
          </p>
        )}
      </div>

      {/* Shimmering micro progress indicator */}
      <div className="w-48 h-1 bg-slate-200 dark:bg-slate-800 rounded-full mt-5 overflow-hidden">
        <div className="h-full bg-gradient-to-r from-emerald-500 to-teal-400 rounded-full w-2/3 animate-shimmer" />
      </div>
    </div>
  );
}

export default PageLoader;
