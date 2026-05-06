// tools/aegis-pattern-mine/lib.mjs (sprint-v10-07)
//
// Shared helpers for the pattern miner:
//   - JSONL line-stream reader
//   - Question normalizer (loads versioned rules)
//   - Stable SHA256 cluster keys
//   - Sort comparators for byte-equal output
//
// Spec: AEGIS Knowledge-Layer Mega Plan derivation; sprint-v10-07 plan.md.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export const MINER_VERSION = '1.0.0';

// ─── JSONL reader ──────────────────────────────────────────────────────────

export function readJsonlStrict(filePath) {
  if (!fs.existsSync(filePath)) return [];
  const body = fs.readFileSync(filePath, 'utf8');
  if (body.length === 0) return [];
  const out = [];
  const lines = body.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.length === 0) continue;
    try {
      out.push(JSON.parse(line));
    } catch (e) {
      // Tolerant: skip malformed lines. The decision-audit log is append-only;
      // a corrupt line shouldn't kill the miner.
      console.error(`warn: skipping malformed JSONL at ${filePath}:${i + 1}`);
    }
  }
  return out;
}

// ─── Normalizer ────────────────────────────────────────────────────────────

const _ruleCache = new Map();

export function loadNormalizerRules(rulesPath) {
  if (_ruleCache.has(rulesPath)) return _ruleCache.get(rulesPath);
  if (!fs.existsSync(rulesPath)) {
    throw new Error(`normalizer rules not found: ${rulesPath}`);
  }
  // Minimal YAML parser — sufficient for the shape of normalizer-rules.yaml.
  // We avoid js-yaml to keep zero-dep.
  const body = fs.readFileSync(rulesPath, 'utf8');
  const lines = body.split('\n');
  let version = null;
  const rules = [];
  let inRules = false;
  let current = null;
  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    const stripped = raw.replace(/#.*$/, '').replace(/\s+$/, '');
    if (stripped.length === 0) continue;
    const m = stripped.match(/^version:\s*['"]?([\d.]+)['"]?/);
    if (m) { version = m[1]; continue; }
    if (/^rules:/.test(stripped)) { inRules = true; continue; }
    if (!inRules) continue;
    // Each rule entry starts with "  - pattern:" (2-space indent)
    const ruleStart = stripped.match(/^\s*-\s+pattern:\s*['"](.*)['"]\s*$/);
    if (ruleStart) {
      if (current) rules.push(current);
      current = { pattern: ruleStart[1], replace: '', flags: 'g' };
      continue;
    }
    const replaceLine = stripped.match(/^\s+replace:\s*['"](.*)['"]\s*$/);
    if (replaceLine && current) { current.replace = replaceLine[1]; continue; }
    const flagsLine = stripped.match(/^\s+flags:\s*['"](.*)['"]\s*$/);
    if (flagsLine && current) { current.flags = flagsLine[1]; continue; }
  }
  if (current) rules.push(current);
  if (rules.length === 0) {
    throw new Error(`no rules parsed from ${rulesPath}`);
  }
  // Compile each rule's regex
  const compiled = rules.map((r) => {
    try {
      // Always force case-insensitive since we lowercase first; the lowercase
      // step makes the 'i' flag redundant but tolerated.
      return { ...r, regex: new RegExp(r.pattern, r.flags || 'g') };
    } catch (e) {
      throw new Error(`bad regex in ${rulesPath}: ${r.pattern} — ${e.message}`);
    }
  });
  const result = { version, rules: compiled };
  _ruleCache.set(rulesPath, result);
  return result;
}

export function normalize(question, rulesObj) {
  let s = String(question || '').toLowerCase();
  for (const r of rulesObj.rules) {
    s = s.replace(r.regex, r.replace);
  }
  return s.trim();
}

// ─── Cluster keys ──────────────────────────────────────────────────────────

export function clusterId(normalizedQuestion) {
  return crypto.createHash('sha256')
    .update(normalizedQuestion)
    .digest('hex')
    .slice(0, 12);
}

// ─── Sort comparators ──────────────────────────────────────────────────────

export function compareClustersByImpact(a, b) {
  // Primary: occurrences DESC
  if (a.occurrences !== b.occurrences) return b.occurrences - a.occurrences;
  // Tiebreaker: cluster_id ASC (stable)
  if (a.cluster_id < b.cluster_id) return -1;
  if (a.cluster_id > b.cluster_id) return 1;
  return 0;
}

// ─── Sprint extraction (best-effort) ───────────────────────────────────────
//
// A decision-audit entry may carry a `source_id` like "sprint-v9-02" or an
// `adr:sprint-v9-04` source tag. We try a few patterns to extract the sprint
// for diversity counting.

export function extractSprint(entry) {
  // Try source_id first (most specific)
  if (entry.source_id) {
    const m = entry.source_id.match(/(?:sprint-)?(v\d+-\d+|s\d+-\d+)/i);
    if (m) return m[1].toLowerCase();
  }
  // Fall back to source tag
  if (typeof entry.source === 'string') {
    const m = entry.source.match(/(?:sprint-)?(v\d+-\d+|s\d+-\d+)/i);
    if (m) return m[1].toLowerCase();
  }
  // Fall back to question text
  if (typeof entry.question === 'string') {
    const m = entry.question.match(/(v\d+-\d+|s\d+-\d+)/i);
    if (m) return m[1].toLowerCase();
  }
  return 'unknown';
}

// ─── Modal answer extractor ────────────────────────────────────────────────
//
// Given a list of answers, return the most-frequent one. Ties broken by first
// occurrence in input order (stable).

export function modalAnswer(answers) {
  if (answers.length === 0) return null;
  const counts = new Map();
  for (const a of answers) counts.set(a, (counts.get(a) || 0) + 1);
  let best = answers[0];
  let bestCount = counts.get(best);
  for (const [a, c] of counts.entries()) {
    if (c > bestCount) { best = a; bestCount = c; }
  }
  return best;
}

// ─── Atomic file write ─────────────────────────────────────────────────────

export function writeAtomic(filePath, content) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const tmp = filePath + '.tmp';
  fs.writeFileSync(tmp, content);
  fs.renameSync(tmp, filePath);
}
