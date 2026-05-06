#!/usr/bin/env node
// tools/aegis-doc-canon/lint.mjs (sprint-v12-01)
//
// Asserts every governance doc carries:
//   1. an HTML comment header `<!-- version: X.Y.Z -->` (semver)
//   2. a `<!-- Last updated: YYYY-MM-DD -->` line
//   3. a `## Changelog` section with a markdown table containing ≥ 1 row
//
// Exit codes:
//   0 — all checked docs pass
//   1 — at least one doc failed lint
//   2 — usage / IO error (e.g. given dir not found)
//
// Usage:
//   node tools/aegis-doc-canon/lint.mjs              # lints repo root
//   node tools/aegis-doc-canon/lint.mjs --dir <path> # lints custom dir (used by tests)
//   node tools/aegis-doc-canon/lint.mjs --json       # machine-readable output
//   node tools/aegis-doc-canon/lint.mjs --quiet      # only print failures + summary
//
// Spec: AEGIS Knowledge-Layer Mega Plan v1.1, sprint v12-01 story D.

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const DEFAULT_DOCS = [
  'CLAUDE.md',
  'CLAUDE_safety.md',
  'CLAUDE_agents.md',
  'CLAUDE_skills.md',
  'CLAUDE_lessons.md',
  'DoD.md',
  'ARCHITECTURE.md',
];

const VERSION_RE = /^<!--\s*version:\s*(\d+\.\d+\.\d+)\s*-->/m;
const LAST_UPDATED_RE = /^<!--\s*Last updated:\s*(\d{4}-\d{2}-\d{2})\s*-->/m;
const CHANGELOG_HEADING_RE = /^##\s+Changelog\s*$/m;

function parseArgs(argv) {
  const args = { dir: null, json: false, quiet: false, docs: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dir') {
      args.dir = argv[++i];
    } else if (a === '--json') {
      args.json = true;
    } else if (a === '--quiet') {
      args.quiet = true;
    } else if (a === '--docs') {
      args.docs = argv[++i].split(',').map((s) => s.trim()).filter(Boolean);
    } else if (a === '--help' || a === '-h') {
      console.log(
        'Usage: lint.mjs [--dir <path>] [--docs <a.md,b.md>] [--json] [--quiet]'
      );
      process.exit(0);
    } else {
      console.error(`Unknown arg: ${a}`);
      process.exit(2);
    }
  }
  return args;
}

function findChangelogRowCount(body) {
  // Find the "## Changelog" heading, then look for the next markdown table.
  // A markdown table with header + separator + ≥ 1 row matches `| ... | ... |\n|---|---|---|\n| row1 ...`
  const headingIdx = body.search(CHANGELOG_HEADING_RE);
  if (headingIdx === -1) return -1; // missing
  const tail = body.slice(headingIdx);
  const lines = tail.split('\n');
  let inTable = false;
  let rowCount = 0;
  let pastSeparator = false;
  for (const line of lines.slice(1)) {
    // skip the heading line
    const isPipeRow = /^\s*\|.*\|\s*$/.test(line);
    if (!isPipeRow) {
      if (inTable && pastSeparator) break; // table ended
      if (inTable && !pastSeparator) {
        // table malformed — header without separator
        return 0;
      }
      continue;
    }
    if (!inTable) {
      inTable = true;
      pastSeparator = false;
      continue;
    }
    if (!pastSeparator) {
      // next pipe row should be the separator line: ---
      if (/^\s*\|[\s|:-]+\|\s*$/.test(line)) {
        pastSeparator = true;
        continue;
      } else {
        return 0; // malformed
      }
    }
    rowCount++;
  }
  return rowCount;
}

function lintFile(filePath) {
  const errors = [];
  let body;
  try {
    body = fs.readFileSync(filePath, 'utf8');
  } catch (e) {
    return {
      ok: false,
      errors: [`cannot read file: ${e.code || e.message}`],
      version: null,
      lastUpdated: null,
      changelogRows: 0,
    };
  }
  // Look only in the first 30 lines for the version + last-updated headers.
  const head = body.split('\n').slice(0, 30).join('\n');
  const versionMatch = head.match(VERSION_RE);
  const lastUpdatedMatch = head.match(LAST_UPDATED_RE);
  if (!versionMatch) errors.push('missing <!-- version: X.Y.Z --> header (first 30 lines)');
  if (!lastUpdatedMatch) errors.push('missing <!-- Last updated: YYYY-MM-DD --> header (first 30 lines)');
  const changelogRows = findChangelogRowCount(body);
  if (changelogRows === -1) errors.push('missing "## Changelog" section');
  else if (changelogRows === 0) errors.push('Changelog table has 0 data rows (need ≥ 1)');
  return {
    ok: errors.length === 0,
    errors,
    version: versionMatch ? versionMatch[1] : null,
    lastUpdated: lastUpdatedMatch ? lastUpdatedMatch[1] : null,
    changelogRows: Math.max(0, changelogRows),
  };
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const baseDir = args.dir
    ? path.resolve(args.dir)
    : path.resolve(process.cwd());
  if (!fs.existsSync(baseDir) || !fs.statSync(baseDir).isDirectory()) {
    console.error(`error: not a directory: ${baseDir}`);
    process.exit(2);
  }
  const docList = args.docs ?? DEFAULT_DOCS;
  const results = [];
  for (const rel of docList) {
    const full = path.join(baseDir, rel);
    if (!fs.existsSync(full)) {
      results.push({
        path: rel,
        ok: false,
        errors: ['file not found'],
        version: null,
        lastUpdated: null,
        changelogRows: 0,
      });
      continue;
    }
    const r = lintFile(full);
    results.push({ path: rel, ...r });
  }

  const failed = results.filter((r) => !r.ok);

  if (args.json) {
    process.stdout.write(
      JSON.stringify(
        {
          ok: failed.length === 0,
          checked: results.length,
          failed: failed.length,
          results,
        },
        null,
        2
      ) + '\n'
    );
  } else {
    for (const r of results) {
      if (r.ok) {
        if (!args.quiet) {
          console.log(
            `✓ ${r.path.padEnd(20)} — version ${r.version}, changelog ${r.changelogRows} row${r.changelogRows === 1 ? '' : 's'}`
          );
        }
      } else {
        console.log(`✗ ${r.path.padEnd(20)} — ${r.errors.join('; ')}`);
      }
    }
    const ok = results.length - failed.length;
    if (failed.length === 0) {
      console.log(`all ${ok} governance doc${ok === 1 ? '' : 's'} pass.`);
    } else {
      console.log(
        `${failed.length} governance doc${failed.length === 1 ? '' : 's'} failed lint (${ok} passed).`
      );
    }
  }

  process.exit(failed.length === 0 ? 0 : 1);
}

main();
