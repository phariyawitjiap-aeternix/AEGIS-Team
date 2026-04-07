"use client";
import useSWR from "swr";
import type { ApiResponse, ActivityLogEntry } from "@/types";

const fetcher = (url: string) => fetch(url).then((r) => r.json());

export function useActivity() {
  const { data, error, isLoading } = useSWR<ApiResponse<ActivityLogEntry[]>>(
    "/api/activity",
    fetcher,
    { refreshInterval: 5000 }
  );

  return {
    entries: data?.data ?? [],
    error,
    isLoading,
  };
}
