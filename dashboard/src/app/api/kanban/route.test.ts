import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("next/server", () => ({
  NextResponse: {
    json: (body: unknown, init?: { status?: number }) => ({
      body,
      status: init?.status ?? 200,
    }),
  },
}));

vi.mock("@/lib/constants", () => ({
  BRAIN_DIR: "/fake/brain",
  OUTPUT_DIR: "/fake/output",
}));

import fs from "fs/promises";
import { GET } from "./route";

const SAMPLE_KANBAN_MD = `# Sprint 2
Updated: 2026-03-30

## TODO (1 task, 5 pts)
| ID | Title | Pts | Assignee | Priority |
|---|---|---|---|---|
| PROJ-T-010 | Build login page | 5 | @spider-man | high |

## IN_PROGRESS (1 task, 3 pts)
| ID | Title | Pts | Assignee | Priority |
|---|---|---|---|---|
| PROJ-T-011 | Write tests | 3 | @war-machine | medium |

## DONE (0 tasks, 0 pts)
`;

beforeEach(() => {
  vi.restoreAllMocks();
});

describe("GET /api/kanban", () => {
  describe("successful parse", () => {
    it("returns ok:true and a parsed board", async () => {
      vi.spyOn(fs, "readFile").mockResolvedValue(SAMPLE_KANBAN_MD);

      const res = await GET();
      const body = (res as any).body;

      expect(body.ok).toBe(true);
      expect(body.data).toBeDefined();
      expect(body.data.sprint).toBe("sprint-2");
    });

    it("parses columns correctly", async () => {
      vi.spyOn(fs, "readFile").mockResolvedValue(SAMPLE_KANBAN_MD);

      const res = await GET();
      const board = (res as any).body.data;

      expect(board.columns).toHaveLength(6); // always all 6
      const todo = board.columns.find((c: any) => c.name === "TODO");
      expect(todo.tasks).toHaveLength(1);
      expect(todo.tasks[0].id).toBe("PROJ-T-010");
    });

    it("strips @ from assignees in tasks", async () => {
      vi.spyOn(fs, "readFile").mockResolvedValue(SAMPLE_KANBAN_MD);

      const res = await GET();
      const board = (res as any).body.data;
      const todo = board.columns.find((c: any) => c.name === "TODO");

      expect(todo.tasks[0].assignee).toBe("spider-man");
    });

    it("parses updated timestamp", async () => {
      vi.spyOn(fs, "readFile").mockResolvedValue(SAMPLE_KANBAN_MD);

      const res = await GET();
      const board = (res as any).body.data;

      expect(board.updated).toBe("2026-03-30");
    });

    it("includes a timestamp in the envelope", async () => {
      vi.spyOn(fs, "readFile").mockResolvedValue(SAMPLE_KANBAN_MD);

      const res = await GET();
      expect((res as any).body.timestamp).toBeDefined();
    });
  });

  describe("when kanban.md is missing", () => {
    it("returns ok:false with an empty board", async () => {
      vi.spyOn(fs, "readFile").mockRejectedValue(
        Object.assign(new Error("ENOENT: no such file"), { code: "ENOENT" })
      );

      const res = await GET();
      const body = (res as any).body;

      expect(body.ok).toBe(false);
      expect(body.data.columns).toEqual([]);
      expect(body.data.sprint).toBe("");
      expect(body.data.updated).toBe("");
    });

    it("includes an error field in the envelope", async () => {
      vi.spyOn(fs, "readFile").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      expect((res as any).body.error).toBeDefined();
    });
  });

  describe("markdown edge cases", () => {
    it("handles a kanban.md with only column headers and no tasks", async () => {
      const md = `# Sprint 1\n## TODO (0 tasks, 0 pts)\n## DONE (0 tasks, 0 pts)\n`;
      vi.spyOn(fs, "readFile").mockResolvedValue(md);

      const res = await GET();
      const board = (res as any).body.data;

      expect(board.columns).toHaveLength(6);
      board.columns.forEach((c: any) => expect(c.tasks).toHaveLength(0));
    });

    it("handles completely empty kanban.md content", async () => {
      vi.spyOn(fs, "readFile").mockResolvedValue("");

      const res = await GET();
      const body = (res as any).body;

      expect(body.ok).toBe(true);
      expect(body.data.columns).toHaveLength(6);
    });
  });
});
