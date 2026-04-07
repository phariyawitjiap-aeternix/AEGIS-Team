import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";
import { BRAIN_DIR } from "@/lib/constants";
import type { ApiResponse, SprintMetrics } from "@/types";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const metricsPath = path.join(
      BRAIN_DIR,
      "sprints",
      "current",
      "metrics.json"
    );

    let metrics: SprintMetrics;
    try {
      const content = await fs.readFile(metricsPath, "utf-8");
      metrics = JSON.parse(content);
    } catch {
      // Build metrics from kanban if metrics.json doesn't exist
      // Read tasks to derive metrics
      const tasksDir = path.join(BRAIN_DIR, "tasks");
      let taskDirs: string[] = [];
      try {
        const entries = await fs.readdir(tasksDir);
        taskDirs = entries.filter((e) => e.startsWith("PROJ-T-"));
      } catch {
        taskDirs = [];
      }

      const taskCounts = {
        TODO: 0,
        IN_PROGRESS: 0,
        IN_REVIEW: 0,
        QA: 0,
        DONE: 0,
        BLOCKED: 0,
      };
      let totalPts = 0;
      let donePts = 0;

      for (const dir of taskDirs) {
        try {
          const metaPath = path.join(tasksDir, dir, "meta.json");
          const content = await fs.readFile(metaPath, "utf-8");
          const task = JSON.parse(content);
          if (task.sprint === "sprint-1" && task.type === "task") {
            const status = task.status as keyof typeof taskCounts;
            if (status in taskCounts) taskCounts[status]++;
            totalPts += task.points || 0;
            if (task.status === "DONE") donePts += task.points || 0;
          }
        } catch {
          // skip
        }
      }

      metrics = {
        sprint: "sprint-1",
        started: "2026-03-24",
        planned_end: "2026-04-04",
        actual_end: null,
        goal: "Fix the Foundation - install, state management, and core pipeline",
        capacity_pts: 28,
        committed_pts: totalPts || 27,
        completed_pts: donePts,
        daily_burndown: [],
        velocity_history: [],
        tasks: taskCounts,
        carry_over: { count: 0, points: 0, task_ids: [] },
      };
    }

    const response: ApiResponse<SprintMetrics> = {
      ok: true,
      data: metrics,
      timestamp: new Date().toISOString(),
    };

    return NextResponse.json(response);
  } catch (err) {
    return NextResponse.json(
      {
        ok: false,
        data: null,
        error: process.env.NODE_ENV === "development" ? String(err) : "Internal error",
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}
