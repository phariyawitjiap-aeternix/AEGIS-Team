"use client";
import type { KanbanTask } from "@/types";
import { PRIORITY_COLORS } from "@/lib/constants";

export function KanbanCard({ task }: { task: KanbanTask }) {
  return (
    <div className="rounded-lg border border-[var(--border)] bg-[var(--bg-surface)] p-3 hover:border-[var(--accent)]/30 transition-colors">
      <div className="flex items-start justify-between mb-1">
        <span className="text-xs font-mono text-[var(--accent)]">
          {task.id}
        </span>
        <span className="text-xs font-semibold text-[var(--text-secondary)]">
          {task.points}p
        </span>
      </div>
      <div className="text-sm text-[var(--text-primary)] mb-2 line-clamp-2">
        {task.title}
      </div>
      <div className="flex items-center justify-between">
        <span className="text-xs text-[var(--text-secondary)]">
          @{task.assignee}
        </span>
        <span
          className={`text-[10px] px-1.5 py-0.5 rounded border ${
            PRIORITY_COLORS[task.priority] || ""
          }`}
        >
          {task.priority}
        </span>
      </div>
    </div>
  );
}
