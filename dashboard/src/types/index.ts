// ---- API Envelope ----
export interface ApiResponse<T> {
  ok: boolean;
  data: T;
  error?: string;
  timestamp: string;
}

// ---- Task Meta (from tasks/PROJ-*/meta.json) ----
export interface TaskMeta {
  id: string;
  title: string;
  type: "task" | "epic" | "story" | "journey";
  task_type?: "impl" | "review" | "spec" | "test";
  parent?: string;
  children: string[];
  status: TaskStatus;
  assignee: string;
  points: number;
  priority: "critical" | "high" | "medium" | "low";
  labels: string[];
  dependencies: {
    blocks: string[];
    blocked_by: string[];
  };
  created: string;
  updated: string;
  sprint: string;
  time_tracking: {
    estimated_hours: number;
    logged_hours: number;
  };
  gate_results: GateResults;
}

export type TaskStatus =
  | "TODO"
  | "IN_PROGRESS"
  | "IN_REVIEW"
  | "QA"
  | "DONE"
  | "BLOCKED";

export interface GateResults {
  gate1_code_review?: "PASS" | "FAIL";
  gate1_date?: string;
  gate2_test?: "PASS" | "FAIL";
  gate2_date?: string;
  gate3_integration?: "PASS" | "FAIL";
  gate3_date?: string;
  gate4_security?: "PASS" | "FAIL";
  gate4_date?: string;
  gate5_acceptance?: "PASS" | "FAIL";
  gate5_date?: string;
}

// ---- Sprint Metrics ----
export interface SprintMetrics {
  sprint: string;
  started: string;
  planned_end: string;
  actual_end: string | null;
  goal: string;
  capacity_pts: number;
  committed_pts: number;
  completed_pts: number;
  daily_burndown: Array<{
    date: string;
    day: number;
    remaining: number;
    completed: number;
  }>;
  velocity_history: Array<{
    sprint: string;
    velocity: number;
  }>;
  tasks: Record<TaskStatus, number>;
  carry_over: {
    count: number;
    points: number;
    task_ids: string[];
  };
}

// ---- Counters ----
export interface Counters {
  project_key: string;
  counters: Record<string, number>;
  last_updated: string;
}

// ---- Activity Log ----
export interface ActivityLogEntry {
  timestamp: string;
  agent_emoji?: string;
  event_type: string;
  message: string;
  raw: string;
}

// ---- Agent State (derived) ----
export interface AgentState {
  name: string;
  emoji: string;
  model: "opus" | "sonnet" | "haiku";
  role: string;
  status: "idle" | "working" | "waiting" | "done" | "blocked";
  active_task?: {
    id: string;
    title: string;
    status: string;
  };
  tasks_completed: number;
  points_completed: number;
  last_action?: string;
}

// ---- Heartbeat ----
export interface HeartbeatStatus {
  alive: boolean;
  last_beat: string | null;
  age_seconds: number;
  health: "healthy" | "working" | "stale" | "dead" | "unknown";
  source?: string;
}

// ---- Kanban ----
export interface KanbanBoard {
  columns: KanbanColumn[];
  sprint: string;
  updated: string;
}

export interface KanbanColumn {
  name: TaskStatus;
  tasks: KanbanTask[];
  task_count: number;
  point_sum: number;
}

export interface KanbanTask {
  id: string;
  title: string;
  points: number;
  assignee: string;
  priority: "critical" | "high" | "medium" | "low";
}

// ---- Gates ----
export interface GateSummary {
  gates: {
    name: string;
    key: string;
    passed: number;
    failed: number;
    pending: number;
    total: number;
  }[];
  tasks: {
    id: string;
    title: string;
    status: TaskStatus;
    gates: GateResults;
  }[];
}

// ---- Sprint List ----
export interface SprintInfo {
  name: string;
  isCurrent: boolean;
}
