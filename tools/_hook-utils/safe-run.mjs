// safe-run.mjs — shared error wrapper for Node-based AEGIS hooks.
//
// Sprint v15-12. Catches uncaught exceptions, unhandled rejections, and
// thrown errors from the hook's main() function. Writes the full stack
// to .aegis/brain/logs/hook-errors.log for forensics, then emits a single
// classified, human-readable line to stderr so Claude Code shows
// "⚠ [hook] missing Node module — run: bash tools/aegis-doctor.sh --fix"
// instead of "PostToolUse:Bash hook error / node:internal/modules/esm/resolve:271".
//
// Usage from any hook entry point:
//
//   import { safeRun } from "../_hook-utils/safe-run.mjs";
//
//   async function main() { ... return 0; }
//
//   safeRun(main, { hookName: "aegis-live-tail", failOpen: true });
//
// Options:
//   hookName  (string)  — used in log entries and friendly message prefix
//   failOpen  (boolean) — true for PostToolUse / Stop / SessionStart hooks
//                         (always exit 0 on error); false for PreToolUse
//                         hooks where exit-2 should propagate
//   exitOnSuccess (boolean, default true) — call process.exit(rc) when main
//                         resolves; set to false if main manages its own exit

import fs from "node:fs";
import path from "node:path";

// ── Log path resolution ────────────────────────────────────────────────
// Prefer CLAUDE_PROJECT_DIR (set by Claude Code), fall back to cwd. We do
// NOT throw if the log dir can't be created — the wrapper itself must
// never become a new source of crashes.
function resolveLogPath() {
  const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  return path.join(root, ".aegis", "brain", "logs", "hook-errors.log");
}

function logFullStack(hookName, err) {
  try {
    const logPath = resolveLogPath();
    fs.mkdirSync(path.dirname(logPath), { recursive: true });
    const ts = new Date().toISOString();
    const stack = err && err.stack ? err.stack : String(err);
    fs.appendFileSync(
      logPath,
      `[${ts}] hook=${hookName} pid=${process.pid}\n${stack}\n---\n`,
      { encoding: "utf8" },
    );
  } catch {
    // Logging itself failed — accept and continue. The friendly stderr
    // line below is the user-visible fallback.
  }
}

// ── Error classifier ────────────────────────────────────────────────────
// Map common Node failure modes to a one-line, actionable message.
// Unrecognised errors get a generic line that points at the log.
function classify(err, hookName) {
  const msg = String(err && err.message ? err.message : err);
  const code = err && err.code ? String(err.code) : "";

  if (code === "ERR_MODULE_NOT_FOUND" || /Cannot find module|Cannot find package/.test(msg)) {
    return `⚠ [${hookName}] missing Node module — run: bash tools/aegis-doctor.sh --fix`;
  }
  if (code === "ENOENT") {
    const target = msg.match(/'([^']+)'/);
    const t = target ? target[1] : "a referenced path";
    return `⚠ [${hookName}] missing file: ${t} — run: bash tools/aegis-doctor.sh`;
  }
  if (code === "EACCES" || /permission denied/i.test(msg)) {
    return `⚠ [${hookName}] permission denied — try: chmod +x <script>`;
  }
  if (code === "ERR_REQUIRE_ESM" || /require\(\) of ES Module/.test(msg)) {
    return `⚠ [${hookName}] CommonJS/ESM mismatch — Node version may be stale`;
  }
  if (/SyntaxError/.test(msg)) {
    return `⚠ [${hookName}] syntax error in hook script — see .aegis/brain/logs/hook-errors.log`;
  }
  if (/JSON\.parse|Unexpected token.*JSON/.test(msg)) {
    return `⚠ [${hookName}] malformed hook input — Claude Code may have sent unexpected JSON`;
  }
  // Generic fallback — keep it short, point at the log.
  const firstLine = msg.split(/\r?\n/)[0].slice(0, 120);
  return `⚠ [${hookName}] failed: ${firstLine} (full trace in .aegis/brain/logs/hook-errors.log)`;
}

function emitFriendly(err, hookName) {
  try {
    process.stderr.write(classify(err, hookName) + "\n");
  } catch {
    // Even writing to stderr can fail (closed pipe). Silently accept.
  }
}

// ── Public API ──────────────────────────────────────────────────────────
export async function safeRun(mainFn, opts = {}) {
  const hookName = opts.hookName || "unknown-hook";
  const failOpen = opts.failOpen !== false; // default true (PostToolUse-safe)
  const exitOnSuccess = opts.exitOnSuccess !== false;

  // Install process-level catchers BEFORE running main, so any async
  // throw that escapes main()'s promise also gets a friendly message.
  // We dedupe by checking if a handler is already installed (some hooks
  // may set their own; we want to wrap, not clobber).
  const pErr = (err) => {
    logFullStack(hookName, err);
    emitFriendly(err, hookName);
    process.exit(failOpen ? 0 : 1);
  };
  if (process.listenerCount("uncaughtException") === 0) {
    process.on("uncaughtException", pErr);
  }
  if (process.listenerCount("unhandledRejection") === 0) {
    process.on("unhandledRejection", pErr);
  }

  try {
    const rc = await mainFn();
    if (exitOnSuccess) {
      process.exit((typeof rc === "number" ? rc : 0) | 0);
    }
    return rc;
  } catch (err) {
    logFullStack(hookName, err);
    emitFriendly(err, hookName);
    process.exit(failOpen ? 0 : 1);
  }
}

// Exposed for tests + advanced callers.
export { classify, logFullStack };
