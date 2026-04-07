"use client";
import { useMetrics } from "@/hooks/useMetrics";

export function SprintSummaryCard() {
  const { metrics, isLoading } = useMetrics();

  if (isLoading || !metrics) {
    return (
      <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-4 animate-pulse">
        <div className="h-4 bg-[var(--bg-elevated)] rounded w-1/3 mb-2" />
        <div className="h-3 bg-[var(--bg-elevated)] rounded w-2/3" />
      </div>
    );
  }

  const progress =
    metrics.committed_pts > 0
      ? Math.round((metrics.completed_pts / metrics.committed_pts) * 100)
      : 0;

  const totalTasks = Object.values(metrics.tasks).reduce((a, b) => a + b, 0);
  const doneTasks = metrics.tasks.DONE || 0;

  return (
    <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-4">
      <div className="text-xs text-[var(--text-secondary)] mb-1 uppercase tracking-wider">
        Sprint Summary
      </div>
      <div className="font-semibold text-[var(--text-primary)] mb-1">
        {metrics.sprint.replace("-", " ").replace(/\b\w/g, (c) => c.toUpperCase())}
      </div>
      <div className="text-sm text-[var(--text-secondary)] mb-3">
        {metrics.goal}
      </div>
      <div className="text-xs text-[var(--text-secondary)] mb-1">
        {metrics.started} - {metrics.planned_end}
      </div>

      {/* Progress bar */}
      <div className="mt-3 mb-2">
        <div className="flex justify-between text-xs text-[var(--text-secondary)] mb-1">
          <span>{progress}% complete</span>
          <span>
            {metrics.completed_pts}/{metrics.committed_pts} pts
          </span>
        </div>
        <div className="h-2 rounded-full bg-[var(--bg-elevated)] overflow-hidden">
          <div
            className="h-full rounded-full bg-[var(--accent)] transition-all duration-500"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      <div className="text-xs text-[var(--text-secondary)]">
        {doneTasks}/{totalTasks} tasks done
      </div>
    </div>
  );
}
