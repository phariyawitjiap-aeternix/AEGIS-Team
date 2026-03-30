"use client";
import { useActivity } from "@/hooks/useActivity";
import { EVENT_COLORS } from "@/lib/constants";

export function ActivityFeed() {
  const { entries, isLoading } = useActivity();

  if (isLoading) {
    return (
      <div className="space-y-2">
        {Array.from({ length: 5 }).map((_, i) => (
          <div
            key={i}
            className="rounded-lg border border-[var(--border)] bg-[var(--bg-surface)] p-3 animate-pulse h-12"
          />
        ))}
      </div>
    );
  }

  if (entries.length === 0) {
    return (
      <div className="text-center text-[var(--text-secondary)] py-12">
        No activity logged yet
      </div>
    );
  }

  return (
    <div className="space-y-1">
      {entries.map((entry, i) => {
        const badgeColor =
          EVENT_COLORS[entry.event_type] || "bg-gray-500";
        return (
          <div
            key={i}
            className="flex items-start gap-3 rounded-lg border border-[var(--border)] bg-[var(--bg-surface)] px-3 py-2 hover:border-[var(--accent)]/30 transition-colors"
          >
            <span className="text-xs text-[var(--text-secondary)] font-mono whitespace-nowrap shrink-0 mt-0.5">
              {entry.timestamp}
            </span>
            {entry.agent_emoji && (
              <span className="text-sm shrink-0">{entry.agent_emoji}</span>
            )}
            <span
              className={`text-[10px] px-1.5 py-0.5 rounded text-white shrink-0 mt-0.5 ${badgeColor}`}
            >
              {entry.event_type}
            </span>
            <span className="text-sm text-[var(--text-primary)] break-words">
              {entry.message}
            </span>
          </div>
        );
      })}
    </div>
  );
}
