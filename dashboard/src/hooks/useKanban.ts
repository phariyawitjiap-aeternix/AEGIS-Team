"use client";
import useSWR from "swr";
import type { ApiResponse } from "@/types";

const fetcher = (url: string) => fetch(url).then((r) => r.json());

export interface KanbanTask {
  id: string;
  title: string;
  points: number;
  assignee: string;
  priority: string;
}

export interface KanbanColumn {
  name: string;
  tasks: KanbanTask[];
  task_count: number;
  point_sum: number;
}

export interface KanbanData {
  sprint: string;
  updated: string;
  columns: KanbanColumn[];
}

export function useKanban() {
  const { data, error, isLoading } = useSWR<ApiResponse<KanbanData>>(
    "/api/kanban",
    fetcher,
    { refreshInterval: 5000 }
  );

  return {
    kanban: data?.data ?? null,
    error,
    isLoading,
  };
}
