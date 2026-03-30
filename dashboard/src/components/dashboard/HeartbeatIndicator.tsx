"use client";
import { useHeartbeat } from "@/hooks/useHeartbeat";

export function HeartbeatIndicator() {
  const { heartbeat, isLoading } = useHeartbeat();

  if (isLoading || !heartbeat) {
    return (
      <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-4">
        <div className="flex items-center gap-3">
          <div className="w-4 h-4 rounded-full bg-gray-500 animate-pulse" />
          <span className="text-sm text-[var(--text-secondary)]">
            Loading...
          </span>
        </div>
      </div>
    );
  }

  const colorMap = {
    healthy: "bg-[var(--success)]",
    stale: "bg-[var(--warning)]",
    dead: "bg-[var(--danger)]",
    unknown: "bg-gray-500",
  };

  const labelMap = {
    healthy: "ALIVE",
    stale: "STALE",
    dead: "DEAD",
    unknown: "UNKNOWN",
  };

  const dotColor = colorMap[heartbeat.health];
  const label = labelMap[heartbeat.health];

  return (
    <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-4">
      <div className="text-xs text-[var(--text-secondary)] mb-2 uppercase tracking-wider">
        Mother Brain
      </div>
      <div className="flex items-center gap-3">
        <div className="relative">
          <div className={`w-4 h-4 rounded-full ${dotColor}`} />
          {heartbeat.health === "healthy" && (
            <div
              className={`absolute inset-0 w-4 h-4 rounded-full ${dotColor} animate-ping opacity-75`}
            />
          )}
        </div>
        <div>
          <span className="font-semibold text-[var(--text-primary)]">
            {label}
          </span>
          {heartbeat.last_beat && (
            <span className="ml-2 text-xs text-[var(--text-secondary)]">
              {heartbeat.age_seconds >= 0
                ? `${heartbeat.age_seconds}s ago`
                : "unknown"}
            </span>
          )}
        </div>
      </div>
    </div>
  );
}
