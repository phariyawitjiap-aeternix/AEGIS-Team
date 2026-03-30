// ---- Pathfinding / Movement helpers ----
// Simple straight-line movement with soft collision avoidance.
// No grid A* — the office is open-plan enough that direct paths work fine.
// Avoidance is handled by nudging overlapping agents apart.

import type { PixelAgent } from "./types";

const SPEED = 2; // pixels per frame
const AGENT_RADIUS = 12; // collision radius

/**
 * Move all walking agents one step toward their target.
 * Returns true if the agent reached its target this frame.
 */
export function stepAgent(agent: PixelAgent): boolean {
  const dx = agent.targetX - agent.x;
  const dy = agent.targetY - agent.y;
  const dist = Math.sqrt(dx * dx + dy * dy);

  if (dist <= SPEED) {
    agent.x = agent.targetX;
    agent.y = agent.targetY;
    return true; // arrived
  }

  agent.x += (dx / dist) * SPEED;
  agent.y += (dy / dist) * SPEED;

  // Update facing direction based on horizontal movement
  if (Math.abs(dx) > 1) {
    agent.facing = dx > 0 ? 1 : -1;
  }

  return false;
}

/**
 * Advance walk animation frame.
 * Frame cycle: 0 (left foot) → 1 (stand) → 2 (right foot) → 3 (stand)
 * Advances every 8 game ticks.
 */
export function advanceWalkFrame(agent: PixelAgent, tick: number): void {
  if (tick - agent.walkFrameTick >= 8) {
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
        // Push both agents apart by half the overlap
        a.x -= nx * overlap * 0.5;
        a.y -= ny * overlap * 0.5;
        b.x += nx * overlap * 0.5;
        b.y += ny * overlap * 0.5;
      }
    }
  }
}
