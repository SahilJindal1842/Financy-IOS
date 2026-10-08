"use client";

import { useEffect, useState } from "react";
import { usePathname, useSearchParams } from "next/navigation";

export function NavigationProgressBar() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [navigating, setNavigating] = useState(false);

  useEffect(() => {
    // When route change completes, finish and reset
    setNavigating(false);
  }, [pathname, searchParams]);

  useEffect(() => {
    const handleStart = (e: MouseEvent) => {
      const target = (e.target as HTMLElement)?.closest("a");
      if (target && target.href && !target.target && !target.href.startsWith("javascript:")) {
        const url = new URL(target.href, window.location.origin);
        if (url.origin === window.location.origin && url.pathname !== window.location.pathname) {
          setNavigating(true);
        }
      }
    };

    document.addEventListener("click", handleStart, { capture: true });
    return () => {
      document.removeEventListener("click", handleStart, { capture: true });
    };
  }, []);

  if (!navigating) return null;

  return (
    <div className="fixed top-0 left-0 right-0 z-[100] h-1 bg-transparent overflow-hidden pointer-events-none">
      <div className="h-full bg-gradient-to-r from-emerald-500 via-teal-400 to-emerald-300 w-full animate-pulse shadow-[0_0_10px_rgba(16,185,129,0.7)]" />
    </div>
  );
}

export default NavigationProgressBar;
