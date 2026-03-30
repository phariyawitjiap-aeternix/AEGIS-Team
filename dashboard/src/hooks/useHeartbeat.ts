"use client";
import useSWR from "swr";
import type { ApiResponse, HeartbeatStatus } from "@/types";

const fetcher = (url: string) => fetch(url).then((r) => r.json());

export function useHeartbeat() {
  const { data, error, isLoading } = useSWR<ApiResponse<HeartbeatStatus>>(
    "/api/heartbeat",
    fetcher,
    { refreshInterval: 2000 }
  );

  return {
    heartbeat: data?.data ?? null,
    error,
    isLoading,
  };
}
