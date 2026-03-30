"use client";
import useSWR from "swr";
import type { ApiResponse, AgentState } from "@/types";

const fetcher = (url: string) => fetch(url).then((r) => r.json());

export function useAgents() {
  const { data, error, isLoading } = useSWR<ApiResponse<AgentState[]>>(
    "/api/agents",
    fetcher,
    { refreshInterval: 5000 }
  );

  return {
    agents: data?.data ?? [],
    error,
    isLoading,
  };
}
