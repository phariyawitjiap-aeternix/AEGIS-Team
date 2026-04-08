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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function task(
  id: string,
  overrides: {
    type?: string;
    status?: string;
    gate_results?: Record<string, unknown> | null;
  } = {}
) {
  return JSON.stringify({
    id,
    title: `Task ${id}`,
    type: "task",
    status: "DONE",
    assignee: "spider-man",
    gate_results: {
      gate1_code_review: "PASS",
      gate2_test: "PASS",
      gate3_integration: "PASS",
      gate4_security: "PASS",
      gate5_acceptance: "PASS",
    },
    ...overrides,
  });
}

function setupTasks(tasks: string[]) {
  const dirs = tasks.map((_, i) => `PROJ-T-${String(i + 1).padStart(3, "0")}`);

  vi.spyOn(fs, "readdir").mockImplementation(async (p) => {
    if (String(p).endsWith("/tasks")) return dirs as any;
    throw new Error("ENOENT");
  });

  vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
    const idx = dirs.findIndex((d) => String(p).includes(d));
    if (idx !== -1) return tasks[idx];
    throw new Error("ENOENT");
  });
}

beforeEach(() => {
  vi.restoreAllMocks();
});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("GET /api/gates", () => {
  describe("null safety — tasks with missing gate_results", () => {
    it("does not throw when gate_results is null", async () => {
      setupTasks([task("PROJ-T-001", { gate_results: null })]);

      await expect(GET()).resolves.toBeDefined();
    });

    it("does not throw when gate_results is undefined", async () => {
      setupTasks([
        JSON.stringify({
          id: "PROJ-T-001",
          title: "Task",
          type: "task",
          status: "TODO",
          assignee: "spider-man",
          // gate_results intentionally omitted
        }),
      ]);

      await expect(GET()).resolves.toBeDefined();
    });

    it("counts task as pending when gate_results is missing", async () => {
      setupTasks([
        JSON.stringify({
          id: "PROJ-T-001",
          title: "Task",
          type: "task",
          status: "TODO",
          assignee: "spider-man",
        }),
      ]);

      const res = await GET();
      const gates = (res as any).body.data.gates;
      const codeReview = gates.find((g: any) => g.key === "gate1_code_review");

      expect(codeReview.pending).toBe(1);
      expect(codeReview.passed).toBe(0);
      expect(codeReview.failed).toBe(0);
    });

    it("returns empty gates task list when the empty task results in an empty gate", async () => {
      setupTasks([task("PROJ-T-001", { gate_results: null })]);

      const res = await GET();
      const taskGates = (res as any).body.data.tasks;

      expect(taskGates[0].gates).toEqual({});
    });
  });

  describe("gate aggregation", () => {
    it("counts PASS correctly", async () => {
      setupTasks([
        task("PROJ-T-001", {
          gate_results: { gate1_code_review: "PASS" },
        }),
        task("PROJ-T-002", {
          gate_results: { gate1_code_review: "PASS" },
        }),
      ]);

      const res = await GET();
      const gates = (res as any).body.data.gates;
      const g = gates.find((g: any) => g.key === "gate1_code_review");

      expect(g.passed).toBe(2);
      expect(g.failed).toBe(0);
    });

    it("counts FAIL correctly", async () => {
      setupTasks([
        task("PROJ-T-001", {
          gate_results: { gate2_test: "FAIL" },
        }),
      ]);

      const res = await GET();
      const gates = (res as any).body.data.gates;
      const g = gates.find((g: any) => g.key === "gate2_test");

      expect(g.failed).toBe(1);
      expect(g.passed).toBe(0);
    });

    it("total equals passed + failed + pending", async () => {
      setupTasks([
        task("PROJ-T-001", { gate_results: { gate1_code_review: "PASS" } }),
        task("PROJ-T-002", { gate_results: { gate1_code_review: "FAIL" } }),
        JSON.stringify({
          id: "PROJ-T-003",
          title: "Task",
          type: "task",
          status: "TODO",
          assignee: "spider-man",
        }), // pending (no gate_results)
      ]);

      const res = await GET();
      const g = (res as any).body.data.gates.find(
        (g: any) => g.key === "gate1_code_review"
      );

      expect(g.total).toBe(g.passed + g.failed + g.pending);
      expect(g.total).toBe(3);
    });

    it("skips non-task types (epics, stories)", async () => {
      setupTasks([
        task("PROJ-T-001", { type: "epic", gate_results: { gate1_code_review: "PASS" } }),
        task("PROJ-T-002", { type: "story", gate_results: { gate1_code_review: "PASS" } }),
        task("PROJ-T-003", { type: "task", gate_results: { gate1_code_review: "PASS" } }),
      ]);

      const res = await GET();
      const g = (res as any).body.data.gates.find(
        (g: any) => g.key === "gate1_code_review"
      );

      // Only the task type should be counted
      expect(g.passed).toBe(1);
      expect(g.total).toBe(1);
    });
  });

  describe("all 5 gate definitions are present", () => {
    it("returns exactly 5 gate entries", async () => {
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const gates = (res as any).body.data.gates;

      expect(gates).toHaveLength(5);
    });

    it("gate keys match expected names", async () => {
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const keys = (res as any).body.data.gates.map((g: any) => g.key);

      expect(keys).toEqual([
        "gate1_code_review",
        "gate2_test",
        "gate3_integration",
        "gate4_security",
        "gate5_acceptance",
      ]);
    });
  });

  describe("response structure", () => {
    it("returns ok:true on success", async () => {
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      expect((res as any).body.ok).toBe(true);
    });

    it("task gate view includes id, title, status, gates", async () => {
      setupTasks([
        task("PROJ-T-001"),
      ]);

      const res = await GET();
      const taskEntry = (res as any).body.data.tasks[0];

      expect(taskEntry).toHaveProperty("id");
      expect(taskEntry).toHaveProperty("title");
      expect(taskEntry).toHaveProperty("status");
      expect(taskEntry).toHaveProperty("gates");
    });
  });
});
