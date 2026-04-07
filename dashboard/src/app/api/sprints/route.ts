import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";
import { BRAIN_DIR } from "@/lib/constants";
import type { ApiResponse, SprintInfo } from "@/types";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const sprintsDir = path.join(BRAIN_DIR, "sprints");
    const entries = await fs.readdir(sprintsDir, { withFileTypes: true });

    // Find current sprint symlink target
    let currentTarget = "";
    try {
      currentTarget = await fs.readlink(
        path.join(sprintsDir, "current")
      );
    } catch {
      // no symlink
    }

    const sprints: SprintInfo[] = entries
      .filter(
        (e) =>
          e.isDirectory() && e.name.startsWith("sprint-") && e.name !== "current"
      )
      .map((e) => ({
        name: e.name,
        isCurrent: e.name === currentTarget,
      }))
      .sort((a, b) => b.name.localeCompare(a.name));

    const response: ApiResponse<SprintInfo[]> = {
      ok: true,
      data: sprints,
      timestamp: new Date().toISOString(),
    };

    return NextResponse.json(response);
  } catch (err) {
    return NextResponse.json({
      ok: false,
      data: [],
      error: process.env.NODE_ENV === "development" ? String(err) : "Internal error",
      timestamp: new Date().toISOString(),
    });
  }
}
