"use client";
import { Header } from "@/components/layout/Header";
import { useAgents } from "@/hooks/useAgents";
import { useSearchParams } from "next/navigation";
import { Suspense } from "react";

const MODEL_BADGE: Record<string, string> = {
  opus: "text-purple-400 bg-purple-400/10",
  sonnet: "text-blue-400 bg-blue-400/10",
  haiku: "text-emerald-400 bg-emerald-400/10",
};

const STATUS_DOT: Record<string, string> = {
  idle: "bg-gray-400",
  working: "bg-blue-500",
  waiting: "bg-yellow-500",
  done: "bg-green-500",
  blocked: "bg-red-500",
};

function AgentsContent() {
  const { agents, isLoading } = useAgents();
  const searchParams = useSearchParams();
  const selectedName = searchParams.get("name");

  if (isLoading) {
    return <div className="animate-pulse p-6">Loading agents...</div>;
  }

  const selected = selectedName
    ? agents.find((a) => a.name === selectedName)
    : null;

  if (selected) {
    return (
      <div className="p-6 space-y-6">
        {/* Header */}
        <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-6">
          <div className="flex items-center gap-4">
            <span className="text-4xl">{selected.emoji}</span>
            <div>
              <h2 className="text-xl font-bold text-[var(--text-primary)]">
                {selected.name}
              </h2>
              <p className="text-sm text-[var(--text-secondary)]">
                {selected.role}
              </p>
              <div className="flex items-center gap-3 mt-1">
                <span
                  className={`text-xs px-2 py-0.5 rounded-full ${
                    MODEL_BADGE[selected.model]
                  }`}
                >
                  {selected.model}
                </span>
                <div className="flex items-center gap-1">
                  <div
                    className={`w-2 h-2 rounded-full ${
                      STATUS_DOT[selected.status]
                    }`}
                  />
                  <span className="text-xs text-[var(--text-secondary)]">
                    {selected.status}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Active Task */}
        {selected.active_task && (
          <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-4">
            <div className="text-xs text-[var(--text-secondary)] mb-2 uppercase tracking-wider">
              Active Task
            </div>
            <div className="text-sm">
              <span className="font-mono text-[var(--accent)]">
                {selected.active_task.id}
              </span>
              <span className="ml-2 text-[var(--text-primary)]">
                {selected.active_task.title}
              </span>
              <span className="ml-2 text-xs text-[var(--text-secondary)]">
                ({selected.active_task.status})
              </span>
            </div>
          </div>
        )}

        {/* Stats */}
        <div className="grid grid-cols-2 gap-4">
          <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-4">
            <div className="text-xs text-[var(--text-secondary)] mb-1">
              Tasks Completed
            </div>
            <div className="text-2xl font-bold text-[var(--text-primary)]">
              {selected.tasks_completed}
            </div>
          </div>
          <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-4">
            <div className="text-xs text-[var(--text-secondary)] mb-1">
              Points Completed
            </div>
            <div className="text-2xl font-bold text-[var(--text-primary)]">
              {selected.points_completed}
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Agent list view
  return (
    <div className="p-6">
      <div className="grid gap-4">
        {agents.map((agent) => (
          <a
            key={agent.name}
            href={`/agents?name=${encodeURIComponent(agent.name)}`}
            className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-4 flex items-center gap-4 hover:border-[var(--accent)]/50 transition-colors"
          >
            <span className="text-2xl">{agent.emoji}</span>
            <div className="flex-1">
              <div className="font-medium text-[var(--text-primary)]">
                {agent.name}
              </div>
              <div className="text-xs text-[var(--text-secondary)]">
                {agent.role}
              </div>
            </div>
            <span
              className={`text-xs px-2 py-0.5 rounded-full ${
                MODEL_BADGE[agent.model]
              }`}
            >
              {agent.model}
            </span>
            <div className="flex items-center gap-1">
              <div
                className={`w-2 h-2 rounded-full ${STATUS_DOT[agent.status]}`}
              />
              <span className="text-xs text-[var(--text-secondary)]">
                {agent.status}
              </span>
            </div>
            <div className="text-xs text-[var(--text-secondary)]">
              {agent.tasks_completed} done / {agent.points_completed} pts
            </div>
          </a>
        ))}
      </div>
    </div>
  );
}

export default function AgentsPage() {
  return (
    <div>
      <Header title="Agents" />
      <Suspense fallback={<div className="p-6">Loading...</div>}>
        <AgentsContent />
      </Suspense>
    </div>
  );
}
