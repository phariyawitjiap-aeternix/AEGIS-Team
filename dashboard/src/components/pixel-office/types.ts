// ---- Pixel Office Internal Types ----

export type AgentBehaviorState =
  | "at_desk"
  | "walking"
  | "at_friend"
  | "at_orb"
  | "at_cooler"
  | "at_meeting"
  | "idle_anim";

export interface SpeechBubble {
  text: string;
  color: "white" | "green" | "red" | "yellow" | "blue";
  /** tick when the bubble was created */
  createdAt: number;
  /** how many ticks it lives */
  duration: number;
}

export interface PixelAgent {
  name: string;
  /** current canvas-space position (feet anchor) */
  x: number;
  y: number;
  /** walk target (canvas-space) */
  targetX: number;
  targetY: number;
  /** behavioral state */
  behavior: AgentBehaviorState;
  /** ticks to stay at a location before returning */
  waitTicks: number;
  /** which agent this agent is visiting (name) */
  visitTarget: string | null;
  bubble: SpeechBubble | null;
  /** walk frame 0-3 */
  walkFrame: number;
  /** tick counter for next walk-frame update */
  walkFrameTick: number;
  /** next tick when a random social behavior may trigger */
  nextBehaviorTick: number;
  /** direction: 1=right, -1=left */
  facing: number;
}

export interface Vec2 {
  x: number;
  y: number;
}
