// aegis-commands/registry.mjs
// ─────────────────────────────────────────────────────────────────────────────
// CommandDef central registry — single source of truth for all 14 AEGIS slash commands.
// Adapted from Hermes-Agent's hermes_cli/commands.py CommandDef pattern.
//
// Sprint:    v14-01 (S14-01-01)
// Source:    https://github.com/NousResearch/hermes-agent/blob/main/hermes_cli/commands.py
//
// To add a command: add a CommandDef entry to COMMAND_REGISTRY.
// To add an alias:  set aliases: [...] on the existing CommandDef.
//
// The .claude/commands/<name>.md files remain authoritative for documentation
// (Claude Code loads them at session start). This registry is the source-of-truth
// for METADATA — name, description, triggers, category, args_hint, aliases.
// render-help.mjs validates that .md frontmatter is consistent with this registry.
// ─────────────────────────────────────────────────────────────────────────────

/**
 * @typedef {Object} CommandDef
 * @property {string}    name         - Canonical name without slash (e.g. "aegis-status")
 * @property {string}    description  - One-line human-readable description
 * @property {string}    category     - "Setup" | "Workflow" | "Inspection" | "Lifecycle"
 * @property {string[]}  aliases      - Alternative names (without slash)
 * @property {string[]}  triggers_en  - English natural-language triggers
 * @property {string[]}  triggers_th  - Thai natural-language triggers
 * @property {string}    args_hint    - Argument placeholder (e.g. "<sprint-id>", "[--json]")
 * @property {string[]}  subcommands  - Tab-completable subcommands
 * @property {boolean}   gateway_only - True if not available in CLI (always false for AEGIS today)
 * @property {boolean}   cli_only     - True if not available in messaging (always true for AEGIS today)
 */

/**
 * Categories (mirror Hermes Session/Configuration/Tools&Skills/Info/Exit, adapted for AEGIS):
 *   Setup       — session bootstrap, mode/profile changes, framework upgrade
 *   Workflow    — work-execution commands (sprint, pipeline, team, deploy, breakdown)
 *   Inspection  — observation commands (status, verify, memory, linear)
 *   Lifecycle   — session-end commands (retro, handoff)
 */
export const CATEGORIES = Object.freeze([
  "Setup",
  "Workflow",
  "Inspection",
  "Lifecycle",
]);

/** @type {readonly Readonly<CommandDef>[]} */
export const COMMAND_REGISTRY = Object.freeze([
  // ── Setup ───────────────────────────────────────────────────────────────
  Object.freeze({
    name: "aegis-start",
    description: "Initialize AEGIS session — load brain, activate Nick Fury, auto-execute",
    category: "Setup",
    aliases: [],
    triggers_en: ["start session", "begin", "init", "start work"],
    triggers_th: ["เริ่ม session", "เริ่มงาน"],
    args_hint: "[--dashboard | --no-dashboard]",
    subcommands: [],
    gateway_only: false,
    cli_only: true,
  }),
  Object.freeze({
    name: "aegis-mode",
    description: "Switch profile tier and/or autonomy level for the current session",
    category: "Setup",
    aliases: [],
    triggers_en: ["mode", "switch mode", "change mode", "set autonomy", "set profile"],
    triggers_th: ["โหมด", "เปลี่ยนโหมด"],
    args_hint: "[L0|L1|L2|L3] [--profile=minimal|standard|full]",
    subcommands: [],
    gateway_only: false,
    cli_only: true,
  }),
  Object.freeze({
    name: "aegis-upgrade",
    description: "Upgrade this AEGIS project to the latest framework — runs install.sh --upgrade with backup + hook normalization + migration log",
    category: "Setup",
    aliases: [],
    triggers_en: ["upgrade", "upgrade aegis", "update framework", "sync framework"],
    triggers_th: ["อัพเกรด", "อัพเดทเฟรมเวิร์ค"],
    args_hint: "[--check-only | --yes | --source <path>]",
    subcommands: [],
    gateway_only: false,
    cli_only: true,
  }),

  // ── Workflow ─────────────────────────────────────────────────────────────
  Object.freeze({
    name: "aegis-pipeline",
    description: "Full analysis pipeline with phased subagent execution and quality gates",
    category: "Workflow",
    aliases: [],
    triggers_en: ["analyze", "full pipeline", "deep analysis", "run pipeline"],
    triggers_th: ["วิเคราะห์", "pipeline เต็ม"],
    args_hint: "[--qa | --flow]",
    subcommands: [],
    gateway_only: false,
    cli_only: true,
  }),
  Object.freeze({
    name: "aegis-team",
    description: "Spawn a team — build, review, or debate",
    category: "Workflow",
    aliases: [],
    triggers_en: ["team build", "team review", "team debate", "spawn team"],
    triggers_th: ["ทีม", "สปอนทีม"],
    args_hint: "<build|review|debate>",
    subcommands: ["build", "review", "debate"],
    gateway_only: false,
    cli_only: true,
  }),
  Object.freeze({
    name: "aegis-sprint",
    description: "Sprint management — plan, standup, review, retro, status, close. Full scrum lifecycle via Captain America.",
    category: "Workflow",
    aliases: ["scrum"],
    triggers_en: ["sprint", "scrum", "standup", "sprint plan", "sprint review", "sprint retro", "sprint status", "sprint close"],
    triggers_th: ["สปรินต์", "สครัม", "สแตนอัพ", "วางแผนสปรินต์"],
    args_hint: "<plan|standup|review|retro|status|close> [<sprint-id>]",
    subcommands: ["plan", "standup", "review", "retro", "status", "close"],
    gateway_only: false,
    cli_only: true,
  }),
  Object.freeze({
    name: "aegis-deploy",
    description: "Deploy pipeline — build, deploy, health check, monitor, rollback",
    category: "Workflow",
    aliases: ["ship", "release"],
    triggers_en: ["deploy", "ship", "release"],
    triggers_th: ["เดพลอย", "ปล่อย"],
    args_hint: "[--launch]",
    subcommands: [],
    gateway_only: false,
    cli_only: true,
  }),
  Object.freeze({
    name: "aegis-breakdown",
    description: "Decompose a user story into journeys, epics, tasks, and subtasks using Iron Man sub-agent",
    category: "Workflow",
    aliases: ["decompose"],
    triggers_en: ["breakdown", "decompose"],
    triggers_th: ["แตกงาน", "แยกย่อย"],
    args_hint: "<story-text-or-file>",
    subcommands: [],
    gateway_only: false,
    cli_only: true,
  }),

  // ── Inspection ───────────────────────────────────────────────────────────
  Object.freeze({
    name: "aegis-status",
    description: "Show team status dashboard — agents, tasks, progress, context, recent activity",
    category: "Inspection",
    aliases: ["dashboard"],
    triggers_en: ["status", "team status", "what is happening", "dashboard"],
    triggers_th: ["สถานะ", "ตอนนี้ทำอะไรอยู่"],
    args_hint: "[--kanban | --dashboard | --context]",
    subcommands: [],
    gateway_only: false,
    cli_only: true,
  }),
  Object.freeze({
    name: "aegis-verify",
    description: "Run verification pipeline — tests, linting, TODOs, git status, security check",
    category: "Inspection",
    aliases: ["check", "validate"],
    triggers_en: ["verify", "check", "validate", "run checks"],
    triggers_th: ["ตรวจสอบ", "verify"],
    args_hint: "[--doctor]",
    subcommands: [],
    gateway_only: false,
    cli_only: true,
  }),
  Object.freeze({
    name: "aegis-memory",
    description: "Memory management — status, recall, save, forget across memory tiers",
    category: "Inspection",
    aliases: ["recall", "remember"],
    triggers_en: ["memory", "recall", "remember", "what do you remember", "save memory"],
    triggers_th: ["ความจำ", "จำอะไรได้บ้าง", "บันทึกความจำ"],
    args_hint: "[--adr | --instinct | --distill | --evolve | --ingest | --lint | --iso]",
    subcommands: ["adr", "instinct", "distill", "evolve", "ingest", "lint", "iso"],
    gateway_only: false,
    cli_only: true,
  }),
  Object.freeze({
    name: "aegis-linear",
    description: "Linear integration — health check, project bootstrap, sprint sync (one-way kanban→Linear, milestone-based)",
    category: "Inspection",
    aliases: [],
    triggers_en: ["linear", "linear sync", "linear health", "sync to linear", "push to linear"],
    triggers_th: ["ลิเนียร์", "ซิงค์ลิเนียร์", "เช็คลิเนียร์"],
    args_hint: "<health|bootstrap|sync> [<sprint-id>]",
    subcommands: ["health", "bootstrap", "sync"],
    gateway_only: false,
    cli_only: true,
  }),
  Object.freeze({
    name: "aegis-decisions",
    description: "Search Nick Fury's decision-audit log — filter by source, date, or free-text query",
    category: "Inspection",
    aliases: [],
    triggers_en: ["decisions", "decision audit", "search decisions", "why did we"],
    triggers_th: ["ค้นการตัดสินใจ", "ทำไมเราถึง"],
    args_hint: "[--source <name>] [--since YYYY-MM-DD] [--tail N] <query>",
    subcommands: [],
    gateway_only: false,
    cli_only: true,
  }),
  Object.freeze({
    name: "aegis-goal",
    description: "Persistent goal POC — Hermes Ralph-loop pattern (judge-loop until done or 20-turn budget)",
    category: "Workflow",
    aliases: [],
    triggers_en: ["goal", "set goal", "persistent goal", "keep working"],
    triggers_th: ["เป้าหมาย", "ตั้งเป้า", "ทำต่อจนกว่า"],
    args_hint: "<text> | pause | resume | clear | status",
    subcommands: ["pause", "resume", "clear", "status"],
    gateway_only: false,
    cli_only: true,
  }),

  // ── Lifecycle ────────────────────────────────────────────────────────────
  Object.freeze({
    name: "aegis-retro",
    description: "Session retrospective — gather work, write diary, extract lessons learned",
    category: "Lifecycle",
    aliases: [],
    triggers_en: ["retrospective", "retro", "session end", "wrap up"],
    triggers_th: ["ย้อนมอง", "retrospective", "จบ session"],
    args_hint: "",
    subcommands: [],
    gateway_only: false,
    cli_only: true,
  }),
  Object.freeze({
    name: "aegis-handoff",
    description: "Create session handoff brief for the next session to pick up seamlessly",
    category: "Lifecycle",
    aliases: ["transfer"],
    triggers_en: ["handoff", "hand off", "transfer session", "pass the baton"],
    triggers_th: ["ส่งต่อ", "handoff", "ส่งงาน"],
    args_hint: "[<destination>]",
    subcommands: [],
    gateway_only: false,
    cli_only: true,
  }),
]);

// ─────────────────────────────────────────────────────────────────────────────
// Convenience accessors (match Hermes downstream-consumer pattern)
// ─────────────────────────────────────────────────────────────────────────────

/** Map: canonical name → CommandDef */
export const COMMANDS_BY_NAME = Object.freeze(
  Object.fromEntries(COMMAND_REGISTRY.map((c) => [c.name, c]))
);

/** Map: category → CommandDef[] */
export const COMMANDS_BY_CATEGORY = Object.freeze(
  CATEGORIES.reduce((acc, cat) => {
    acc[cat] = Object.freeze(COMMAND_REGISTRY.filter((c) => c.category === cat));
    return acc;
  }, /** @type {Record<string, readonly Readonly<CommandDef>[]>} */ ({}))
);

/** Set: every canonical name + alias (for fast `is-known-command` checks) */
export const ALL_COMMAND_NAMES = Object.freeze(
  new Set(COMMAND_REGISTRY.flatMap((c) => [c.name, ...c.aliases]))
);

/**
 * Resolve a typed name (with or without leading slash) to the canonical
 * CommandDef, honoring aliases. Returns undefined for unknown names.
 */
export function resolveCommand(typed) {
  if (!typed) return undefined;
  const name = typed.startsWith("/") ? typed.slice(1) : typed;
  const direct = COMMANDS_BY_NAME[name];
  if (direct) return direct;
  for (const c of COMMAND_REGISTRY) {
    if (c.aliases.includes(name)) return c;
  }
  return undefined;
}

/**
 * Return a shallow array of canonical names. Useful for help, validation,
 * and registry⊇filesystem checks.
 */
export function allCanonicalNames() {
  return COMMAND_REGISTRY.map((c) => c.name);
}
