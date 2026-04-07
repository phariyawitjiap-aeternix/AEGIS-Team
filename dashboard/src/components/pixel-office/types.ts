// ---- Pixel Office Internal Types ----

export type AgentBehaviorState =
  | "at_desk"
  | "walking"
  | "at_friend"
  | "at_orb"
  | "at_cooler"
  | "at_meeting"
  | "idle_anim"
  | "working_at_desk"     // actively working on a task
  | "reporting_to_mb"     // walking to Mother Brain to report
  | "receiving_task"      // at MB orb, getting a new task assignment
  | "collaborating"       // walking to teammate for handoff (Sage→Bolt→Vigil chain)
  | "code_reviewing"      // Vigil reviewing at someone's desk
  | "celebrating"         // task/sprint done celebration
  | "coffee_break"        // relaxing at water cooler
  | "chatting";           // casual chat with friend

export interface SpeechBubble {
  text: string;
  color: "white" | "green" | "red" | "yellow" | "blue" | "purple";
  createdAt: number;
  duration: number;
}

export interface PixelAgent {
  name: string;
  x: number;
  y: number;
  targetX: number;
  targetY: number;
  behavior: AgentBehaviorState;
  waitTicks: number;
  visitTarget: string | null;
  bubble: SpeechBubble | null;
  walkFrame: number;
  walkFrameTick: number;
  nextBehaviorTick: number;
  facing: number;
  /** Track previous live status to detect transitions */
  prevLiveStatus: string;
  /** What task this agent is working on (from API) */
  activeTaskId: string | null;
  /** Chain: who to hand off to next */
  handoffTarget: string | null;
}

export interface Vec2 {
  x: number;
  y: number;
}
