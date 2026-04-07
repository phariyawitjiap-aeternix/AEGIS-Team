"use client";
import useSWR from "swr";
import type { ApiResponse, SprintMetrics } from "@/types";

const fetcher = (url: string) => fetch(url).then((r) => r.json());

export function useMetrics() {
  const { data, error, isLoading } = useSWR<ApiResponse<SprintMetrics>>(
    "/api/metrics",
    fetcher,
    { refreshInterval: 10000 }
  );

  return {
    metrics: data?.data ?? null,
    error,
    isLoading,
  };
}
