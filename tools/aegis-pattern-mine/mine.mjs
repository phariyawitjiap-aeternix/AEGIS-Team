#!/usr/bin/env node
// tools/aegis-pattern-mine/mine.mjs (sprint-v10-07)
//
// Deterministic pattern miner over .aegis/brain/logs/decision-audit.log.
// Reads judgment-source decisions, normalizes the questions, clusters by
// the normalized form, and emits a JSON report of clusters that meet
// occurrence + sprint-diversity thresholds.
//
// Idempotent: same input → byte-equal output across runs.
// No LLM. ISO 29110 audit-trail-safe.
//
// Usage:
//   node tools/aegis-pattern-mine/mine.mjs [--root <path>] [--min-occurrences N]
//                                          [--min-sprints N] [--source <tag>]
//                                          [--out <path>] [--quiet] [--json]
//
// Defaults:
//   --root             = cwd
//   --min-occurrences  = 3
//   --min-sprints      = 2
//   --source           = judgment
//   --out              = <root>/.aegis/brain/state/pattern-mine-report.json
//
// Exit codes:
//   0 — mine completed (report written; check report.cluster_count)
//   1 — IO / parse error
//   2 — usage error

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import {
  MINER_VERSION,
  readJsonlStrict,
  loadNormalizerRules,
  normalize,
  clusterId,
  compareClustersByImpact,
  extractSprint,
  modalAnswer,
  writeAtomic,
} from './lib.mjs';

// Default exclusion: questions that look like fixture/test pollution.
// Real-world questions almost never start with "tc test", "new session test",
// "S<n>-<n> judgment test", or contain "happy path after --help".
const DEFAULT_TEST_PATTERNS = [
  /^tc test\b/i,
  /^new session test\b/i,
  /\bjudgment test\b/i,
  /\btest happy path\b/i,
];

function parseArgs(argv) {
  const args = {
    root: process.cwd(),
    minOccurrences: 3,
    minSprints: 2,
    source: 'judgment',
    out: null,
    quiet: false,
    json: false,
    excludeTestFixtures: true,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    switch (a) {
      case '--root':                  args.root = path.resolve(argv[++i]); break;
      case '--min-occurrences':       args.minOccurrences = Number(argv[++i]); break;
      case '--min-sprints':           args.minSprints = Number(argv[++i]); break;
      case '--source':                args.source = argv[++i]; break;
      case '--out':                   args.out = path.resolve(argv[++i]); break;
      case '--include-test-fixtures': args.excludeTestFixtures = false; break;
      case '--quiet':                 args.quiet = true; break;
      case '--json':                  args.json = true; break;
      case '-h':
      case '--help':
        console.log('Usage: mine.mjs [--root <path>] [--min-occurrences N] [--min-sprints N]\n' +
                    '                [--source <tag>] [--out <path>] [--include-test-fixtures]\n' +
                    '                [--quiet] [--json]');
        process.exit(0);
        break;
      default:
        console.error(`Unknown arg: ${a}`);
        process.exit(2);
    }
  }
  return args;
}

function isTestFixture(question) {
  if (typeof question !== 'string') return false;
  for (const re of DEFAULT_TEST_PATTERNS) {
    if (re.test(question)) return true;
  }
  return false;
}

function mine({ root, minOccurrences, minSprints, source, excludeTestFixtures }) {
  const auditPath = path.join(root, '.aegis', 'brain', 'logs', 'decision-audit.log');
  const rulesPath = path.join(root, 'tools', 'aegis-pattern-mine', 'normalizer-rules.yaml');

  const entries = readJsonlStrict(auditPath);
  const rulesObj = loadNormalizerRules(rulesPath);

  // Filter to the target source, optionally drop test-fixture questions
  const filtered = entries.filter((e) => {
    if (!e || e.source !== source) return false;
    if (excludeTestFixtures && isTestFixture(e.question)) return false;
    return true;
  });

  // Cluster
  const clusters = new Map();
  for (const e of filtered) {
    const norm = normalize(e.question, rulesObj);
    if (!norm) continue;
    const cid = clusterId(norm);
    if (!clusters.has(cid)) {
      clusters.set(cid, {
        cluster_id: cid,
        normalized_question: norm,
        decision_ids: [],
        sprints_seen: new Set(),
        answers: [],
        confidences: [],
        timestamps: [],
      });
    }
    const c = clusters.get(cid);
    c.decision_ids.push(e.decision_id || `unknown-${c.decision_ids.length}`);
    const sprint = extractSprint(e);
    c.sprints_seen.add(sprint);
    if (typeof e.answer === 'string') c.answers.push(e.answer);
    if (typeof e.confidence === 'number') c.confidences.push(e.confidence);
    if (typeof e.ts === 'string') c.timestamps.push(e.ts);
  }

  // Apply thresholds
  const out = [];
  for (const c of clusters.values()) {
    const occurrences = c.decision_ids.length;
    const sprintCount = c.sprints_seen.size;
    if (occurrences < minOccurrences) continue;
    if (sprintCount < minSprints) continue;
    const avgConf = c.confidences.length
      ? c.confidences.reduce((s, x) => s + x, 0) / c.confidences.length
      : 0;
    const sprintsArray = [...c.sprints_seen].sort();
    const sortedTs = [...c.timestamps].sort();
    out.push({
      cluster_id: c.cluster_id,
      normalized_question: c.normalized_question,
      occurrences,
      decision_ids: [...c.decision_ids].sort(),
      sprints_seen: sprintsArray,
      modal_answer: modalAnswer(c.answers),
      avg_confidence: Math.round(avgConf * 1000) / 1000,
      first_seen_ts: sortedTs[0] || null,
      last_seen_ts: sortedTs[sortedTs.length - 1] || null,
      candidate_instinct_score: Math.round(
        (occurrences * avgConf * Math.min(sprintCount / 5, 1)) * 1000
      ) / 1000,
    });
  }
  out.sort(compareClustersByImpact);
  return out;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const reportPath = args.out || path.join(args.root, '.aegis', 'brain', 'state', 'pattern-mine-report.json');

  let clusters;
  try {
    clusters = mine(args);
  } catch (e) {
    console.error(`mine failed: ${e.message}`);
    process.exit(1);
  }

  const auditPath = path.join(args.root, '.aegis', 'brain', 'logs', 'decision-audit.log');
  const allEntries = fs.existsSync(auditPath) ? readJsonlStrict(auditPath) : [];
  const auditLines = allEntries.length;
  const sourceLines = allEntries.filter((e) => e && e.source === args.source).length;
  const fixtureLines = args.excludeTestFixtures
    ? allEntries.filter((e) => e && e.source === args.source && isTestFixture(e.question)).length
    : 0;

  const report = {
    miner_version: MINER_VERSION,
    generated_at_iso: new Date().toISOString(),
    source_filter: args.source,
    min_occurrences_threshold: args.minOccurrences,
    min_sprints_threshold: args.minSprints,
    exclude_test_fixtures: args.excludeTestFixtures,
    audit_lines_total: auditLines,
    audit_lines_for_source: sourceLines,
    audit_lines_excluded_as_fixture: fixtureLines,
    cluster_count: clusters.length,
    clusters,
  };

  // Stable JSON output (sorted keys at top level via the field order above;
  // clusters already sorted deterministically).
  const jsonOut = JSON.stringify(report, null, 2) + '\n';
  writeAtomic(reportPath, jsonOut);

  if (args.json) {
    process.stdout.write(JSON.stringify({
      ok: true,
      report_path: path.relative(args.root, reportPath),
      cluster_count: clusters.length,
      audit_lines_total: auditLines,
      audit_lines_for_source: sourceLines,
      audit_lines_excluded_as_fixture: fixtureLines,
    }) + '\n');
  } else if (!args.quiet) {
    const usedLines = sourceLines - fixtureLines;
    console.log(`mine: ${clusters.length} cluster(s) from ${usedLines}/${sourceLines} entries (source=${args.source}${args.excludeTestFixtures ? `, excluded ${fixtureLines} fixture` : ''})`);
    console.log(`report: ${path.relative(args.root, reportPath)}`);
    if (clusters.length > 0) {
      console.log(`top cluster: "${clusters[0].normalized_question.slice(0, 60)}" — ${clusters[0].occurrences}× across ${clusters[0].sprints_seen.length} sprint(s)`);
    }
  }
  process.exit(0);
}

main();
