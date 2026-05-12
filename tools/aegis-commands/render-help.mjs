#!/usr/bin/env node
// aegis-commands/render-help.mjs
// ─────────────────────────────────────────────────────────────────────────────
// Validate that .claude/commands/<name>.md frontmatter is consistent with
// the COMMAND_REGISTRY in registry.mjs, and emit help/listing output.
//
// Sprint:    v14-01 (S14-01-01)
// Source:    Hermes hermes_cli/commands.py:gateway_help_lines() pattern
//
// Usage:
//   node tools/aegis-commands/render-help.mjs validate    [exit 1 on mismatch]
//   node tools/aegis-commands/render-help.mjs list        [print canonical names, one per line]
//   node tools/aegis-commands/render-help.mjs help        [print human-readable help]
//   node tools/aegis-commands/render-help.mjs help --json [print machine-readable JSON]
// ─────────────────────────────────────────────────────────────────────────────

import { readFile, readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";

import {
  COMMAND_REGISTRY,
  COMMANDS_BY_CATEGORY,
  CATEGORIES,
  allCanonicalNames,
} from "./registry.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = resolve(__dirname, "..", "..");
const COMMANDS_DIR = join(REPO_ROOT, ".claude", "commands");

// ─────────────────────────────────────────────────────────────────────────────
// Frontmatter parser (minimal — only needs name/description/triggers)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Extract frontmatter block (between two `---` lines at the top of the file)
 * and parse the minimal subset we care about. Returns null if no frontmatter.
 */
function parseFrontmatter(content) {
  if (!content.startsWith("---\n") && !content.startsWith("---\r\n")) {
    return null;
  }
  const endIdx = content.indexOf("\n---", 4);
  if (endIdx === -1) return null;
  const block = content.slice(4, endIdx);

  const fm = { name: null, description: null, triggers_en: [], triggers_th: [] };
  const lines = block.split(/\r?\n/);

  let inTriggers = false;
  for (const raw of lines) {
    const line = raw.replace(/\s+$/, "");
    if (!line.trim()) {
      inTriggers = false;
      continue;
    }

    // Top-level keys
    const kv = line.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$/);
    if (kv && !line.startsWith("  ")) {
      const [, key, val] = kv;
      if (key === "triggers") {
        inTriggers = true;
        continue;
      }
      inTriggers = false;
      if (key === "name") fm.name = stripQuotes(val);
      else if (key === "description") fm.description = stripQuotes(val);
      continue;
    }

    // Nested (under triggers:)
    if (inTriggers) {
      const nested = line.match(/^\s+(en|th)\s*:\s*(.*)$/);
      if (nested) {
        const [, lang, val] = nested;
        const items = val.split(",").map((s) => s.trim()).filter(Boolean);
        if (lang === "en") fm.triggers_en = items;
        else fm.triggers_th = items;
      }
    }
  }
  return fm;
}

function stripQuotes(v) {
  v = v.trim();
  if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
    return v.slice(1, -1);
  }
  return v;
}

// ─────────────────────────────────────────────────────────────────────────────
// Validation
// ─────────────────────────────────────────────────────────────────────────────

async function readFilesystemCommands() {
  const entries = await readdir(COMMANDS_DIR);
  const mdFiles = entries.filter((f) => f.endsWith(".md"));
  const result = {};
  for (const f of mdFiles) {
    const name = f.replace(/\.md$/, "");
    const path = join(COMMANDS_DIR, f);
    const content = await readFile(path, "utf-8");
    const fm = parseFrontmatter(content);
    result[name] = { path, frontmatter: fm };
  }
  return result;
}

async function validate() {
  const fs = await readFilesystemCommands();
  const registryNames = new Set(allCanonicalNames());
  const fsNames = new Set(Object.keys(fs));

  const errors = [];

  // 1. registry ⊇ filesystem (every .md has a registry entry)
  for (const fname of fsNames) {
    if (!registryNames.has(fname)) {
      errors.push(
        `MISSING_FROM_REGISTRY: .claude/commands/${fname}.md exists but no CommandDef in registry`
      );
    }
  }

  // 2. filesystem ⊇ registry (every registry entry has an .md)
  for (const rname of registryNames) {
    if (!fsNames.has(rname)) {
      errors.push(
        `MISSING_FROM_FILESYSTEM: registry entry '${rname}' has no .claude/commands/${rname}.md`
      );
    }
  }

  // 3. frontmatter present on every .md
  for (const [name, { frontmatter }] of Object.entries(fs)) {
    if (!frontmatter) {
      errors.push(`NO_FRONTMATTER: .claude/commands/${name}.md has no YAML frontmatter`);
      continue;
    }
    if (!frontmatter.name) {
      errors.push(`FRONTMATTER_MISSING_NAME: .claude/commands/${name}.md`);
    } else if (frontmatter.name !== name) {
      errors.push(
        `FRONTMATTER_NAME_MISMATCH: .claude/commands/${name}.md has name='${frontmatter.name}' (expected '${name}')`
      );
    }
    if (!frontmatter.description) {
      errors.push(`FRONTMATTER_MISSING_DESCRIPTION: .claude/commands/${name}.md`);
    }
  }

  // 4. registry description ↔ filesystem description match (loose — both present)
  for (const cmd of COMMAND_REGISTRY) {
    const fsEntry = fs[cmd.name];
    if (!fsEntry || !fsEntry.frontmatter) continue;
    if (fsEntry.frontmatter.description &&
        fsEntry.frontmatter.description !== cmd.description) {
      // Soft warning, not error — descriptions allowed to drift if intentional
      errors.push(
        `WARN_DESCRIPTION_DRIFT: '${cmd.name}' registry vs .md description differ ` +
        `(registry='${cmd.description.slice(0, 40)}...', md='${fsEntry.frontmatter.description.slice(0, 40)}...')`
      );
    }
  }

  return errors;
}

// ─────────────────────────────────────────────────────────────────────────────
// Output
// ─────────────────────────────────────────────────────────────────────────────

function listAll() {
  for (const c of COMMAND_REGISTRY) {
    console.log(c.name);
  }
}

function helpHuman() {
  console.log("AEGIS Slash Commands (14 canonical, single source: tools/aegis-commands/registry.mjs)\n");
  for (const cat of CATEGORIES) {
    const cmds = COMMANDS_BY_CATEGORY[cat] || [];
    if (cmds.length === 0) continue;
    console.log(`── ${cat} ${"─".repeat(60 - cat.length)}`);
    for (const c of cmds) {
      const aliases = c.aliases.length > 0 ? `  (alias: ${c.aliases.join(", ")})` : "";
      const args = c.args_hint ? ` ${c.args_hint}` : "";
      console.log(`  /${c.name}${args}${aliases}`);
      console.log(`      ${c.description}`);
    }
    console.log("");
  }
}

function helpJson() {
  const out = {
    categories: CATEGORIES,
    commands: COMMAND_REGISTRY,
  };
  console.log(JSON.stringify(out, null, 2));
}

// ─────────────────────────────────────────────────────────────────────────────
// CLI entry
// ─────────────────────────────────────────────────────────────────────────────

const cmd = process.argv[2] || "help";
const flag = process.argv[3];

switch (cmd) {
  case "validate": {
    const errors = await validate();
    if (errors.length === 0) {
      console.log("OK: registry ⊇ filesystem and frontmatter consistent (14/14 commands)");
      process.exit(0);
    } else {
      const fatal = errors.filter((e) => !e.startsWith("WARN_"));
      const warn = errors.filter((e) => e.startsWith("WARN_"));
      for (const e of warn) console.error(`  ${e}`);
      for (const e of fatal) console.error(`  ${e}`);
      console.error(`\nFAIL: ${fatal.length} error(s), ${warn.length} warning(s)`);
      process.exit(fatal.length > 0 ? 1 : 0);
    }
    break;
  }
  case "list":
    listAll();
    break;
  case "help":
    if (flag === "--json") helpJson();
    else helpHuman();
    break;
  default:
    console.error(`Unknown command: ${cmd}`);
    console.error("Usage: render-help.mjs <validate|list|help> [--json]");
    process.exit(2);
}
