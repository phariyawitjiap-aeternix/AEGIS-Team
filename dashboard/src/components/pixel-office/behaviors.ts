// ---- Agent Social Behavior System ----
// Manages idle/social behaviors for pixel office agents.
// Only affects agents that are NOT working/blocked in the live data.

import type { PixelAgent, SpeechBubble } from "./types";
import type { AgentState } from "@/types";

// ---- Key positions in canvas space ----
export const ORB_POS = { x: 640, y: 490 };
export const WATER_COOLER_POS = { x: 113, y: 555 };
export const MEETING_ROOM_POS = { x: 625, y: 520 };

// Desk anchor positions (agent standing position: feet of sprite)
export const DESK_POSITIONS: Record<string, { x: number; y: number }> = {
  Navi:     { x: 120, y: 295 },
  Sage:     { x: 248, y: 295 },
  Bolt:     { x: 376, y: 295 },
  Vigil:    { x: 504, y: 295 },
  Havoc:    { x: 632, y: 295 },
  Forge:    { x: 120, y: 425 },
  Pixel:    { x: 248, y: 425 },
  Muse:     { x: 376, y: 425 },
  Sentinel: { x: 504, y: 425 },
  Probe:    { x: 632, y: 425 },
  Scribe:   { x: 120, y: 555 },
  Ops:      { x: 248, y: 555 },
};

// ---- Speech bubble text pools ----
const CHAT_MESSAGES: Record<string, string[]> = {
  white: ["Hey!", "Sup?", "Lunch?", "Nice!", "LOL", "Brb", "Indeed", "Hmm"],
  green: ["Done!", "PASS", "Shipped!", "LFG!", "Merged!", "Green!"],
  red:   ["Bug!", "FAIL", "Broken!", "Yikes", "Revert?", "Ugh"],
  yellow:["Hmm...", "Thinking", "Maybe?", "IDK", "...", "How?"],
  blue:  ["Coding...", "Reviewing", "Testing", "Building", "Deploying"],
};

const VISIT_MESSAGES = ["Hey!", "Nice work!", "Quick Q?", "Coffee?", "Brb"];
const ORB_MESSAGES   = ["Reporting...", "Status: OK", "Done!", "Syncing"];
const COOLER_MESSAGES = ["Hydrating", "Coffee?", "Water break", "Sip"];
const MEETING_MESSAGES = ["In meeting", "Syncing...", "Align?", "10min?"];

function randomFrom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

// ---- Build initial pixel agent state ----
export function buildInitialPixelAgents(): PixelAgent[] {
  return Object.entries(DESK_POSITIONS).map(([name, pos]) => ({
    name,
    x: pos.x,
    y: pos.y,
    targetX: pos.x,
    targetY: pos.y,
    behavior: "at_desk" as const,
    waitTicks: 0,
    visitTarget: null,
    bubble: null,
    walkFrame: 0,
    walkFrameTick: 0,
    nextBehaviorTick: randomInt(100, 400),
    facing: 1,
  }));
}

// ---- Create a speech bubble ----
function makeBubble(
  text: string,
  color: SpeechBubble["color"],
  tick: number,
  duration = 180
): SpeechBubble {
  return { text, color, createdAt: tick, duration };
}

// ---- Per-frame behavior tick for a single agent ----
export function tickBehavior(
  pa: PixelAgent,
  liveStatus: AgentState | undefined,
  allPixelAgents: PixelAgent[],
  tick: number
): void {
  const status = liveStatus?.status ?? "idle";

  // Clear expired bubbles
  if (pa.bubble && tick - pa.bubble.createdAt >= pa.bubble.duration) {
    pa.bubble = null;
  }

  // Working agents: stay at desk, show blue bubble occasionally
  if (status === "working") {
    returnToDesk(pa);
    pa.behavior = "at_desk";
    if (tick % 200 === 0 && !pa.bubble) {
      pa.bubble = makeBubble(randomFrom(CHAT_MESSAGES.blue), "blue", tick, 160);
    }
    return;
  }

  // Blocked agents: stay at desk, show red "..." bubble
  if (status === "blocked") {
    returnToDesk(pa);
    pa.behavior = "at_desk";
    if (!pa.bubble || tick - pa.bubble.createdAt > 240) {
      pa.bubble = makeBubble("...", "red", tick, 240);
    }
    return;
  }

  // Done agents: celebrate then socialize freely
  if (status === "done" && pa.behavior === "at_desk") {
    if (!pa.bubble) {
      pa.bubble = makeBubble(randomFrom(CHAT_MESSAGES.green), "green", tick, 200);
    }
    // After the celebration bubble starts, they can start socializing
    if (tick - (pa.bubble?.createdAt ?? 0) > 80) {
      triggerRandomBehavior(pa, allPixelAgents, tick);
    }
    return;
  }

  // Handle walking to target
  if (pa.behavior === "walking") {
    const dx = pa.targetX - pa.x;
    const dy = pa.targetY - pa.y;
    if (Math.sqrt(dx * dx + dy * dy) < 5) {
      // Arrived — switch to the destination behavior
      onArrived(pa, tick);
    }
    return;
  }

  // Waiting at a location
  if (pa.waitTicks > 0) {
    pa.waitTicks--;
    if (pa.waitTicks === 0) {
      returnToDesk(pa);
      startWalking(pa, DESK_POSITIONS[pa.name].x, DESK_POSITIONS[pa.name].y);
    }
    return;
  }

  // Idle at desk — check if it's time for a social behavior
  if (pa.behavior === "at_desk" && tick >= pa.nextBehaviorTick) {
    triggerRandomBehavior(pa, allPixelAgents, tick);
  }
}

function returnToDesk(pa: PixelAgent): void {
  const home = DESK_POSITIONS[pa.name];
  if (!home) return;
  pa.targetX = home.x;
  pa.targetY = home.y;
}

function startWalking(pa: PixelAgent, tx: number, ty: number): void {
  pa.targetX = tx;
  pa.targetY = ty;
  pa.behavior = "walking";
}

function onArrived(pa: PixelAgent, tick: number): void {
  switch (pa.behavior) {
    case "walking": {
      // Determine where we arrived based on distance to key spots
      const distToDesk = dist(pa, DESK_POSITIONS[pa.name] ?? { x: -999, y: -999 });
      const distToOrb  = dist(pa, ORB_POS);
      const distToCooler = dist(pa, WATER_COOLER_POS);
      const distToMeeting = dist(pa, MEETING_ROOM_POS);

      if (distToDesk < 20) {
        pa.behavior = "at_desk";
        pa.visitTarget = null;
      } else if (distToOrb < 30) {
        pa.behavior = "at_orb";
        pa.waitTicks = randomInt(90, 180);
        pa.bubble = makeBubble(randomFrom(ORB_MESSAGES), "blue", tick, 150);
      } else if (distToCooler < 30) {
        pa.behavior = "at_cooler";
        pa.waitTicks = randomInt(120, 200);
        pa.bubble = makeBubble(randomFrom(COOLER_MESSAGES), "white", tick, 140);
      } else if (distToMeeting < 40) {
        pa.behavior = "at_meeting";
        pa.waitTicks = randomInt(200, 400);
        pa.bubble = makeBubble(randomFrom(MEETING_MESSAGES), "yellow", tick, 180);
      } else if (pa.visitTarget) {
        pa.behavior = "at_friend";
        pa.waitTicks = randomInt(100, 180);
        pa.bubble = makeBubble(randomFrom(VISIT_MESSAGES), "white", tick, 140);
      } else {
        pa.behavior = "at_desk";
      }
      break;
    }
    default:
      pa.behavior = "at_desk";
  }
}

function dist(pa: { x: number; y: number }, target: { x: number; y: number }): number {
  return Math.sqrt((pa.x - target.x) ** 2 + (pa.y - target.y) ** 2);
}

function triggerRandomBehavior(
  pa: PixelAgent,
  allAgents: PixelAgent[],
  tick: number
): void {
  const roll = Math.random();

  if (roll < 0.30) {
    // Walk to a random friend's desk
    const others = allAgents.filter((a) => a.name !== pa.name);
    if (others.length > 0) {
      const friend = randomFrom(others);
      pa.visitTarget = friend.name;
      // Stand slightly to the right of the friend's desk
      startWalking(pa, friend.x + 18, friend.y);
    }
  } else if (roll < 0.50) {
    // Walk to Mother Brain orb
    startWalking(pa, ORB_POS.x, ORB_POS.y + 10);
  } else if (roll < 0.65) {
    // Coffee / water break
    startWalking(pa, WATER_COOLER_POS.x + 5, WATER_COOLER_POS.y);
  } else if (roll < 0.72) {
    // Meeting room
    const mx = MEETING_ROOM_POS.x + randomInt(-20, 20);
    const my = MEETING_ROOM_POS.y + randomInt(-10, 10);
    startWalking(pa, mx, my);
  } else {
    // Random idle animation (stretch/yawn)
    pa.bubble = makeBubble(
      randomFrom(["...", "Hmm", "Yawn", "Brb"]),
      "white",
      tick,
      100
    );
    pa.nextBehaviorTick = tick + randomInt(200, 500);
  }

  // Schedule the next social behavior check
  pa.nextBehaviorTick = tick + randomInt(300, 700);
}

// ---- Compute bubble alpha (fade out in last 30 ticks) ----
export function bubbleAlpha(bubble: SpeechBubble, tick: number): number {
  const elapsed = tick - bubble.createdAt;
  const remaining = bubble.duration - elapsed;
  if (remaining <= 0) return 0;
  if (remaining < 30) return remaining / 30;
  if (elapsed < 10) return elapsed / 10;
  return 1;
}
