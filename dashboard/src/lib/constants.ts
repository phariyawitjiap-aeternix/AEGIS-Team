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
    name: "Mother Brain",
    emoji: "🧬",
    model: "opus",
    role: "Autonomous Controller",
    color: "#FF00FF",
  },
  {
    name: "Navi",
    emoji: "🧭",
    model: "opus",
    role: "Project Manager",
    color: "#00CED1",
  },
  {
    name: "Sage",
    emoji: "📐",
    model: "opus",
    role: "Architect",
    color: "#4B0082",
  },
  {
    name: "Bolt",
    emoji: "⚡",
    model: "sonnet",
    role: "Implementer",
    color: "#FFD700",
  },
  {
    name: "Vigil",
    emoji: "🛡️",
    model: "sonnet",
    role: "Code Reviewer",
    color: "#4682B4",
  },
  {
    name: "Havoc",
    emoji: "😈",
    model: "opus",
    role: "Devil's Advocate",
    color: "#DC143C",
  },
  {
    name: "Forge",
    emoji: "🔧",
    model: "haiku",
    role: "Researcher",
    color: "#B87333",
  },
  {
    name: "Pixel",
    emoji: "🎨",
    model: "sonnet",
    role: "UI Designer",
    color: "#E6E6FA",
  },
  {
    name: "Muse",
    emoji: "✍️",
    model: "haiku",
    role: "Writer",
    color: "#B76E79",
  },
  {
    name: "Sentinel",
    emoji: "🎯",
    model: "sonnet",
    role: "QA Strategist",
    color: "#355E3B",
  },
  {
    name: "Probe",
    emoji: "🔬",
    model: "haiku",
    role: "QA Executor",
    color: "#FFBF00",
  },
  {
    name: "Scribe",
    emoji: "📜",
    model: "haiku",
    role: "Compliance",
    color: "#F5DEB3",
  },
  {
    name: "Ops",
    emoji: "🚀",
    model: "sonnet",
    role: "DevOps",
    color: "#2C3539",
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
