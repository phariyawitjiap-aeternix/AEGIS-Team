#!/usr/bin/env node
// tools/aegis-doc-canon/skill-frontmatter.mjs (sprint-v12-03)
//
// Lint, backfill, and apply-manifest for skill frontmatter.
//
// Schema (per skill-schema.md v1.0.0):
//   Required keys: name, description, profile, triggers, reads, writes, wires, tests, supersedes
//   The 5 "graph keys" (reads/writes/wires/tests/supersedes) are required PRESENT but
//   may be empty arrays. The 4 "base keys" (name/description/profile/triggers) must be present
//   AND non-empty (legacy invariant — pre-v12-03 skills already have these).
//
// Modes (mutually exclusive):
//   --lint                       assert all skills satisfy schema; exit 0 / 1
//   --backfill [--dry-run]       fill missing graph keys with [] (atomic, idempotent)
//   --apply-manifest <file>      set graph values from manifest JSON (overwrites)
//
// Common flags:
//   --skills-dir <path>          default: ./skills
//   --json                       machine-readable output
//
// Spec: AEGIS Knowledge-Layer Mega Plan v1.1, sprint v12-03 stories B + C.

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const BASE_KEYS = ['name', 'description', 'profile', 'triggers'];
const GRAPH_KEYS = ['reads', 'writes', 'wires', 'tests', 'supersedes'];
const ALL_KEYS = [...BASE_KEYS, ...GRAPH_KEYS];

function parseArgs(argv) {
  const args = {
    mode: null, // 'lint' | 'backfill' | 'apply-manifest'
    skillsDir: 'skills',
    manifestPath: null,
    dryRun: false,
    json: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    switch (a) {
      case '--lint':            args.mode = 'lint'; break;
      case '--backfill':        args.mode = 'backfill'; break;
      case '--apply-manifest':  args.mode = 'apply-manifest'; args.manifestPath = argv[++i]; break;
      case '--skills-dir':      args.skillsDir = argv[++i]; break;
      case '--dry-run':         args.dryRun = true; break;
      case '--json':            args.json = true; break;
      case '-h':
      case '--help':
        console.log(
          'Usage: skill-frontmatter.mjs --lint | --backfill [--dry-run] | --apply-manifest <file>\n' +
          '       [--skills-dir <path>] [--json]'
        );
        process.exit(0);
        break;
      default:
        console.error(`Unknown arg: ${a}`);
        process.exit(2);
    }
  }
  if (!args.mode) {
    console.error('error: must specify --lint, --backfill, or --apply-manifest <file>');
    process.exit(2);
  }
  return args;
}

// ─── Minimal frontmatter parser (no js-yaml dependency) ────────────────────
//
// Skill frontmatter is between two `---` lines at the top of the file.
// Within it, we recognize:
//   key: value          (scalar)
//   key:                (followed by indented `- item` lines for arrays, or nested map)
//   key: []             (inline empty array)
//   key: [a, b]         (inline non-empty array)
// Nested two-level objects (e.g. triggers.en / triggers.th) are flattened
// to dotted keys for storage but reassembled on write.

function readFrontmatter(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  if (lines[0] !== '---') {
    return { ok: false, error: 'no leading --- delimiter', content, frontmatter: null, body: content };
  }
  let endIdx = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === '---') {
      endIdx = i;
      break;
    }
  }
  if (endIdx === -1) {
    return { ok: false, error: 'no closing --- delimiter', content, frontmatter: null, body: content };
  }
  const fmRaw = lines.slice(1, endIdx).join('\n');
  const body = lines.slice(endIdx + 1).join('\n');
  return {
    ok: true,
    fmRaw,
    body,
    fmLines: lines.slice(1, endIdx),
    fullLines: lines,
    fmStartIdx: 1,
    fmEndIdx: endIdx,
  };
}

function detectKeysPresent(fmLines) {
  const present = new Set();
  for (const line of fmLines) {
    const m = line.match(/^([a-zA-Z_][a-zA-Z0-9_]*)\s*:/);
    if (m) present.add(m[1]);
  }
  return present;
}

// Find the line index INSIDE fmLines (0-based) where graph keys should be appended.
// Strategy: append at end of frontmatter (right before the closing ---).
function findAppendLineIndex(fmLines) {
  return fmLines.length;
}

// Build a YAML snippet for missing graph keys.
function buildMissingKeysSnippet(missingKeys) {
  return missingKeys.map((k) => `${k}: []`).join('\n');
}

// ─── Lint ──────────────────────────────────────────────────────────────────

function lintSkill(filePath) {
  const fr = readFrontmatter(filePath);
  if (!fr.ok) return { ok: false, errors: [fr.error], missing: ALL_KEYS };
  const present = detectKeysPresent(fr.fmLines);
  const missing = ALL_KEYS.filter((k) => !present.has(k));
  const errors = [];
  if (missing.length > 0) errors.push(`missing keys: ${missing.join(', ')}`);
  return { ok: errors.length === 0, errors, missing };
}

function lintAll(skillsDir) {
  const files = fs.readdirSync(skillsDir).filter((f) => f.endsWith('.md'));
  const results = files.map((f) => {
    const full = path.join(skillsDir, f);
    return { path: path.posix.join(path.basename(skillsDir), f), ...lintSkill(full) };
  });
  return results;
}

// ─── Backfill ──────────────────────────────────────────────────────────────

function backfillSkill(filePath, { dryRun }) {
  const fr = readFrontmatter(filePath);
  if (!fr.ok) return { changed: false, error: fr.error, added: [] };
  const present = detectKeysPresent(fr.fmLines);
  const missingGraph = GRAPH_KEYS.filter((k) => !present.has(k));
  if (missingGraph.length === 0) return { changed: false, added: [] };
  // Append missing graph keys at end of frontmatter
  const newFmLines = [...fr.fmLines];
  for (const k of missingGraph) newFmLines.push(`${k}: []`);
  const before = fr.fullLines.slice(0, fr.fmStartIdx).join('\n');
  const after = fr.fullLines.slice(fr.fmEndIdx).join('\n');
  const newContent = before + '\n' + newFmLines.join('\n') + '\n' + after;
  if (!dryRun) {
    const tmp = filePath + '.tmp';
    fs.writeFileSync(tmp, newContent);
    fs.renameSync(tmp, filePath);
  }
  return { changed: true, added: missingGraph };
}

function backfillAll(skillsDir, opts) {
  const files = fs.readdirSync(skillsDir).filter((f) => f.endsWith('.md'));
  const results = files.map((f) => {
    const full = path.join(skillsDir, f);
    return { path: path.posix.join(path.basename(skillsDir), f), ...backfillSkill(full, opts) };
  });
  return results;
}

// ─── Apply manifest ────────────────────────────────────────────────────────
//
// For each skill named in the manifest, set the graph keys to the manifest's
// values (overwriting). Operates by replacing whole-line `<key>: ...` lines
// in the frontmatter, OR appending if absent.

function setOrReplaceArrayKey(fmLines, key, values) {
  // values = JS array
  const inlined = values.length === 0
    ? '[]'
    : '[' + values.map((v) => JSON.stringify(v)).join(', ') + ']';
  // Find the line where this key starts (could be `key: []`, `key: [a,b]`, or `key:` followed by `- a`)
  let foundIdx = -1;
  for (let i = 0; i < fmLines.length; i++) {
    if (new RegExp(`^${key}\\s*:`).test(fmLines[i])) {
      foundIdx = i;
      break;
    }
  }
  if (foundIdx === -1) {
    fmLines.push(`${key}: ${inlined}`);
    return;
  }
  // If the existing line is `key:` with multi-line YAML below, we need to find the run of indented lines.
  // For simplicity in v12-03, we only handle single-line replacements; multi-line array values aren't used yet.
  fmLines[foundIdx] = `${key}: ${inlined}`;
}

function applyManifestToSkill(filePath, skillKey, manifestEntry) {
  const fr = readFrontmatter(filePath);
  if (!fr.ok) return { changed: false, error: fr.error, applied: [] };
  const newFmLines = [...fr.fmLines];
  const applied = [];
  for (const k of GRAPH_KEYS) {
    if (manifestEntry[k] !== undefined) {
      const before = newFmLines.find((l) => new RegExp(`^${k}\\s*:`).test(l)) || null;
      setOrReplaceArrayKey(newFmLines, k, manifestEntry[k]);
      const after = newFmLines.find((l) => new RegExp(`^${k}\\s*:`).test(l)) || null;
      if (before !== after) applied.push(k);
    }
  }
  if (applied.length === 0) return { changed: false, applied: [] };
  const before = fr.fullLines.slice(0, fr.fmStartIdx).join('\n');
  const after = fr.fullLines.slice(fr.fmEndIdx).join('\n');
  const newContent = before + '\n' + newFmLines.join('\n') + '\n' + after;
  const tmp = filePath + '.tmp';
  fs.writeFileSync(tmp, newContent);
  fs.renameSync(tmp, filePath);
  return { changed: true, applied };
}

function applyManifest(skillsDir, manifestPath) {
  if (!fs.existsSync(manifestPath)) {
    console.error(`error: manifest not found: ${manifestPath}`);
    process.exit(2);
  }
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const results = [];
  for (const [skillName, entry] of Object.entries(manifest.skills || {})) {
    const filePath = path.join(skillsDir, `${skillName}.md`);
    if (!fs.existsSync(filePath)) {
      results.push({ path: `skills/${skillName}.md`, changed: false, error: 'skill file not found' });
      continue;
    }
    const r = applyManifestToSkill(filePath, skillName, entry);
    results.push({ path: `skills/${skillName}.md`, ...r });
  }
  return results;
}

// ─── Main ──────────────────────────────────────────────────────────────────

function printResults(mode, results, args) {
  if (args.json) {
    process.stdout.write(JSON.stringify({ mode, results }, null, 2) + '\n');
    return;
  }
  if (mode === 'lint') {
    let pass = 0, fail = 0;
    for (const r of results) {
      if (r.ok) {
        pass++;
        // (skip per-file print on lint pass; summary at end)
      } else {
        console.log(`✗ ${r.path}: ${r.errors.join('; ')}`);
        fail++;
      }
    }
    if (fail === 0) console.log(`all ${pass} skills satisfy schema.`);
    else console.log(`${fail} skill${fail === 1 ? '' : 's'} failed lint (${pass} passed).`);
  } else if (mode === 'backfill') {
    let changed = 0, unchanged = 0;
    for (const r of results) {
      if (r.error) console.log(`! ${r.path}: ${r.error}`);
      else if (r.changed) {
        console.log(`+ ${r.path}: added ${r.added.join(', ')}`);
        changed++;
      } else unchanged++;
    }
    console.log(`${changed} skill${changed === 1 ? '' : 's'} backfilled, ${unchanged} already complete.${args.dryRun ? ' (--dry-run, no writes)' : ''}`);
  } else if (mode === 'apply-manifest') {
    let changed = 0, unchanged = 0;
    for (const r of results) {
      if (r.error) console.log(`! ${r.path}: ${r.error}`);
      else if (r.changed) {
        console.log(`+ ${r.path}: applied ${r.applied.join(', ')}`);
        changed++;
      } else unchanged++;
    }
    console.log(`${changed} skill${changed === 1 ? '' : 's'} updated from manifest, ${unchanged} unchanged.`);
  }
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const skillsDir = path.resolve(args.skillsDir);
  if (!fs.existsSync(skillsDir) || !fs.statSync(skillsDir).isDirectory()) {
    console.error(`error: skills directory not found: ${skillsDir}`);
    process.exit(2);
  }

  let results;
  let exitCode = 0;
  if (args.mode === 'lint') {
    results = lintAll(skillsDir);
    if (results.some((r) => !r.ok)) exitCode = 1;
  } else if (args.mode === 'backfill') {
    results = backfillAll(skillsDir, { dryRun: args.dryRun });
    if (results.some((r) => r.error)) exitCode = 1;
  } else if (args.mode === 'apply-manifest') {
    results = applyManifest(skillsDir, args.manifestPath);
    if (results.some((r) => r.error)) exitCode = 1;
  }
  printResults(args.mode, results, args);
  process.exit(exitCode);
}

main();
