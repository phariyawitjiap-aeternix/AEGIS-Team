#!/usr/bin/env node
// tools/aegis-pattern-mine/propose.mjs (sprint-v10-07)
//
// Read pattern-mine-report.json, write top-N clusters as instinct candidates
// at .aegis/brain/instincts/_proposed/<cluster_id>.yaml.
//
// Filters out clusters whose normalized question is already covered by a
// promoted instinct (instincts/<id>.yaml) — re-mine prevention.
//
// Idempotent: same input → same output. Re-running doesn't duplicate.
//
// Usage:
//   node tools/aegis-pattern-mine/propose.mjs [--root <path>] [--top-n N]
//                                              [--report <path>] [--out-dir <path>]
//                                              [--quiet] [--json]
//
// Exit codes:
//   0 — done (any combination of writes / skips)
//   1 — IO / parse error
//   2 — usage error

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { writeAtomic } from './lib.mjs';

function parseArgs(argv) {
  const args = {
    root: process.cwd(),
    topN: 3,
    report: null,
    outDir: null,
    quiet: false,
    json: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    switch (a) {
      case '--root':    args.root = path.resolve(argv[++i]); break;
      case '--top-n':   args.topN = Number(argv[++i]); break;
      case '--report':  args.report = path.resolve(argv[++i]); break;
      case '--out-dir': args.outDir = path.resolve(argv[++i]); break;
      case '--quiet':   args.quiet = true; break;
      case '--json':    args.json = true; break;
      case '-h':
      case '--help':
        console.log('Usage: propose.mjs [--root <path>] [--top-n N] [--report <path>] [--out-dir <path>] [--quiet] [--json]');
        process.exit(0);
        break;
      default:
        console.error(`Unknown arg: ${a}`);
        process.exit(2);
    }
  }
  return args;
}

// Read existing promoted instincts to filter against. We treat any *.yaml
// in instincts/ (excluding _proposed/) as "already promoted" — match by
// normalized_question if present, otherwise by trigger_pattern.
function loadPromotedInstincts(instinctsDir) {
  if (!fs.existsSync(instinctsDir)) return [];
  const files = fs.readdirSync(instinctsDir, { withFileTypes: true })
    .filter((d) => d.isFile() && d.name.endsWith('.yaml'))
    .map((d) => path.join(instinctsDir, d.name));
  const out = [];
  for (const f of files) {
    try {
      const body = fs.readFileSync(f, 'utf8');
      // Minimal YAML peek: extract `trigger_pattern: ...` or `normalized_question: ...`
      const tp = body.match(/^\s*trigger_pattern:\s*['"]?(.+?)['"]?\s*$/m);
      const nq = body.match(/^\s*normalized_question:\s*['"]?(.+?)['"]?\s*$/m);
      const n = body.match(/^\s*name:\s*['"]?(.+?)['"]?\s*$/m);
      out.push({
        path: f,
        trigger_pattern: tp ? tp[1] : null,
        normalized_question: nq ? nq[1] : null,
        name: n ? n[1] : path.basename(f, '.yaml'),
      });
    } catch (e) {
      // Skip unparseable
    }
  }
  return out;
}

function clusterAlreadyCovered(cluster, promoted) {
  for (const p of promoted) {
    if (p.normalized_question && p.normalized_question === cluster.normalized_question) {
      return p;
    }
    if (p.trigger_pattern && p.trigger_pattern === cluster.normalized_question) {
      return p;
    }
  }
  return null;
}

function buildYaml(cluster) {
  // Hand-rolled minimal YAML — readable, no js-yaml dep
  const lines = [
    'status: pending',
    `proposed_at: ${new Date().toISOString().slice(0, 10)}`,
    'source: aegis-pattern-mine',
    `cluster_id: ${cluster.cluster_id}`,
    `trigger_pattern: ${quote(cluster.normalized_question)}`,
    `recommendation: ${quote(cluster.modal_answer || '(no modal answer)')}`,
    `confidence: ${cluster.avg_confidence}`,
    `candidate_instinct_score: ${cluster.candidate_instinct_score}`,
    `occurrences: ${cluster.occurrences}`,
    `sprints_seen:`,
    ...(cluster.sprints_seen.map((s) => `  - ${s}`)),
    `decision_ids:`,
    ...(cluster.decision_ids.slice(0, 5).map((d) => `  - ${d}`)),
    `first_seen_ts: ${cluster.first_seen_ts || 'unknown'}`,
    `last_seen_ts: ${cluster.last_seen_ts || 'unknown'}`,
  ];
  return lines.join('\n') + '\n';
}

function quote(s) {
  if (typeof s !== 'string') return JSON.stringify(s);
  // Quote with double-quotes if contains special chars; otherwise bare
  if (/[":{}\[\],&*#?|<>=!%@`\n]/.test(s) || s.startsWith(' ') || s.endsWith(' ')) {
    return JSON.stringify(s); // JSON.stringify gives valid YAML double-quote string
  }
  return JSON.stringify(s);
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const reportPath = args.report || path.join(args.root, '.aegis', 'brain', 'state', 'pattern-mine-report.json');
  const outDir = args.outDir || path.join(args.root, '.aegis', 'brain', 'instincts', '_proposed');
  const promotedDir = path.join(args.root, '.aegis', 'brain', 'instincts');

  if (!fs.existsSync(reportPath)) {
    console.error(`error: report not found: ${reportPath}\n  hint: run mine.mjs first`);
    process.exit(1);
  }

  let report;
  try {
    report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
  } catch (e) {
    console.error(`error: cannot parse report at ${reportPath}: ${e.message}`);
    process.exit(1);
  }

  const promoted = loadPromotedInstincts(promotedDir);
  const clusters = (report.clusters || []).slice(0, args.topN);

  const written = [];
  const skippedCovered = [];
  const skippedUnchanged = [];

  fs.mkdirSync(outDir, { recursive: true });

  for (const c of clusters) {
    const covered = clusterAlreadyCovered(c, promoted);
    if (covered) {
      skippedCovered.push({ cluster_id: c.cluster_id, already_in: path.relative(args.root, covered.path) });
      continue;
    }
    const outPath = path.join(outDir, `${c.cluster_id}.yaml`);
    const content = buildYaml(c);
    if (fs.existsSync(outPath)) {
      const existing = fs.readFileSync(outPath, 'utf8');
      // Idempotent: only the proposed_at line varies day-to-day. Compare ignoring it.
      const stripDate = (s) => s.replace(/^proposed_at:.*$/m, '').replace(/^last_seen_ts:.*$/m, '').replace(/^first_seen_ts:.*$/m, '');
      if (stripDate(existing) === stripDate(content)) {
        skippedUnchanged.push({ cluster_id: c.cluster_id, path: path.relative(args.root, outPath) });
        continue;
      }
    }
    writeAtomic(outPath, content);
    written.push({ cluster_id: c.cluster_id, path: path.relative(args.root, outPath) });
  }

  if (args.json) {
    process.stdout.write(JSON.stringify({
      ok: true,
      written: written.length,
      skipped_covered: skippedCovered.length,
      skipped_unchanged: skippedUnchanged.length,
      written_paths: written.map((w) => w.path),
    }) + '\n');
  } else if (!args.quiet) {
    console.log(`propose: ${written.length} written, ${skippedCovered.length} skipped (already promoted), ${skippedUnchanged.length} unchanged`);
    for (const w of written) console.log(`  + ${w.path}`);
    for (const s of skippedCovered) console.log(`  = ${s.cluster_id} (covered by ${s.already_in})`);
  }
  process.exit(0);
}

main();
