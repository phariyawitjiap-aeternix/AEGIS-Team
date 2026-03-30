import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";
import { BRAIN_DIR } from "@/lib/constants";
import { parseKanbanMd } from "@/lib/parsers";
import type { ApiResponse, KanbanBoard } from "@/types";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const kanbanPath = path.join(
      BRAIN_DIR,
      "sprints",
      "current",
      "kanban.md"
    );
    const content = await fs.readFile(kanbanPath, "utf-8");
    const board = parseKanbanMd(content);

    const response: ApiResponse<KanbanBoard> = {
      ok: true,
      data: board,
      timestamp: new Date().toISOString(),
    };

    return NextResponse.json(response);
  } catch (err) {
    // Return empty board
    const emptyBoard: KanbanBoard = {
      columns: [],
      sprint: "",
      updated: "",
    };
    return NextResponse.json({
      ok: false,
      data: emptyBoard,
      error: String(err),
      timestamp: new Date().toISOString(),
    });
  }
}
