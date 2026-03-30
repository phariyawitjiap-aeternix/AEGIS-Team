import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";
import { BRAIN_DIR } from "@/lib/constants";
import { parseActivityLog } from "@/lib/parsers";
import type { ApiResponse, ActivityLogEntry } from "@/types";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const logPath = path.join(BRAIN_DIR, "logs", "activity.log");
    const content = await fs.readFile(logPath, "utf-8");
    const entries = parseActivityLog(content);

    // Return last 100 entries, newest first
    const last100 = entries.slice(-100).reverse();

    const response: ApiResponse<ActivityLogEntry[]> = {
      ok: true,
      data: last100,
      timestamp: new Date().toISOString(),
    };

    return NextResponse.json(response);
  } catch (err) {
    return NextResponse.json({
      ok: true,
      data: [],
      error: String(err),
      timestamp: new Date().toISOString(),
    });
  }
}
