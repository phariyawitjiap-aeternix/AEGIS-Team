"use client";
import { useMetrics } from "@/hooks/useMetrics";

export function QuickStats() {
  const { metrics, isLoading } = useMetrics();

  if (isLoading || !metrics) {
    return (
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {Array.from({ length: 4 }).map((_, i) => (
          <div
            key={i}
            className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-3 animate-pulse h-16"
          />
        ))}
      </div>
    );
  }

  const totalTasks = Object.values(metrics.tasks).reduce((a, b) => a + b, 0);

  const stats = [
    {
      label: "Tasks Done",
      value: `${metrics.tasks.DONE || 0} / ${totalTasks}`,
    },
    {
      label: "Points",
      value: `${metrics.completed_pts} / ${metrics.committed_pts}`,
    },
    {
      label: "Blocked",
      value: String(metrics.tasks.BLOCKED || 0),
    },
    {
      label: "Velocity",
      value:
        metrics.velocity_history.length > 0
          ? String(
              metrics.velocity_history[metrics.velocity_history.length - 1]
                .velocity
            )
          : "--",
    },
  ];

  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
      {stats.map((stat) => (
        <div
          key={stat.label}
          className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-3"
        >
          <div className="text-xs text-[var(--text-secondary)] mb-1">
            {stat.label}
          </div>
          <div className="text-lg font-semibold text-[var(--text-primary)]">
            {stat.value}
          </div>
        </div>
      ))}
    </div>
  );
}
