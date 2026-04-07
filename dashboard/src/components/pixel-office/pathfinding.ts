// ---- Pathfinding / Movement helpers ----
// Simple straight-line movement with soft collision avoidance.
// Speed varies by work state: working = brisk, idle = leisurely stroll.

import type { PixelAgent } from "./types";

const SPEED_WORKING = 2.5;  // brisk walk — got stuff to do
const SPEED_IDLE = 0.8;     // leisurely stroll — no rush
const SPEED_DONE = 2.0;     // heading to report — satisfied pace

const WALK_FRAME_INTERVAL_WORKING = 6;  // faster leg cycle
const WALK_FRAME_INTERVAL_IDLE = 14;    // slow lazy steps

const AGENT_RADIUS = 12;

/**
 * Get walk speed based on behavior.
 * Work-related movement = fast. Leisure = slow and chill.
 */
function getSpeed(agent: PixelAgent): number {
  switch (agent.behavior) {
    case "working_at_desk":
    case "collaborating":
    case "reporting_to_mb":
    case "receiving_task":
      return SPEED_WORKING;
    case "celebrating":
      return SPEED_DONE;
    case "coffee_break":
    case "chatting":
    case "idle_anim":
    case "at_desk":
    default:
      return SPEED_IDLE;
  }
}

/**
 * Get walk animation speed — idle agents move legs slower.
 */
function getWalkFrameInterval(agent: PixelAgent): number {
  switch (agent.behavior) {
    case "working_at_desk":
    case "collaborating":
    case "reporting_to_mb":
    case "celebrating":
      return WALK_FRAME_INTERVAL_WORKING;
    default:
      return WALK_FRAME_INTERVAL_IDLE;
  }
}

/**
 * Move a walking agent one step toward its target.
 * Returns true if the agent reached its target this frame.
 */
export function stepAgent(agent: PixelAgent): boolean {
  const dx = agent.targetX - agent.x;
  const dy = agent.targetY - agent.y;
  const dist = Math.sqrt(dx * dx + dy * dy);
  const speed = getSpeed(agent);

  if (dist <= speed) {
    agent.x = agent.targetX;
    agent.y = agent.targetY;
    return true; // arrived
  }

  agent.x += (dx / dist) * speed;
  agent.y += (dy / dist) * speed;

  // Update facing direction based on horizontal movement
  if (Math.abs(dx) > 1) {
    agent.facing = dx > 0 ? 1 : -1;
  }

  return false;
}

/**
 * Advance walk animation frame.
 * Frame cycle: 0 (left foot) → 1 (stand) → 2 (right foot) → 3 (stand)
 * Speed varies: working agents step faster, idle agents amble.
 */
export function advanceWalkFrame(agent: PixelAgent, tick: number): void {
  const interval = getWalkFrameInterval(agent);
  if (tick - agent.walkFrameTick >= interval) {
    agent.walkFrame = (agent.walkFrame + 1) % 4;
    agent.walkFrameTick = tick;
  }
}

/**
 * Soft collision avoidance: push overlapping agents apart.
 * Call once per frame after all agents have stepped.
 */
export function resolveCollisions(agents: PixelAgent[]): void {
  for (let i = 0; i < agents.length; i++) {
    for (let j = i + 1; j < agents.length; j++) {
      const a = agents[i];
      const b = agents[j];
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < AGENT_RADIUS * 2 && dist > 0) {
        const overlap = AGENT_RADIUS * 2 - dist;
        const nx = dx / dist;
        const ny = dy / dist;
        a.x -= nx * overlap * 0.5;
        a.y -= ny * overlap * 0.5;
        b.x += nx * overlap * 0.5;
        b.y += ny * overlap * 0.5;
      }
    }
  }
}
