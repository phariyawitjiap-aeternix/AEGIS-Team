import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("next/server", () => ({
  NextResponse: {
    json: (body: unknown, init?: { status?: number }) => ({
      body,
      status: init?.status ?? 200,
    }),
  },
}));

vi.mock("@/lib/constants", async (importOriginal) => {
  // Keep the real AGENTS list so normalisation logic is tested against real data
  const real = await importOriginal<typeof import("@/lib/constants")>();
  return {
    ...real,
    BRAIN_DIR: "/fake/brain",
    OUTPUT_DIR: "/fake/output",
  };
});

import fs from "fs/promises";
import { GET } from "./route";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeTask(
  overrides: Partial<{
    id: string;
    title: string;
    status: string;
    assignee: string;
    points: number;
    sprint: string;
    updated: string;
    type: string;
  }>
) {
  return JSON.stringify({
    id: "PROJ-T-001",
    title: "Test task",
    status: "TODO",
    assignee: "spider-man",
    points: 3,
    sprint: "sprint-1",
    updated: new Date().toISOString(),
    type: "task",
    ...overrides,
  });
}

beforeEach(() => {
  vi.restoreAllMocks();
});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("GET /api/agents", () => {
  describe("@assignee normalisation", () => {
    it("matches assignee without @ prefix", async () => {
      vi.spyOn(fs, "readdir").mockImplementation(async (p) => {
        if (String(p).endsWith("/tasks")) return ["PROJ-T-001"] as any;
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).includes("PROJ-T-001")) {
          return makeTask({ assignee: "spider-man", status: "IN_PROGRESS", sprint: "sprint-1" });
        }
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readlink").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const agents: any[] = (res as any).body.data;
      const spiderMan = agents.find((a) => a.name === "Spider-Man");

      expect(spiderMan).toBeDefined();
      expect(spiderMan.status).toBe("working");
    });

    it("matches assignee with @ prefix (@spider-man)", async () => {
      vi.spyOn(fs, "readdir").mockImplementation(async (p) => {
        if (String(p).endsWith("/tasks")) return ["PROJ-T-001"] as any;
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).includes("PROJ-T-001")) {
          return makeTask({ assignee: "@spider-man", status: "IN_PROGRESS", sprint: "sprint-1" });
        }
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readlink").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const agents: any[] = (res as any).body.data;
      const spiderMan = agents.find((a) => a.name === "Spider-Man");

      expect(spiderMan.status).toBe("working");
    });

    it("matches assignee with mixed case (@Spider-Man)", async () => {
      vi.spyOn(fs, "readdir").mockImplementation(async (p) => {
        if (String(p).endsWith("/tasks")) return ["PROJ-T-001"] as any;
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).includes("PROJ-T-001")) {
          return makeTask({ assignee: "@Spider-Man", status: "IN_PROGRESS", sprint: "sprint-1" });
        }
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readlink").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const agents: any[] = (res as any).body.data;
      const spiderMan = agents.find((a) => a.name === "Spider-Man");

      expect(spiderMan.status).toBe("working");
    });

    it("matches multi-word agent name with hyphens (nick-fury)", async () => {
      vi.spyOn(fs, "readdir").mockImplementation(async (p) => {
        if (String(p).endsWith("/tasks")) return ["PROJ-T-002"] as any;
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).includes("PROJ-T-002")) {
          return makeTask({
            id: "PROJ-T-002",
            assignee: "nick-fury",
            status: "IN_PROGRESS",
            sprint: "sprint-1",
          });
        }
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readlink").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const agents: any[] = (res as any).body.data;
      const nickFury = agents.find((a) => a.name === "Nick Fury");

      expect(nickFury).toBeDefined();
      expect(nickFury.status).toBe("working");
    });
  });

  describe("agent status derivation", () => {
    it("is idle with no assigned tasks", async () => {
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "readFile").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "readlink").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const agents: any[] = (res as any).body.data;
      const spiderMan = agents.find((a) => a.name === "Spider-Man");

      expect(spiderMan.status).toBe("idle");
      expect(spiderMan.tasks_completed).toBe(0);
      expect(spiderMan.active_task).toBeUndefined();
    });

    it("is waiting when task is in TODO state", async () => {
      vi.spyOn(fs, "readdir").mockImplementation(async (p) => {
        if (String(p).endsWith("/tasks")) return ["PROJ-T-001"] as any;
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).includes("PROJ-T-001")) {
          return makeTask({ assignee: "spider-man", status: "TODO", sprint: "sprint-1" });
        }
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readlink").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const spiderMan = (res as any).body.data.find((a: any) => a.name === "Spider-Man");

      expect(spiderMan.status).toBe("waiting");
    });

    it("is blocked when task is BLOCKED", async () => {
      vi.spyOn(fs, "readdir").mockImplementation(async (p) => {
        if (String(p).endsWith("/tasks")) return ["PROJ-T-001"] as any;
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).includes("PROJ-T-001")) {
          return makeTask({ assignee: "spider-man", status: "BLOCKED", sprint: "sprint-1" });
        }
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readlink").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const spiderMan = (res as any).body.data.find((a: any) => a.name === "Spider-Man");

      expect(spiderMan.status).toBe("blocked");
      expect(spiderMan.active_task).toBeDefined();
      expect(spiderMan.active_task.id).toBe("PROJ-T-001");
    });

    it("accumulates tasks_completed and points_completed correctly", async () => {
      vi.spyOn(fs, "readdir").mockImplementation(async (p) => {
        if (String(p).endsWith("/tasks")) return ["PROJ-T-001", "PROJ-T-002"] as any;
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).includes("PROJ-T-001")) {
          return makeTask({ id: "PROJ-T-001", assignee: "spider-man", status: "DONE", points: 5, sprint: "sprint-1" });
        }
        if (String(p).includes("PROJ-T-002")) {
          return makeTask({ id: "PROJ-T-002", assignee: "spider-man", status: "DONE", points: 3, sprint: "sprint-1" });
        }
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readlink").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const spiderMan = (res as any).body.data.find((a: any) => a.name === "Spider-Man");

      expect(spiderMan.tasks_completed).toBe(2);
      expect(spiderMan.points_completed).toBe(8);
    });

    it("blocked status takes priority over working", async () => {
      vi.spyOn(fs, "readdir").mockImplementation(async (p) => {
        if (String(p).endsWith("/tasks")) return ["PROJ-T-001", "PROJ-T-002"] as any;
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).includes("PROJ-T-001")) {
          return makeTask({ id: "PROJ-T-001", assignee: "spider-man", status: "BLOCKED", sprint: "sprint-1" });
        }
        if (String(p).includes("PROJ-T-002")) {
          return makeTask({ id: "PROJ-T-002", assignee: "spider-man", status: "IN_PROGRESS", sprint: "sprint-1" });
        }
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readlink").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const spiderMan = (res as any).body.data.find((a: any) => a.name === "Spider-Man");

      expect(spiderMan.status).toBe("blocked");
    });
  });

  describe("response structure", () => {
    it("returns an entry for every agent in the registry", async () => {
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "readFile").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "readlink").mockRejectedValue(new Error("ENOENT"));

      const { AGENTS } = await import("@/lib/constants");
      const res = await GET();
      const agents: any[] = (res as any).body.data;

      expect(agents).toHaveLength(AGENTS.length);
    });

    it("response envelope has ok:true", async () => {
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "readFile").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "readlink").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      expect((res as any).body.ok).toBe(true);
    });
  });
});
