"use client";
import { useAgents } from "@/hooks/useAgents";
import { AgentCard } from "./AgentCard";

export function AgentGrid() {
  const { agents, isLoading } = useAgents();

  return (
    <div>
      <div className="text-xs text-[var(--text-secondary)] mb-3 uppercase tracking-wider">
        Agent Team
      </div>
      {isLoading ? (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          {Array.from({ length: 13 }).map((_, i) => (
            <div
              key={i}
              className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-3 animate-pulse h-24"
            />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          {agents.map((agent) => (
            <AgentCard key={agent.name} agent={agent} />
          ))}
        </div>
      )}
    </div>
  );
}
