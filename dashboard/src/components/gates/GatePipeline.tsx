"use client";
import useSWR from "swr";
import type { ApiResponse, GateSummary } from "@/types";

const fetcher = (url: string) => fetch(url).then((r) => r.json());

function GateCircle({
  result,
  label,
}: {
  result?: "PASS" | "FAIL";
  label: string;
}) {
  const color =
    result === "PASS"
      ? "bg-[var(--success)] border-[var(--success)]"
      : result === "FAIL"
      ? "bg-[var(--danger)] border-[var(--danger)]"
      : "bg-transparent border-[var(--border)]";

  return (
    <div
      className={`w-7 h-7 rounded-full border-2 ${color} flex items-center justify-center`}
      aria-label={`${label}: ${result || "PENDING"}`}
      title={`${label}: ${result || "PENDING"}`}
    >
      {result === "PASS" && (
        <span className="text-white text-xs font-bold">+</span>
      )}
      {result === "FAIL" && (
        <span className="text-white text-xs font-bold">x</span>
      )}
    </div>
  );
}

export function GatePipeline() {
  const { data, isLoading } = useSWR<ApiResponse<GateSummary>>(
    "/api/gates",
    fetcher,
    { refreshInterval: 10000 }
  );

  if (isLoading) {
    return (
      <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-6 animate-pulse h-48" />
    );
  }

  const summary = data?.data;
  if (!summary) return null;

  const gateKeys = [
    { key: "gate1_code_review", short: "G1" },
    { key: "gate2_test", short: "G2" },
    { key: "gate3_integration", short: "G3" },
    { key: "gate4_security", short: "G4" },
    { key: "gate5_acceptance", short: "G5" },
  ] as const;

  return (
    <div className="space-y-6">
      {/* Overview */}
      <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-6">
        <div className="text-xs text-[var(--text-secondary)] mb-4 uppercase tracking-wider">
          Gate Pipeline Overview
        </div>
        <div className="grid grid-cols-5 gap-4">
          {summary.gates.map((gate) => (
            <div key={gate.key} className="text-center">
              <div className="text-sm font-medium text-[var(--text-primary)] mb-1">
                {gate.name}
              </div>
              <div className="text-2xl font-bold text-[var(--accent)]">
                {gate.passed}
              </div>
              <div className="text-xs text-[var(--text-secondary)]">
                / {gate.total} passed
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Per-task table */}
      <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-6 overflow-x-auto">
        <div className="text-xs text-[var(--text-secondary)] mb-4 uppercase tracking-wider">
          Per-Task Gate Status
        </div>
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-[var(--border)]">
              <th className="text-left py-2 text-[var(--text-secondary)] font-medium">
                Task
              </th>
              {gateKeys.map((g) => (
                <th
                  key={g.key}
                  className="text-center py-2 text-[var(--text-secondary)] font-medium w-12"
                >
                  {g.short}
                </th>
              ))}
              <th className="text-left py-2 text-[var(--text-secondary)] font-medium">
                Status
              </th>
            </tr>
          </thead>
          <tbody>
            {summary.tasks.map((task) => (
              <tr
                key={task.id}
                className="border-b border-[var(--border)]/50"
              >
                <td className="py-2 text-[var(--text-primary)]">
                  <span className="font-mono text-xs text-[var(--accent)]">
                    {task.id}
                  </span>
                </td>
                {gateKeys.map((g) => (
                  <td key={g.key} className="py-2 text-center">
                    <div className="flex justify-center">
                      <GateCircle
                        result={
                          task.gates[
                            g.key as keyof typeof task.gates
                          ] as "PASS" | "FAIL" | undefined
                        }
                        label={g.short}
                      />
                    </div>
                  </td>
                ))}
                <td className="py-2">
                  <span className="text-xs text-[var(--text-secondary)]">
                    {task.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
