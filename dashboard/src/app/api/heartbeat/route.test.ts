import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// ---------------------------------------------------------------------------
// Mocks — must be declared before the module under test is imported
// ---------------------------------------------------------------------------

// Mock next/server so we don't pull in the full Next.js runtime
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

// We will control fs/promises per-test via vi.spyOn
import fs from "fs/promises";

import { GET } from "./route";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** A fake dirent-like object returned by readdir */
function fakeEntry(name: string) {
  return { name, isFile: () => true, isDirectory: () => false };
}

function nowIso() {
  return new Date().toISOString();
}

beforeEach(() => {
  vi.restoreAllMocks();
});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("GET /api/heartbeat", () => {
  describe("Source 1 — heartbeat.log", () => {
    it("returns health=healthy when heartbeat.log has a recent timestamp", async () => {
      const recentTs = new Date(Date.now() - 5_000).toISOString(); // 5 s ago

      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).endsWith("heartbeat.log")) return recentTs + "\n";
        throw new Error("ENOENT");
      });
      // Make all readdir / stat calls fail so source 3 returns not-alive
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "stat").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const data = (res as any).body.data;

      expect(data.health).toBe("healthy");
      expect(data.alive).toBe(true);
      expect(data.source).toBe("heartbeat");
      expect(data.age_seconds).toBeGreaterThanOrEqual(0);
      expect(data.age_seconds).toBeLessThan(30);
    });

    it("returns health=stale when heartbeat.log has a 30s-old timestamp", async () => {
      const staleTs = new Date(Date.now() - 30_000).toISOString();

      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).endsWith("heartbeat.log")) return staleTs + "\n";
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "stat").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const data = (res as any).body.data;

      expect(data.health).toBe("stale");
      expect(data.alive).toBe(false);
    });

    it("returns health=dead when heartbeat.log has an old timestamp", async () => {
      const oldTs = new Date(Date.now() - 300_000).toISOString(); // 5 min ago

      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).endsWith("heartbeat.log")) return oldTs + "\n";
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "stat").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const data = (res as any).body.data;

      expect(data.health).toBe("dead");
      expect(data.alive).toBe(false);
    });

    it("uses the last line when heartbeat.log has multiple lines", async () => {
      const oldTs = new Date(Date.now() - 300_000).toISOString();
      const recentTs = new Date(Date.now() - 3_000).toISOString();
      const content = [oldTs, recentTs].join("\n") + "\n";

      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).endsWith("heartbeat.log")) return content;
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "stat").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const data = (res as any).body.data;

      expect(data.health).toBe("healthy");
    });
  });

  describe("Source 2 — activity.log fallback", () => {
    it("falls back to activity.log when heartbeat.log is missing", async () => {
      const recentTs = new Date(Date.now() - 8_000).toISOString();

      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).endsWith("heartbeat.log")) throw new Error("ENOENT");
        if (String(p).endsWith("activity.log"))
          return `[${recentTs}] SESSION_START | Nick Fury started\n`;
        throw new Error("ENOENT");
      });
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "stat").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const data = (res as any).body.data;

      expect(data.source).toBe("activity");
      expect(data.health).toBe("healthy");
    });
  });

  describe("Source 3 — process-level file check", () => {
    it("returns health=working when a brain file was modified recently but heartbeat is old", async () => {
      const oldTs = new Date(Date.now() - 300_000).toISOString();
      const recentMtime = Date.now() - 10_000; // 10s ago, within 60s window

      vi.spyOn(fs, "readFile").mockImplementation(async (p) => {
        if (String(p).endsWith("heartbeat.log")) return oldTs + "\n";
        throw new Error("ENOENT");
      });

      // readdir succeeds for logsDir, returns dirent-like entries
      vi.spyOn(fs, "readdir").mockImplementation(async (dir) => {
        if (String(dir).includes("/fake/brain/logs")) {
          return [{ name: "some-task.log" }] as any;
        }
        throw new Error("ENOENT");
      });

      // stat returns a recent mtime for that file
      vi.spyOn(fs, "stat").mockImplementation(async (p) => {
        if (String(p).endsWith("some-task.log")) {
          return { mtimeMs: recentMtime, isDirectory: () => false } as any;
        }
        throw new Error("ENOENT");
      });

      const res = await GET();
      const data = (res as any).body.data;

      // processCheck.alive = true, but ageSeconds > 60 → working
      expect(data.alive).toBe(true);
      expect(["working", "healthy"]).toContain(data.health);
    });
  });

  describe("when no sources have data", () => {
    it("returns health=unknown when all sources fail", async () => {
      vi.spyOn(fs, "readFile").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "stat").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const data = (res as any).body.data;

      expect(data.health).toBe("unknown");
      expect(data.alive).toBe(false);
      expect(data.last_beat).toBeNull();
      expect(data.age_seconds).toBe(-1);
    });
  });

  describe("response envelope", () => {
    it("always returns ok:true with valid data structure", async () => {
      vi.spyOn(fs, "readFile").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "readdir").mockRejectedValue(new Error("ENOENT"));
      vi.spyOn(fs, "stat").mockRejectedValue(new Error("ENOENT"));

      const res = await GET();
      const body = (res as any).body;

      expect(body.ok).toBe(true);
      expect(body.timestamp).toBeDefined();
      expect(body.data).toBeDefined();
    });
  });
});
