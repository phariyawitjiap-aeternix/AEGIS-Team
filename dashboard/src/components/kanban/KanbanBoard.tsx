"use client";
import useSWR from "swr";
import type { ApiResponse, KanbanBoard as KBBoard } from "@/types";
import { KanbanColumn } from "./KanbanColumn";

const fetcher = (url: string) => fetch(url).then((r) => r.json());

export function KanbanBoard() {
  const { data, isLoading } = useSWR<ApiResponse<KBBoard>>(
    "/api/kanban",
    fetcher,
    { refreshInterval: 5000 }
  );

  const board = data?.data;

  if (isLoading) {
    return (
      <div className="flex gap-4 overflow-x-auto pb-4">
        {Array.from({ length: 6 }).map((_, i) => (
          <div
            key={i}
            className="w-64 shrink-0 rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-3 animate-pulse h-48"
          />
        ))}
      </div>
    );
  }

  if (!board || board.columns.length === 0) {
    return (
      <div className="text-center text-[var(--text-secondary)] py-12">
        No kanban data available
      </div>
    );
  }

  return (
    <div className="flex gap-4 overflow-x-auto pb-4">
      {board.columns.map((col) => (
        <KanbanColumn key={col.name} column={col} />
      ))}
    </div>
  );
}
