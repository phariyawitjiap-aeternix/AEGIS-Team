import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";
import { BRAIN_DIR } from "@/lib/constants";
import type { ApiResponse, HeartbeatStatus } from "@/types";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const heartbeatPath = path.join(BRAIN_DIR, "logs", "heartbeat.log");
    let lastBeat: string | null = null;

    try {
      const content = await fs.readFile(heartbeatPath, "utf-8");
      const lines = content.trim().split("\n").filter(Boolean);
      if (lines.length > 0) {
        lastBeat = lines[lines.length - 1].trim();
      }
    } catch {
      // heartbeat.log may not exist
    }

    // Also check activity.log for last session timestamp
    if (!lastBeat) {
      try {
        const activityPath = path.join(BRAIN_DIR, "logs", "activity.log");
        const content = await fs.readFile(activityPath, "utf-8");
        const lines = content.trim().split("\n").filter(Boolean);
        for (let i = lines.length - 1; i >= 0; i--) {
          const match = lines[i].match(/^\[([^\]]+)\]/);
          if (match) {
            lastBeat = match[1];
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

    let health: HeartbeatStatus["health"] = "unknown";
    if (lastBeat && ageSeconds !== Infinity) {
      if (ageSeconds <= 10) health = "healthy";
      else if (ageSeconds <= 60) health = "stale";
      else health = "dead";
    }

    const data: HeartbeatStatus = {
      alive: health === "healthy",
      last_beat: lastBeat,
      age_seconds: ageSeconds === Infinity ? -1 : Math.round(ageSeconds),
      health,
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
        error: String(err),
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}
