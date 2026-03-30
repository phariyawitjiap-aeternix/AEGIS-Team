import path from "path";
import { BRAIN_DIR, OUTPUT_DIR } from "./constants";

/**
 * Validates that a resolved path is within allowed directories.
 * Returns the safe absolute path or throws.
 */
export function guardPath(requestedPath: string): string {
  // Reject obvious traversal
  if (requestedPath.includes("..")) {
    throw new PathViolation("Path traversal detected");
  }

  const resolved = path.resolve(requestedPath);
  const allowed = [BRAIN_DIR, OUTPUT_DIR];

  const isAllowed = allowed.some(
    (dir) => resolved === dir || resolved.startsWith(dir + path.sep)
  );

  if (!isAllowed) {
    throw new PathViolation(
      `Path outside allowed directories: ${resolved}`
    );
  }

  return resolved;
}

export class PathViolation extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PathViolation";
  }
}
