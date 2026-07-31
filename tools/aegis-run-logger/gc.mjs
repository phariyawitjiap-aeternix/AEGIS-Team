#!/usr/bin/env node
// gc.mjs — retention / garbage-collection pass for .aegis/brain/runs/
//
// The Stop hook (archive.mjs) appends one dir per session to
// .aegis/brain/runs/<YYYY-MM-DD>-<session>/ and never prunes, so the folder
// grows without bound (114MB / 38 runs as of the P5 brain inventory,
// docs/p5-brain-inventory.md). runs/ is gitignored — this is pure local
// disk housekeeping; nothing here touches any other brain subdir.
//
// Retention policy (a run is KEPT if EITHER holds — conservative, keeps more):
//   • it is among the newest --keep N runs (by run-id date), OR
//   • it is newer than --days D days.
// Everything else is pruned.
//
// DRY-RUN BY DEFAULT. Pass --apply to actually delete.
//
// Usage:
//   node tools/aegis-run-logger/gc.mjs                 # dry-run, keep=10, days=30
//   node tools/aegis-run-logger/gc.mjs --keep 5 --days 14
//   node tools/aegis-run-logger/gc.mjs --apply         # really delete
//   node tools/aegis-run-logger/gc.mjs --json          # machine-readable report
//
// Exit code: 0 on success (dry-run or apply), 2 on usage error.

import fs from "node:fs";
import path from "node:path";

const PROJECT_DIR = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const RUNS_DIR    = path.join(PROJECT_DIR, ".aegis/brain/runs");

const flags = { keep: 10, days: 30, apply: false, json: false };
for (let i = 2; i < process.argv.length; i++) {
  const a = process.argv[i];
  switch (a) {
    case "--keep":  flags.keep = parseInt(process.argv[++i] ?? "", 10); break;
    case "--days":  flags.days = parseInt(process.argv[++i] ?? "", 10); break;
    case "--apply": flags.apply = true; break;
    case "--json":  flags.json = true; break;
    case "-h": case "--help":
      process.stdout.write(
        "Usage: gc.mjs [--keep N] [--days D] [--apply] [--json]\n" +
        "  Prunes .aegis/brain/runs/ dirs that are NEITHER among the newest N\n" +
        "  NOR newer than D days. Dry-run unless --apply. Defaults: keep=10, days=30.\n");
      process.exit(0);
    default:
      process.stderr.write(`unknown flag: ${a}\n`); process.exit(2);
  }
}
if (!Number.isInteger(flags.keep) || flags.keep < 0) { process.stderr.write("--keep must be a non-negative integer\n"); process.exit(2); }
if (!Number.isInteger(flags.days) || flags.days < 0) { process.stderr.write("--days must be a non-negative integer\n"); process.exit(2); }

if (!fs.existsSync(RUNS_DIR)) { process.stdout.write("(no runs dir — nothing to GC)\n"); process.exit(0); }

// Recursively sum file sizes under a dir (bytes).
function dirSize(p) {
  let total = 0;
  let entries;
  try { entries = fs.readdirSync(p, { withFileTypes: true }); } catch { return 0; }
  for (const e of entries) {
    const full = path.join(p, e.name);
    try {
      if (e.isDirectory()) total += dirSize(full);
      else total += fs.statSync(full).size;
    } catch { /* skip unreadable */ }
  }
  return total;
}

function fmtBytes(n) {
  if (n < 1024) return `${n}B`;
  if (n < 1024 ** 2) return `${(n / 1024).toFixed(1)}K`;
  if (n < 1024 ** 3) return `${(n / 1024 ** 2).toFixed(1)}M`;
  return `${(n / 1024 ** 3).toFixed(2)}G`;
}

// run-id date prefix → epoch ms; fall back to meta.archived_at, then mtime.
function runDateMs(id, fullPath) {
  const m = id.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (m) {
    const t = Date.parse(`${m[1]}-${m[2]}-${m[3]}T00:00:00Z`);
    if (!Number.isNaN(t)) return t;
  }
  try {
    const meta = JSON.parse(fs.readFileSync(path.join(fullPath, "meta.json"), "utf8"));
    if (meta.archived_at) { const t = Date.parse(meta.archived_at); if (!Number.isNaN(t)) return t; }
  } catch {}
  try { return fs.statSync(fullPath).mtimeMs; } catch { return 0; }
}

const now = Date.now();
const cutoffMs = now - flags.days * 24 * 60 * 60 * 1000;

const runs = fs.readdirSync(RUNS_DIR, { withFileTypes: true })
  .filter(e => e.isDirectory())
  .map(e => {
    const full = path.join(RUNS_DIR, e.name);
    return { id: e.name, full, dateMs: runDateMs(e.name, full) };
  })
  .sort((a, b) => b.dateMs - a.dateMs); // newest first

// KEEP if among newest N (index < keep) OR newer than cutoff.
const decided = runs.map((r, idx) => {
  const keepByCount = idx < flags.keep;
  const keepByAge   = r.dateMs >= cutoffMs;
  const keep = keepByCount || keepByAge;
  return { ...r, idx, keep, reason: keep ? (keepByCount ? "newest-N" : "within-days") : "stale" };
});

const toPrune = decided.filter(r => !r.keep);
let prunedBytes = 0, prunedCount = 0, prunedFiles = 0;

function countFiles(p) {
  let n = 0;
  let entries;
  try { entries = fs.readdirSync(p, { withFileTypes: true }); } catch { return 0; }
  for (const e of entries) {
    if (e.isDirectory()) n += countFiles(path.join(p, e.name));
    else n += 1;
  }
  return n;
}

const report = [];
for (const r of toPrune) {
  // Safety: never operate outside RUNS_DIR.
  const resolved = path.resolve(r.full);
  if (path.dirname(resolved) !== path.resolve(RUNS_DIR)) continue;
  const bytes = dirSize(r.full);
  const files = countFiles(r.full);
  report.push({ id: r.id, bytes, files });
  prunedBytes += bytes; prunedFiles += files; prunedCount += 1;
  if (flags.apply) {
    try { fs.rmSync(r.full, { recursive: true, force: true }); }
    catch (e) { process.stderr.write(`failed to remove ${r.id}: ${e.message}\n`); }
  }
}

if (flags.json) {
  process.stdout.write(JSON.stringify({
    mode: flags.apply ? "apply" : "dry-run",
    keep: flags.keep, days: flags.days,
    total_runs: runs.length, kept: runs.length - prunedCount, pruned: prunedCount,
    pruned_files: prunedFiles, pruned_bytes: prunedBytes,
    pruned: report,
  }, null, 2) + "\n");
  process.exit(0);
}

const mode = flags.apply ? "APPLIED" : "DRY-RUN (no changes — pass --apply to delete)";
process.stdout.write(`runs GC — ${mode}\n`);
process.stdout.write(`  policy: keep newest ${flags.keep} OR within ${flags.days} days\n`);
process.stdout.write(`  total runs: ${runs.length} | keep: ${runs.length - prunedCount} | prune: ${prunedCount}\n`);
if (report.length) {
  process.stdout.write(`  would remove ${prunedFiles} files / ${fmtBytes(prunedBytes)}:\n`);
  for (const r of report.sort((a, b) => b.bytes - a.bytes)) {
    process.stdout.write(`    ${r.id}  ${fmtBytes(r.bytes).padStart(7)}  (${r.files} files)\n`);
  }
} else {
  process.stdout.write(`  nothing to prune.\n`);
}
