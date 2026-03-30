import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";
import { BRAIN_DIR } from "@/lib/constants";
import type { ApiResponse, GateSummary, TaskMeta } from "@/types";

export const dynamic = "force-dynamic";

const GATE_DEFS = [
  { name: "Code Review", key: "gate1_code_review" },
  { name: "Tests", key: "gate2_test" },
  { name: "Integration", key: "gate3_integration" },
  { name: "Security", key: "gate4_security" },
  { name: "Acceptance", key: "gate5_acceptance" },
] as const;

export async function GET() {
  try {
    const tasksDir = path.join(BRAIN_DIR, "tasks");
    let taskDirs: string[] = [];
    try {
      const entries = await fs.readdir(tasksDir);
      taskDirs = entries.filter((e) => e.startsWith("PROJ-T-"));
    } catch {
      taskDirs = [];
    }

    const tasks: TaskMeta[] = [];
    for (const dir of taskDirs) {
      try {
        const metaPath = path.join(tasksDir, dir, "meta.json");
        const content = await fs.readFile(metaPath, "utf-8");
        tasks.push(JSON.parse(content));
      } catch {
        // skip
      }
    }

    const gates = GATE_DEFS.map((def) => {
      let passed = 0;
      let failed = 0;
      let pending = 0;

      for (const task of tasks) {
        if (task.type !== "task") continue;
        const result =
          task.gate_results[def.key as keyof typeof task.gate_results];
        if (result === "PASS") passed++;
        else if (result === "FAIL") failed++;
        else pending++;
      }

      return {
        name: def.name,
        key: def.key,
        passed,
        failed,
        pending,
        total: passed + failed + pending,
      };
    });

    const taskGates = tasks
      .filter((t) => t.type === "task")
      .map((t) => ({
        id: t.id,
        title: t.title,
        status: t.status,
        gates: t.gate_results,
      }));

    const data: GateSummary = { gates, tasks: taskGates };

    const response: ApiResponse<GateSummary> = {
      ok: true,
      data,
      timestamp: new Date().toISOString(),
    };

    return NextResponse.json(response);
  } catch (err) {
    return NextResponse.json(
      {
        ok: false,
        data: { gates: [], tasks: [] },
        error: String(err),
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}
