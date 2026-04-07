"use client";
import type { KanbanColumn as KCol } from "@/types";
import { KanbanCard } from "./KanbanCard";
import { STATUS_COLORS } from "@/lib/constants";

export function KanbanColumn({ column }: { column: KCol }) {
  return (
    <div className="w-64 shrink-0">
      <div className="flex items-center gap-2 mb-3 px-1">
        <div
          className={`w-2 h-2 rounded-full ${
            STATUS_COLORS[column.name] || "bg-gray-500"
          }`}
        />
        <span className="text-sm font-medium text-[var(--text-primary)]">
          {column.name.replace("_", " ")}
        </span>
        <span className="text-xs text-[var(--text-secondary)] ml-auto">
          {column.task_count} / {column.point_sum}p
        </span>
      </div>
      <div className="space-y-2">
        {column.tasks.map((task) => (
          <KanbanCard key={task.id} task={task} />
        ))}
        {column.tasks.length === 0 && (
          <div className="rounded-lg border border-dashed border-[var(--border)] p-4 text-center text-xs text-[var(--text-secondary)]">
            Empty
          </div>
        )}
      </div>
    </div>
  );
}
