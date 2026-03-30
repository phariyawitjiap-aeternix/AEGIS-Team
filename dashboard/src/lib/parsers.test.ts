import { describe, it, expect } from "vitest";
import { parseActivityLog, parseKanbanMd } from "./parsers";

// ---------------------------------------------------------------------------
// parseActivityLog
// ---------------------------------------------------------------------------
describe("parseActivityLog", () => {
  it("parses a standard log line", () => {
    const line = "[2026-03-30T10:00:00Z] SESSION_START | Mother Brain activated";
    const result = parseActivityLog(line);
    expect(result).toHaveLength(1);
    expect(result[0].timestamp).toBe("2026-03-30T10:00:00Z");
    expect(result[0].event_type).toBe("SESSION_START");
    expect(result[0].message).toBe("Mother Brain activated");
  });

  it("parses a log line with an emoji", () => {
    const line = "[2026-03-30T10:01:00Z] ⚡ TASK_DONE | Implemented feature X";
    const result = parseActivityLog(line);
    expect(result[0].agent_emoji).toBe("⚡");
    expect(result[0].event_type).toBe("TASK_DONE");
    expect(result[0].message).toBe("Implemented feature X");
  });

  it("skips comment lines starting with #", () => {
    const content = "# This is a comment\n[2026-03-30T10:02:00Z] PROGRESS | working";
    const result = parseActivityLog(content);
    expect(result).toHaveLength(1);
    expect(result[0].event_type).toBe("PROGRESS");
  });

  it("skips blank lines", () => {
    const content = "\n\n[2026-03-30T10:03:00Z] DECISION | chose approach A\n\n";
    const result = parseActivityLog(content);
    expect(result).toHaveLength(1);
  });

  it("returns UNKNOWN event_type for unparseable lines", () => {
    const result = parseActivityLog("this is garbage");
    expect(result[0].event_type).toBe("UNKNOWN");
    expect(result[0].raw).toBe("this is garbage");
    expect(result[0].timestamp).toBe("");
  });

  it("returns empty array for empty string", () => {
    expect(parseActivityLog("")).toHaveLength(0);
  });

  it("handles multiple lines", () => {
    const content = [
      "[2026-03-30T10:00:00Z] SESSION_START | begin",
      "[2026-03-30T10:01:00Z] TASK_DONE | done",
      "[2026-03-30T10:02:00Z] SESSION_WRAP | end",
    ].join("\n");
    const result = parseActivityLog(content);
    expect(result).toHaveLength(3);
    expect(result[2].event_type).toBe("SESSION_WRAP");
  });

  it("preserves the raw line", () => {
    const line = "[2026-03-30T10:00:00Z] GATE_PASS | gate 1 passed";
    const result = parseActivityLog(line);
    expect(result[0].raw).toBe(line);
  });
});

// ---------------------------------------------------------------------------
// parseKanbanMd
// ---------------------------------------------------------------------------
describe("parseKanbanMd", () => {
  const SAMPLE_MD = `# Sprint 3
Updated: 2026-03-30

## TODO (2 tasks, 8 pts)
| ID | Title | Pts | Assignee | Priority |
|---|---|---|---|---|
| PROJ-T-001 | Implement auth | 5 | @bolt | high |
| PROJ-T-002 | Write docs | 3 | @muse | low |

## IN_PROGRESS (1 task, 5 pts)
| ID | Title | Pts | Assignee | Priority |
|---|---|---|---|---|
| PROJ-T-003 | Build dashboard | 5 | @bolt | critical |

## DONE (1 task, 3 pts)
| ID | Title | Pts | Assignee | Priority |
|---|---|---|---|---|
| PROJ-T-004 | Setup CI | 3 | @ops | medium |
`;

  it("parses the sprint name", () => {
    const board = parseKanbanMd(SAMPLE_MD);
    expect(board.sprint).toBe("sprint-3");
  });

  it("parses the updated timestamp", () => {
    const board = parseKanbanMd(SAMPLE_MD);
    expect(board.updated).toBe("2026-03-30");
  });

  it("always returns all 6 canonical columns", () => {
    const board = parseKanbanMd(SAMPLE_MD);
    const names = board.columns.map((c) => c.name);
    expect(names).toContain("TODO");
    expect(names).toContain("IN_PROGRESS");
    expect(names).toContain("IN_REVIEW");
    expect(names).toContain("QA");
    expect(names).toContain("DONE");
    expect(names).toContain("BLOCKED");
    expect(board.columns).toHaveLength(6);
  });

  it("returns columns in canonical order", () => {
    const board = parseKanbanMd(SAMPLE_MD);
    const names = board.columns.map((c) => c.name);
    expect(names).toEqual([
      "TODO",
      "IN_PROGRESS",
      "IN_REVIEW",
      "QA",
      "DONE",
      "BLOCKED",
    ]);
  });

  it("parses tasks inside a column", () => {
    const board = parseKanbanMd(SAMPLE_MD);
    const todo = board.columns.find((c) => c.name === "TODO")!;
    expect(todo.tasks).toHaveLength(2);
    expect(todo.tasks[0].id).toBe("PROJ-T-001");
    expect(todo.tasks[0].title).toBe("Implement auth");
    expect(todo.tasks[0].points).toBe(5);
    expect(todo.tasks[0].assignee).toBe("bolt");
    expect(todo.tasks[0].priority).toBe("high");
  });

  it("strips @ from assignee", () => {
    const board = parseKanbanMd(SAMPLE_MD);
    const inProgress = board.columns.find((c) => c.name === "IN_PROGRESS")!;
    expect(inProgress.tasks[0].assignee).toBe("bolt");
  });

  it("parses task_count and point_sum from column header", () => {
    const board = parseKanbanMd(SAMPLE_MD);
    const todo = board.columns.find((c) => c.name === "TODO")!;
    expect(todo.task_count).toBe(2);
    expect(todo.point_sum).toBe(8);
  });

  it("columns missing from markdown have 0 tasks", () => {
    const board = parseKanbanMd(SAMPLE_MD);
    const blocked = board.columns.find((c) => c.name === "BLOCKED")!;
    expect(blocked.tasks).toHaveLength(0);
    expect(blocked.task_count).toBe(0);
  });

  it("handles empty content without throwing", () => {
    const board = parseKanbanMd("");
    expect(board.columns).toHaveLength(6);
    expect(board.sprint).toBe("");
    expect(board.updated).toBe("");
  });

  it("handles content with no tasks in any column", () => {
    const md = `# Sprint 1\n## TODO (0 tasks, 0 pts)\n`;
    const board = parseKanbanMd(md);
    const todo = board.columns.find((c) => c.name === "TODO")!;
    expect(todo.tasks).toHaveLength(0);
    expect(todo.task_count).toBe(0);
  });

  it("correctly handles singular 'task' header label", () => {
    const md = `## IN_PROGRESS (1 task, 5 pts)\n| PROJ-T-010 | Fix bug | 5 | @bolt | high |\n`;
    const board = parseKanbanMd(md);
    const col = board.columns.find((c) => c.name === "IN_PROGRESS")!;
    expect(col.task_count).toBe(1);
    expect(col.tasks).toHaveLength(1);
  });

  it("ignores table separator rows with ---", () => {
    const md = `## TODO (1 task, 3 pts)\n| ID | Title | Pts | Assignee | Priority |\n|---|---|---|---|---|\n| PROJ-T-005 | Task | 3 | @sage | medium |\n`;
    const board = parseKanbanMd(md);
    const todo = board.columns.find((c) => c.name === "TODO")!;
    expect(todo.tasks).toHaveLength(1);
    expect(todo.tasks[0].id).toBe("PROJ-T-005");
  });
});
