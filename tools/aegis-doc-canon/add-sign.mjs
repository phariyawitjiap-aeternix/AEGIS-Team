#!/usr/bin/env node
// tools/aegis-doc-canon/add-sign.mjs (sprint-v12-02)
//
// Append a Sign (Trigger / Do / Why) to GUARDRAILS.md.
//
// Modes:
//   - Interactive: prompts on stdin for title / trigger / do / why
//   - Non-interactive: --non-interactive --title ... --trigger ... --do ... --why ...
//
// Validation: all 4 fields must be non-empty.
// Idempotency: bumps the file's `<!-- version: X.Y.Z -->` patch number + adds a Changelog row.
// Insertion point: appends as the last `### <title>` block under `## Signs` (above any
// trailing `---` or `## How to add a Sign` heading — whichever comes first).
//
// Spec: AEGIS Knowledge-Layer Mega Plan v1.1, sprint v12-02 story C.

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import readline from 'node:readline';

const DEFAULT_TARGET = 'GUARDRAILS.md';

function parseArgs(argv) {
  const args = {
    target: null,
    title: null,
    trigger: null,
    do_: null,
    why: null,
    nonInteractive: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    switch (a) {
      case '--target':          args.target = argv[++i]; break;
      case '--title':           args.title = argv[++i]; break;
      case '--trigger':         args.trigger = argv[++i]; break;
      case '--do':              args.do_ = argv[++i]; break;
      case '--why':             args.why = argv[++i]; break;
      case '--non-interactive': args.nonInteractive = true; break;
      case '--help':
      case '-h':
        console.log(
          'Usage: add-sign.mjs [--target GUARDRAILS.md] [--non-interactive --title <t> --trigger <t> --do <d> --why <w>]'
        );
        process.exit(0);
        break;
      default:
        console.error(`Unknown arg: ${a}`);
        process.exit(2);
    }
  }
  return args;
}

function prompt(rl, question) {
  return new Promise((resolve) => rl.question(question, (a) => resolve(a)));
}

async function gatherInteractive() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  console.log('Add a Sign to GUARDRAILS.md (Ctrl+C to abort).\n');
  const title = (await prompt(rl, 'Title (short noun phrase): ')).trim();
  const trigger = (await prompt(rl, 'Trigger (observable cue): ')).trim();
  const do_ = (await prompt(rl, 'Do (the action that resolves it): ')).trim();
  const why = (await prompt(rl, 'Why (failure mode + incident): ')).trim();
  rl.close();
  return { title, trigger, do_, why };
}

function validateFields({ title, trigger, do_, why }) {
  const missing = [];
  if (!title) missing.push('title');
  if (!trigger) missing.push('trigger');
  if (!do_) missing.push('do');
  if (!why) missing.push('why');
  return missing;
}

function bumpPatch(versionStr) {
  const m = versionStr.match(/^(\d+)\.(\d+)\.(\d+)$/);
  if (!m) return null;
  const [, maj, min, pat] = m;
  return `${maj}.${min}.${Number(pat) + 1}`;
}

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

function buildSignBlock({ title, trigger, do_, why }) {
  return [
    '',
    `### ${title}`,
    '',
    `- **Trigger:** ${trigger}`,
    `- **Do:** ${do_}`,
    `- **Why:** ${why}`,
    '',
  ].join('\n');
}

function buildChangelogRow(newVersion, title) {
  return `| ${todayISO()} | ${newVersion} | Sign added: ${title} |`;
}

// Insert a string `inserted` into `body` immediately before the line whose
// trimmed content matches `marker`. Throws if marker not found.
function insertBeforeLine(body, marker, inserted) {
  const lines = body.split('\n');
  const idx = lines.findIndex((l) => l.trim() === marker);
  if (idx === -1) throw new Error(`marker not found: "${marker}"`);
  const before = lines.slice(0, idx).join('\n');
  const after = lines.slice(idx).join('\n');
  return before + (before.endsWith('\n') ? '' : '\n') + inserted + (inserted.endsWith('\n') ? '' : '\n') + after;
}

function findInsertionMarker(body) {
  // Prefer inserting before the next top-level heading after `## Signs`.
  // The two known candidates in GUARDRAILS.md are:
  //   1. "---"  (the separator above "## How to add a Sign")
  //   2. "## How to add a Sign"
  // We pick whichever appears first AFTER the `## Signs` heading.
  const lines = body.split('\n');
  const signsIdx = lines.findIndex((l) => l.trim() === '## Signs');
  if (signsIdx === -1) throw new Error('## Signs heading not found in target file');
  for (let i = signsIdx + 1; i < lines.length; i++) {
    const t = lines[i].trim();
    if (t === '---' || t === '## How to add a Sign' || /^##\s+\S/.test(t)) {
      return t; // first marker after Signs heading
    }
  }
  throw new Error('no insertion marker found after "## Signs"');
}

function applyVersionBump(body, newVersion) {
  return body.replace(
    /^<!--\s*version:\s*\d+\.\d+\.\d+\s*-->/m,
    `<!-- version: ${newVersion} -->`
  ).replace(
    /^<!--\s*Last updated:\s*\d{4}-\d{2}-\d{2}\s*-->/m,
    `<!-- Last updated: ${todayISO()} -->`
  );
}

function applyChangelogRow(body, row) {
  // Insert the row immediately under the changelog separator line `|------|---------|--------|`
  // (or any pipe-separator-row pattern). We insert right after the FIRST separator under "## Changelog".
  const lines = body.split('\n');
  const clIdx = lines.findIndex((l) => l.trim() === '## Changelog');
  if (clIdx === -1) throw new Error('## Changelog heading not found');
  // Find first separator line (|---|---|---|) AFTER the heading
  let sepIdx = -1;
  for (let i = clIdx + 1; i < Math.min(lines.length, clIdx + 10); i++) {
    if (/^\s*\|[\s|:-]+\|\s*$/.test(lines[i])) {
      sepIdx = i;
      break;
    }
  }
  if (sepIdx === -1) throw new Error('Changelog separator row not found within 10 lines of heading');
  const before = lines.slice(0, sepIdx + 1);
  const after = lines.slice(sepIdx + 1);
  return [...before, row, ...after].join('\n');
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const target = path.resolve(args.target ?? DEFAULT_TARGET);
  if (!fs.existsSync(target)) {
    console.error(`error: target not found: ${target}`);
    process.exit(2);
  }

  let fields;
  if (args.nonInteractive) {
    fields = {
      title: args.title?.trim() || '',
      trigger: args.trigger?.trim() || '',
      do_: args.do_?.trim() || '',
      why: args.why?.trim() || '',
    };
  } else {
    fields = await gatherInteractive();
  }

  const missing = validateFields(fields);
  if (missing.length > 0) {
    console.error(`error: missing required field(s): ${missing.join(', ')}`);
    process.exit(1);
  }

  const body = fs.readFileSync(target, 'utf8');
  const versionMatch = body.match(/^<!--\s*version:\s*(\d+\.\d+\.\d+)\s*-->/m);
  if (!versionMatch) {
    console.error('error: target has no <!-- version: --> header');
    process.exit(2);
  }
  const newVersion = bumpPatch(versionMatch[1]);
  if (!newVersion) {
    console.error(`error: cannot parse version: ${versionMatch[1]}`);
    process.exit(2);
  }

  // Build the new body via three transforms: insert sign, bump version, add changelog row.
  const marker = findInsertionMarker(body);
  const signBlock = buildSignBlock(fields);
  let next = insertBeforeLine(body, marker, signBlock);
  next = applyVersionBump(next, newVersion);
  next = applyChangelogRow(next, buildChangelogRow(newVersion, fields.title));

  // Atomic write (temp + rename)
  const tmp = target + '.tmp';
  fs.writeFileSync(tmp, next);
  fs.renameSync(tmp, target);

  console.log(`✓ Sign appended: "${fields.title}" — version ${versionMatch[1]} → ${newVersion}`);
}

main().catch((e) => {
  console.error(`error: ${e.message}`);
  process.exit(2);
});
