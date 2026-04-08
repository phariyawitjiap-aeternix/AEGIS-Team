import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";
import { BRAIN_DIR, AGENTS } from "@/lib/constants";
import type { ApiResponse, AgentState, TaskMeta } from "@/types";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    // Read all task meta.json files
    const tasksDir = path.join(BRAIN_DIR, "tasks");
    let taskDirs: string[] = [];
    try {
      const entries = await fs.readdir(tasksDir);
      taskDirs = entries.filter((e) => e.startsWith("PROJ-T-"));
    } catch {
      // tasks dir may not exist
    }

    // Detect current sprint
    let currentSprint: string | null = null;
    try {
      const sprintLink = await fs.readlink(path.join(BRAIN_DIR, "sprints", "current"));
      currentSprint = sprintLink;
    } catch {
      // no current symlink
    }

    const tasks: TaskMeta[] = [];
    for (const dir of taskDirs) {
      try {
        const metaPath = path.join(tasksDir, dir, "meta.json");
        const content = await fs.readFile(metaPath, "utf-8");
        const task = JSON.parse(content);
        // Include tasks from current sprint OR with active status
        if (!currentSprint || task.sprint === currentSprint ||
            ["IN_PROGRESS", "IN_REVIEW", "QA", "BLOCKED"].includes(task.status)) {
          tasks.push(task);
        }
      } catch {
        // skip invalid tasks
      }
    }

    // Derive agent states
    const agents: AgentState[] = AGENTS.map((def) => {
      const agentName = def.name.toLowerCase();
      // Match: "spider-man", "@spider-man", "Spider-Man", "iron-man", "ironman"
      const normalizeAssignee = (a: string) =>
        (a || "").replace(/^@/, "").toLowerCase().replace(/[\s-]+/g, "");
      const normalizedAgent = normalizeAssignee(agentName);
      const assignedTasks = tasks.filter((t) => {
        const normalized = normalizeAssignee(t.assignee);
        return normalized === normalizedAgent;
      });
      const activeTasks = assignedTasks.filter(
        (t) => t.status === "IN_PROGRESS" || t.status === "IN_REVIEW"
      );
      const completedTasks = assignedTasks.filter(
        (t) => t.status === "DONE"
      );
      const blockedTasks = assignedTasks.filter(
        (t) => t.status === "BLOCKED"
      );
      const waitingTasks = assignedTasks.filter(
        (t) => t.status === "TODO"
      );

      let status: AgentState["status"] = "idle";
      let activeTask: AgentState["active_task"] = undefined;

      if (blockedTasks.length > 0) {
        status = "blocked";
        activeTask = {
          id: blockedTasks[0].id,
          title: blockedTasks[0].title,
          status: blockedTasks[0].status,
        };
      } else if (activeTasks.length > 0) {
        status = "working";
        activeTask = {
          id: activeTasks[0].id,
          title: activeTasks[0].title,
          status: activeTasks[0].status,
        };
      } else if (waitingTasks.length > 0) {
        status = "waiting";
      }

      // Check if a task was recently completed (within 30s)
      const recentDone = completedTasks.find((t) => {
        const updated = new Date(t.updated);
        return Date.now() - updated.getTime() < 30000;
      });
      if (recentDone && status === "idle") {
        status = "done";
      }

      return {
        name: def.name,
        emoji: def.emoji,
        model: def.model,
        role: def.role,
        status,
        active_task: activeTask,
        tasks_completed: completedTasks.length,
        points_completed: completedTasks.reduce(
          (sum, t) => sum + (t.points || 0),
          0
        ),
        last_action: assignedTasks.length > 0
          ? assignedTasks.sort(
              (a, b) =>
                new Date(b.updated).getTime() - new Date(a.updated).getTime()
            )[0].updated
          : undefined,
      };
    });

    const response: ApiResponse<AgentState[]> = {
      ok: true,
      data: agents,
      timestamp: new Date().toISOString(),
    };

    return NextResponse.json(response);
  } catch (err) {
    return NextResponse.json(
      {
        ok: false,
        data: [],
        error: process.env.NODE_ENV === "development" ? String(err) : "Internal error",
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}
