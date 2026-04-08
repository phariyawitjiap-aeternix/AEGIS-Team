import path from "path";

// ---- Paths ----
export const AEGIS_ROOT =
  process.env.AEGIS_ROOT || path.resolve(process.cwd(), "..");
export const BRAIN_DIR = path.join(AEGIS_ROOT, "_aegis-brain");
export const OUTPUT_DIR = path.join(AEGIS_ROOT, "_aegis-output");

// ---- Agent Registry ----
export interface AgentDef {
  name: string;
  emoji: string;
  model: "opus" | "sonnet" | "haiku";
  role: string;
  color: string;
}

export const AGENTS: AgentDef[] = [
  {
    name: "Nick Fury",
    emoji: "🧬",
    model: "opus",
    role: "Autonomous Controller",
    color: "#1C1C1C", // Black trench coat / eye patch
  },
  {
    name: "Captain America",
    emoji: "🛡️",
    model: "opus",
    role: "Navigator / Team Lead",
    color: "#1C3F94", // Cap blue (with the star)
  },
  {
    name: "Iron Man",
    emoji: "🤖",
    model: "opus",
    role: "Architect",
    color: "#A6192E", // Hot rod red armor
  },
  {
    name: "Spider-Man",
    emoji: "🕷️",
    model: "sonnet",
    role: "Implementer",
    color: "#E62429", // Spidey suit red
  },
  {
    name: "Black Panther",
    emoji: "🐾",
    model: "sonnet",
    role: "Code Reviewer",
    color: "#3A1C71", // Wakandan vibranium purple
  },
  {
    name: "Loki",
    emoji: "😈",
    model: "opus",
    role: "Devil's Advocate",
    color: "#1F7A3D", // Loki green cape/helmet
  },
  {
    name: "Beast",
    emoji: "🦁",
    model: "haiku",
    role: "Researcher",
    color: "#1E5BC6", // Hank McCoy blue fur
  },
  {
    name: "Wasp",
    emoji: "🐝",
    model: "sonnet",
    role: "UX Designer",
    color: "#FFC72C", // Wasp yellow + black
  },
  {
    name: "Songbird",
    emoji: "🎵",
    model: "haiku",
    role: "Writer",
    color: "#FF1493", // Sonic pink
  },
  {
    name: "War Machine",
    emoji: "⚙️",
    model: "sonnet",
    role: "QA Lead",
    color: "#5A5A5A", // Gunmetal military gray
  },
  {
    name: "Vision",
    emoji: "👁️",
    model: "haiku",
    role: "QA Executor",
    color: "#FF8F00", // Vision cape gold/amber
  },
  {
    name: "Coulson",
    emoji: "📋",
    model: "haiku",
    role: "Compliance",
    color: "#003F7F", // S.H.I.E.L.D. agent navy
  },
  {
    name: "Thor",
    emoji: "⚡",
    model: "sonnet",
    role: "DevOps",
    color: "#B0C4DE", // Mjolnir silver
  },
];

// ---- Event Type Colors ----
export const EVENT_COLORS: Record<string, string> = {
  SESSION_START: "bg-blue-500",
  TASK_DONE: "bg-green-500",
  GATE1_PASS: "bg-emerald-500",
  GATE_PASS: "bg-emerald-500",
  GATE_FAIL: "bg-red-500",
  DECISION: "bg-purple-500",
  PROGRESS: "bg-gray-500",
  SPEC_WRITTEN: "bg-cyan-500",
  TASK_WIP: "bg-yellow-500",
  BREAKDOWN: "bg-indigo-500",
  SPRINT_START: "bg-blue-600",
  SESSION_WRAP: "bg-gray-600",
};

// ---- Priority Colors ----
export const PRIORITY_COLORS: Record<string, string> = {
  critical: "text-red-400 bg-red-400/10 border-red-400/30",
  high: "text-orange-400 bg-orange-400/10 border-orange-400/30",
  medium: "text-blue-400 bg-blue-400/10 border-blue-400/30",
  low: "text-gray-400 bg-gray-400/10 border-gray-400/30",
};

// ---- Status Colors ----
export const STATUS_COLORS: Record<string, string> = {
  TODO: "bg-gray-500",
  IN_PROGRESS: "bg-blue-500",
  IN_REVIEW: "bg-purple-500",
  QA: "bg-yellow-500",
  DONE: "bg-green-500",
  BLOCKED: "bg-red-500",
};
