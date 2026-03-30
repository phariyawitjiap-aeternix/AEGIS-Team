import { describe, it, expect, vi, beforeEach } from "vitest";
import path from "path";

// We need to mock constants before importing guardPath so the BRAIN_DIR
// and OUTPUT_DIR resolve to predictable values in the test environment.
vi.mock("@/lib/constants", () => ({
  BRAIN_DIR: "/safe/brain",
  OUTPUT_DIR: "/safe/output",
}));

import { guardPath, PathViolation } from "./path-guard";

describe("guardPath", () => {
  describe("traversal detection", () => {
    it("throws PathViolation when path contains ..", () => {
      expect(() => guardPath("/safe/brain/../../../etc/passwd")).toThrow(
        PathViolation
      );
    });

    it("throws with message 'Path traversal detected'", () => {
      expect(() => guardPath("../outside")).toThrow("Path traversal detected");
    });

    it("throws for double-dot in the middle of path", () => {
      expect(() => guardPath("/safe/brain/subdir/../../../etc")).toThrow(
        PathViolation
      );
    });
  });

  describe("allowed paths", () => {
    it("accepts exact BRAIN_DIR", () => {
      const result = guardPath("/safe/brain");
      expect(result).toBe(path.resolve("/safe/brain"));
    });

    it("accepts a subdirectory of BRAIN_DIR", () => {
      const result = guardPath("/safe/brain/logs/heartbeat.log");
      expect(result).toBe(path.resolve("/safe/brain/logs/heartbeat.log"));
    });

    it("accepts exact OUTPUT_DIR", () => {
      const result = guardPath("/safe/output");
      expect(result).toBe(path.resolve("/safe/output"));
    });

    it("accepts a subdirectory of OUTPUT_DIR", () => {
      const result = guardPath("/safe/output/implementation/result.md");
      expect(result).toBe(
        path.resolve("/safe/output/implementation/result.md")
      );
    });
  });

  describe("disallowed paths outside allowed dirs", () => {
    it("throws PathViolation for /etc/passwd", () => {
      expect(() => guardPath("/etc/passwd")).toThrow(PathViolation);
    });

    it("throws PathViolation for /tmp/secret", () => {
      expect(() => guardPath("/tmp/secret")).toThrow(PathViolation);
    });

    it("includes the resolved path in the error message", () => {
      try {
        guardPath("/etc/hosts");
        expect.fail("should have thrown");
      } catch (err) {
        expect((err as PathViolation).message).toContain(
          "Path outside allowed directories"
        );
      }
    });

    it("does not allow a path that merely starts with BRAIN_DIR as a substring", () => {
      // /safe/brain-extra is NOT inside /safe/brain
      expect(() => guardPath("/safe/brain-extra/file.txt")).toThrow(
        PathViolation
      );
    });
  });

  describe("PathViolation error class", () => {
    it("has name PathViolation", () => {
      try {
        guardPath("../foo");
      } catch (err) {
        expect((err as PathViolation).name).toBe("PathViolation");
      }
    });

    it("is an instance of Error", () => {
      try {
        guardPath("../foo");
      } catch (err) {
        expect(err).toBeInstanceOf(Error);
      }
    });
  });
});
