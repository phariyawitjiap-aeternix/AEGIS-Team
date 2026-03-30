"use client";
import Link from "next/link";
import type { AgentState } from "@/types";

const STATUS_DOT: Record<string, string> = {
  idle: "bg-gray-400",
  working: "bg-blue-500",
  waiting: "bg-yellow-500",
  done: "bg-green-500",
  blocked: "bg-red-500",
};

const MODEL_BADGE: Record<string, string> = {
  opus: "text-purple-400 bg-purple-400/10",
  sonnet: "text-blue-400 bg-blue-400/10",
  haiku: "text-emerald-400 bg-emerald-400/10",
};

export function AgentCard({ agent }: { agent: AgentState }) {
  return (
    <Link
      href={`/agents?name=${encodeURIComponent(agent.name)}`}
      className="block rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-3 hover:border-[var(--accent)]/50 transition-colors"
    >
      <div className="flex items-start justify-between mb-2">
        <div className="flex items-center gap-2">
          <span className="text-lg">{agent.emoji}</span>
          <span className="font-medium text-sm text-[var(--text-primary)]">
            {agent.name}
          </span>
        </div>
        <span
          className={`text-[10px] px-1.5 py-0.5 rounded-full font-mono ${
            MODEL_BADGE[agent.model] || ""
          }`}
        >
          {agent.model}
        </span>
      </div>
      <div className="flex items-center gap-1.5 mb-1">
        <div className={`w-2 h-2 rounded-full ${STATUS_DOT[agent.status]}`} />
        <span className="text-xs text-[var(--text-secondary)]">
          {agent.status}
        </span>
      </div>
      {agent.active_task && (
        <div className="text-xs text-[var(--text-secondary)] truncate mt-1 pl-3.5">
          {agent.active_task.id}
        </div>
      )}
    </Link>
  );
}
