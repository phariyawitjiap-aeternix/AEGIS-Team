import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";
import { BRAIN_DIR } from "@/lib/constants";
import type { ApiResponse, HeartbeatStatus } from "@/types";

export const dynamic = "force-dynamic";

/**
 * Check if Mother Brain agent process is running.
 * Looks for active output files being written to by background agents.
 */
async function checkProcessAlive(): Promise<{
  alive: boolean;
  source: string;
}> {
  // Check 1: Look for recent file modifications in _aegis-brain/ (last 30s)
  // If Mother Brain is working, she's reading/writing files constantly
  try {
    const logsDir = path.join(BRAIN_DIR, "logs");
    const tasksDir = path.join(BRAIN_DIR, "tasks");
    const sprintsDir = path.join(BRAIN_DIR, "sprints");

    const dirsToCheck = [logsDir, tasksDir, sprintsDir];
    const now = Date.now();

    for (const dir of dirsToCheck) {
      try {
        const entries = await fs.readdir(dir, { withFileTypes: true });
        for (const entry of entries) {
          const filePath = path.join(dir, entry.name);
          const stat = await fs.stat(filePath);
          const ageMs = now - stat.mtimeMs;
          // If any file was modified in the last 60 seconds, agent is likely active
          if (ageMs < 60_000) {
            return { alive: true, source: `file:${entry.name} (${Math.round(ageMs / 1000)}s ago)` };
          }
        }
      } catch {
        // dir might not exist
      }
    }
  } catch {
    // ignore
  }

  // Check 2: Look for Claude agent output files being written
  try {
    const tmpDir = "/private/tmp/claude-501";
    const stat = await fs.stat(tmpDir);
    if (stat.isDirectory()) {
      // If tmp dir has recent activity, agents are running
      const entries = await fs.readdir(tmpDir, { recursive: true });
      const now = Date.now();
      for (const entry of entries) {
        if (typeof entry === "string" && entry.endsWith(".output")) {
          const fullPath = path.join(tmpDir, entry);
          try {
            const fstat = await fs.stat(fullPath);
            if (now - fstat.mtimeMs < 120_000) {
              return { alive: true, source: "agent-process" };
            }
          } catch {
            // skip
          }
        }
      }
    }
  } catch {
    // tmp dir may not exist
  }

  return { alive: false, source: "no-signal" };
}

export async function GET() {
  try {
    const heartbeatPath = path.join(BRAIN_DIR, "logs", "heartbeat.log");
    let lastBeat: string | null = null;
    let lastBeatSource: "heartbeat" | "activity" | "process" = "heartbeat";

    // Source 1: heartbeat.log (most reliable when Mother Brain writes it)
    try {
      const content = await fs.readFile(heartbeatPath, "utf-8");
      const lines = content.trim().split("\n").filter(Boolean);
      if (lines.length > 0) {
        lastBeat = lines[lines.length - 1].trim();
        lastBeatSource = "heartbeat";
      }
    } catch {
      // heartbeat.log may not exist
    }

    // Source 2: activity.log (fallback — less frequent but still useful)
    if (!lastBeat) {
      try {
        const activityPath = path.join(BRAIN_DIR, "logs", "activity.log");
        const content = await fs.readFile(activityPath, "utf-8");
        const lines = content.trim().split("\n").filter(Boolean);
        for (let i = lines.length - 1; i >= 0; i--) {
          const match = lines[i].match(/^\[([^\]]+)\]/);
          if (match) {
            lastBeat = match[1];
            lastBeatSource = "activity";
            break;
          }
        }
      } catch {
        // activity.log may not exist
      }
    }

    let ageSeconds = Infinity;
    if (lastBeat) {
      const beatDate = new Date(lastBeat);
      if (!isNaN(beatDate.getTime())) {
        ageSeconds = (Date.now() - beatDate.getTime()) / 1000;
      }
    }

    // Source 3: Process-level check — is the agent actually running right now?
    const processCheck = await checkProcessAlive();

    // Determine health from ALL sources
    let health: HeartbeatStatus["health"] = "unknown";
    if (processCheck.alive) {
      // Process is actively writing files — Mother Brain is WORKING
      // even if heartbeat.log hasn't been written yet
      health = ageSeconds <= 60 ? "healthy" : "working";
    } else if (lastBeat && ageSeconds !== Infinity) {
      if (ageSeconds <= 10) health = "healthy";
      else if (ageSeconds <= 60) health = "stale";
      else health = "dead";
    }

    const data: HeartbeatStatus = {
      alive: health === "healthy" || health === "working",
      last_beat: lastBeat,
      age_seconds: ageSeconds === Infinity ? -1 : Math.round(ageSeconds),
      health,
      // Sanitize source — never expose filesystem paths to client
      source: processCheck.alive
        ? (processCheck.source.startsWith("file:") ? "file-activity" : "agent-process")
        : lastBeatSource,
    };

    const response: ApiResponse<HeartbeatStatus> = {
      ok: true,
      data,
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
