"use client";
import { Header } from "@/components/layout/Header";
import useSWR from "swr";
import type { ApiResponse } from "@/types";

const fetcher = (url: string) => fetch(url).then((r) => r.json());

interface ContextBudget {
  used_pct: number;
  total_tokens: number;
  used_tokens: number;
  breakdown: { category: string; tokens: number; pct: number }[];
  health: "green" | "yellow" | "red";
}

export default function ContextPage() {
  const { data, isLoading } = useSWR<ApiResponse<ContextBudget>>(
    "/api/context",
    fetcher,
    { refreshInterval: 10000 }
  );

  const ctx = data?.data;

  const healthColor =
    ctx?.health === "green"
      ? "text-[var(--success)]"
      : ctx?.health === "yellow"
      ? "text-[var(--warning)]"
      : "text-[var(--danger)]";

  const ringColor =
    ctx?.health === "green"
      ? "stroke-[var(--success)]"
      : ctx?.health === "yellow"
      ? "stroke-[var(--warning)]"
      : "stroke-[var(--danger)]";

  return (
    <div>
      <Header title="Context Budget" />
      <div className="p-6">
        {isLoading || !ctx ? (
          <div className="animate-pulse h-48" />
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Circular gauge */}
            <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-6 flex flex-col items-center">
              <svg viewBox="0 0 120 120" className="w-48 h-48">
                <circle
                  cx="60"
                  cy="60"
                  r="50"
                  fill="none"
                  stroke="var(--border)"
                  strokeWidth="8"
                />
                <circle
                  cx="60"
                  cy="60"
                  r="50"
                  fill="none"
                  className={ringColor}
                  strokeWidth="8"
                  strokeLinecap="round"
                  strokeDasharray={`${(ctx.used_pct / 100) * 314} 314`}
                  transform="rotate(-90 60 60)"
                />
                <text
                  x="60"
                  y="55"
                  textAnchor="middle"
                  className={`fill-[var(--text-primary)] text-2xl font-bold`}
                  fontSize="24"
                >
                  {ctx.used_pct}%
                </text>
                <text
                  x="60"
                  y="72"
                  textAnchor="middle"
                  className="fill-[var(--text-secondary)]"
                  fontSize="10"
                >
                  used
                </text>
              </svg>
              <div className={`text-sm font-medium mt-2 ${healthColor}`}>
                {ctx.health === "green"
                  ? "Healthy"
                  : ctx.health === "yellow"
                  ? "Warning (>60%)"
                  : "Critical (>80%)"}
              </div>
            </div>

            {/* Breakdown */}
            <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-6">
              <div className="text-xs text-[var(--text-secondary)] mb-4 uppercase tracking-wider">
                Breakdown
              </div>
              <div className="space-y-4">
                {ctx.breakdown.map((item) => (
                  <div key={item.category}>
                    <div className="flex justify-between text-sm mb-1">
                      <span className="text-[var(--text-primary)]">
                        {item.category}
                      </span>
                      <span className="text-[var(--text-secondary)]">
                        {(item.tokens / 1000).toFixed(1)}k ({item.pct}%)
                      </span>
                    </div>
                    <div className="h-2 rounded-full bg-[var(--bg-elevated)] overflow-hidden">
                      <div
                        className="h-full rounded-full bg-[var(--accent)]"
                        style={{ width: `${Math.min(item.pct, 100)}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
              <div className="mt-6 pt-4 border-t border-[var(--border)] text-sm text-[var(--text-secondary)]">
                Total: {(ctx.used_tokens / 1000).toFixed(1)}k /{" "}
                {(ctx.total_tokens / 1000).toFixed(0)}k tokens
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
