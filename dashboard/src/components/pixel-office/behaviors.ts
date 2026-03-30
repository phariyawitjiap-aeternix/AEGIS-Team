// ---- Agent Behavior System v2 ----
// Data-driven behaviors from real API state + natural social interactions.
//
// WORK behaviors: respond to actual task assignments, pipeline flow, team commands
// SOCIAL behaviors: idle agents chat, get coffee, rest — like a real office

import type { PixelAgent, SpeechBubble } from "./types";
import type { AgentState } from "@/types";

// ---- Key positions ----
export const ORB_POS = { x: 640, y: 490 };
export const WATER_COOLER_POS = { x: 113, y: 555 };
export const COFFEE_MACHINE_POS = { x: 160, y: 555 };
export const MEETING_ROOM_CENTER = { x: 625, y: 520 };
export const MEETING_SEATS = [
  { x: 590, y: 500 }, { x: 660, y: 500 },
  { x: 590, y: 540 }, { x: 660, y: 540 },
];

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

// ---- Pipeline chain: who hands off to whom ----
const PIPELINE_CHAINS: Record<string, string> = {
  Sage: "Bolt",       // Sage specs → Bolt builds
  Bolt: "Vigil",      // Bolt builds → Vigil reviews
  Vigil: "Sentinel",  // Vigil passes → Sentinel QA
  Sentinel: "Probe",  // Sentinel plans → Probe executes
  Probe: "Scribe",    // Probe reports → Scribe docs
};

// ---- Work speech bubbles (role-specific) ----
const WORK_BUBBLES: Record<string, string[]> = {
  Navi:     ["Planning...", "Routing task", "Sprint check", "Deciding..."],
  Sage:     ["Writing spec", "Designing...", "Architecture", "Trade-offs..."],
  Bolt:     ["Coding...", "npm install", "Building...", "git commit"],
  Vigil:    ["Reviewing...", "Security?", "LGTM!", "Needs fix"],
  Havoc:    ["What if...?", "Edge case!", "Challenge!", "Hmm, flaw?"],
  Forge:    ["Scanning...", "Metrics...", "grep -r", "Dependencies"],
  Pixel:    ["UI wireframe", "Colors...", "Responsive?", "Accessible?"],
  Muse:     ["Writing docs", "README...", "Changelog", "API docs"],
  Sentinel: ["Test plan", "Coverage?", "Risk matrix", "P0 tests"],
  Probe:    ["Running...", "PASS ✅", "Testing...", "npm test"],
  Scribe:   ["ISO docs", "SI.03...", "Tracing...", "PM.01 update"],
  Ops:      ["Deploying...", "Health OK", "docker build", "Monitoring"],
};

// ---- Handoff speech bubbles ----
const HANDOFF_BUBBLES: Record<string, string[]> = {
  Sage:     ["Spec ready!", "Here, Bolt", "Design done"],
  Bolt:     ["Code done!", "PR ready", "Build green"],
  Vigil:    ["PASS!", "Approved ✅", "Ship it"],
  Sentinel: ["QA plan done", "Go Probe!", "Tests ready"],
  Probe:    ["All pass!", "Results in", "73/73 ✅"],
};

// ---- Social chat (personality-specific) ----
const SOCIAL_CHAT: Record<string, string[]> = {
  Navi:     ["Team sync?", "Status?", "On track!", "Sprint OK"],
  Sage:     ["Interesting...", "Pattern!", "ADR idea", "Hmm design"],
  Bolt:     ["Shipped!", "LFG!", "Coffee?", "Break time"],
  Vigil:    ["Good code", "Clean PR", "Watch this", "Security?"],
  Havoc:    ["But what if", "Devil's Q", "Challenge!", "Red team"],
  Forge:    ["Data says", "Found it!", "Metrics up", "Stats"],
  Pixel:    ["Nice UI!", "Dark mode?", "Spacing...", "Pixels!"],
  Muse:     ["Good read!", "Docs done", "Typo fix", "Changelog"],
  Sentinel: ["All green", "Coverage!", "Risk low", "QA OK"],
  Probe:    ["Tests pass", "No bugs!", "Fast run", "Clean!"],
  Scribe:   ["ISO ready", "Compliant", "Audit OK", "Traced!"],
  Ops:      ["Healthy!", "Deployed", "No alerts", "Uptime 99%"],
};

// ---- MB report messages ----
const MB_REPORT: Record<string, string[]> = {
  Sage:     ["Spec complete", "Design ready", "ADR filed"],
  Bolt:     ["Build done", "Code merged", "Tests pass"],
  Vigil:    ["Review done", "Gate 1 pass", "Clean code"],
  Sentinel: ["QA complete", "Gate 2 pass", "All tested"],
  Scribe:   ["ISO updated", "Gate 3 pass", "Docs synced"],
  Ops:      ["Deployed OK", "Health green", "Gate 4 pass"],
};

// ---- Leisure / rest (ONLY when idle — no work, just life) ----
const COFFEE_BUBBLES = ["☕", "Ahh...", "*sip*", "Nice coffee", "Refueling", "Mmm", "Hot!"];
const IDLE_DESK = ["*stretch*", "*yawn*", "📱", "*look around*", "*tap tap*", "🎵", "*hum*", "😴"];
const CASUAL_CHAT: Record<string, string[]> = {
  Navi:     ["What a day", "Any plans?", "Lunch?", "Nice weather"],
  Sage:     ["Read this?", "Cool article", "New pattern", "Interesting..."],
  Bolt:     ["Games later?", "LFG!", "Weekend?", "So tired lol"],
  Vigil:    ["Stay sharp", "Good job", "Clean code", "Not bad"],
  Havoc:    ["Haha!", "No way!", "Crazy!", "LOL"],
  Forge:    ["Did you see", "Numbers!", "Cool stats", "Data nerd"],
  Pixel:    ["Love this!", "Colors!", "So pretty", "Nice design"],
  Muse:     ["Great read", "Typo!", "Docs done", "Creative!"],
  Sentinel: ["All quiet", "No bugs", "Peaceful", "Boring day"],
  Probe:    ["Tests pass", "Clean!", "No issues", "Easy day"],
  Scribe:   ["Filed it", "All good", "Organized", "Neat"],
  Ops:      ["Servers up", "All green", "Quiet day", "Smooth"],
};
const WALK_THOUGHTS = ["🎵", "...", "💭", "🚶"];

function randomFrom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}
function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}
function dist(a: { x: number; y: number }, b: { x: number; y: number }): number {
  return Math.sqrt((a.x - b.x) ** 2 + (a.y - b.y) ** 2);
}

// ---- Build initial state ----
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
    prevLiveStatus: "idle",
    activeTaskId: null,
    handoffTarget: null,
  }));
}

function makeBubble(text: string, color: SpeechBubble["color"], tick: number, duration = 180): SpeechBubble {
  return { text, color, createdAt: tick, duration };
}
function startWalking(pa: PixelAgent, tx: number, ty: number): void {
  pa.targetX = tx;
  pa.targetY = ty;
  pa.behavior = "walking";
}
function goHome(pa: PixelAgent): void {
  const home = DESK_POSITIONS[pa.name];
  if (home) startWalking(pa, home.x, home.y);
}

// ========================================================
// MAIN BEHAVIOR TICK — called every frame for each agent
// ========================================================
export function tickBehavior(
  pa: PixelAgent,
  liveStatus: AgentState | undefined,
  allPixelAgents: PixelAgent[],
  tick: number
): void {
  const status = liveStatus?.status ?? "idle";
  const taskId = liveStatus?.active_task?.id ?? null;

  // Clear expired bubbles
  if (pa.bubble && tick - pa.bubble.createdAt >= pa.bubble.duration) {
    pa.bubble = null;
  }

  // ============================================
  // DETECT STATUS TRANSITIONS (state changes)
  // ============================================
  if (status !== pa.prevLiveStatus) {
    onStatusChange(pa, pa.prevLiveStatus, status, taskId, allPixelAgents, tick);
    pa.prevLiveStatus = status;
  }

  // ============================================
  // STATUS-DRIVEN BEHAVIORS (work)
  // ============================================

  // WORKING: stay at desk, type, show work bubbles
  if (status === "working") {
    if (pa.behavior !== "working_at_desk" && pa.behavior !== "walking") {
      pa.behavior = "working_at_desk";
      goHome(pa);
    }
    pa.activeTaskId = taskId;
    // Periodic work bubbles
    if (tick % 300 === 0 && !pa.bubble) {
      const msgs = WORK_BUBBLES[pa.name] || ["Working..."];
      pa.bubble = makeBubble(randomFrom(msgs), "blue", tick, 160);
    }
    return;
  }

  // BLOCKED: at desk with red bubbles
  if (status === "blocked") {
    if (pa.behavior !== "at_desk") {
      pa.behavior = "at_desk";
      goHome(pa);
    }
    if (!pa.bubble || tick - pa.bubble.createdAt > 300) {
      pa.bubble = makeBubble("Blocked...", "red", tick, 300);
    }
    return;
  }

  // WAITING: stand near desk, look around
  if (status === "waiting") {
    if (pa.behavior !== "at_desk") {
      pa.behavior = "at_desk";
      goHome(pa);
    }
    if (tick % 400 === 0 && !pa.bubble) {
      pa.bubble = makeBubble("Waiting...", "yellow", tick, 120);
    }
    return;
  }

  // DONE: celebrate, then report to MB, then socialize
  if (status === "done") {
    if (pa.behavior === "working_at_desk") {
      // Just finished! Celebrate first
      pa.behavior = "celebrating";
      pa.bubble = makeBubble("Done! 🎉", "green", tick, 200);
      pa.waitTicks = 120;
      return;
    }
    if (pa.behavior === "celebrating") {
      pa.waitTicks--;
      if (pa.waitTicks <= 0) {
        // Go report to Mother Brain
        pa.behavior = "reporting_to_mb";
        startWalking(pa, ORB_POS.x, ORB_POS.y + 10);
        const msgs = MB_REPORT[pa.name] || ["Done!"];
        pa.bubble = makeBubble(randomFrom(msgs), "green", tick, 180);
      }
      return;
    }
    // After reporting, fall through to idle behaviors
  }

  // ============================================
  // WALKING — in transit
  // ============================================
  if (pa.behavior === "walking" || pa.behavior === "reporting_to_mb" || pa.behavior === "collaborating") {
    if (dist(pa, { x: pa.targetX, y: pa.targetY }) < 5) {
      onArrived(pa, allPixelAgents, tick);
    }
    return;
  }

  // ============================================
  // WAITING AT A LOCATION (timed)
  // ============================================
  if (pa.waitTicks > 0) {
    pa.waitTicks--;
    if (pa.waitTicks === 0) {
      // Return home
      goHome(pa);
    }
    return;
  }

  // ============================================
  // IDLE — SOCIAL BEHAVIORS (the fun part)
  // ============================================
  if ((pa.behavior === "at_desk" || pa.behavior === "idle_anim") && tick >= pa.nextBehaviorTick) {
    triggerIdleBehavior(pa, allPixelAgents, tick);
  }
}

// ============================================
// STATUS CHANGE HANDLER
// ============================================
function onStatusChange(
  pa: PixelAgent,
  from: string,
  to: string,
  taskId: string | null,
  allAgents: PixelAgent[],
  tick: number
): void {
  // idle → working: receive task, walk to desk
  if (to === "working") {
    pa.bubble = makeBubble("On it!", "blue", tick, 120);
    pa.behavior = "working_at_desk";
    goHome(pa);
    pa.activeTaskId = taskId;
    // Set up handoff chain
    pa.handoffTarget = PIPELINE_CHAINS[pa.name] || null;
  }

  // working → done: celebrate + handoff to next in chain
  if (from === "working" && to === "done") {
    pa.bubble = makeBubble("Done! 🎉", "green", tick, 200);
    pa.behavior = "celebrating";
    pa.waitTicks = 100;

    // Trigger handoff: walk to next agent in pipeline
    if (pa.handoffTarget) {
      const target = allAgents.find(a => a.name === pa.handoffTarget);
      if (target) {
        // After celebrating, will walk to handoff target
        setTimeout(() => {
          // This won't work in canvas tick, so we use waitTicks approach
        }, 0);
      }
    }
  }

  // idle → done: just mark celebrating
  if (from === "idle" && to === "done") {
    pa.behavior = "celebrating";
    pa.bubble = makeBubble("Complete! ✅", "green", tick, 200);
    pa.waitTicks = 80;
  }

  // anything → blocked
  if (to === "blocked") {
    pa.bubble = makeBubble("Blocked! 🚫", "red", tick, 300);
    goHome(pa);
  }
}

// ============================================
// ARRIVAL HANDLER
// ============================================
function onArrived(pa: PixelAgent, allAgents: PixelAgent[], tick: number): void {
  const distToDesk = dist(pa, DESK_POSITIONS[pa.name] ?? { x: -999, y: -999 });
  const distToOrb = dist(pa, ORB_POS);
  const distToCooler = dist(pa, WATER_COOLER_POS);
  const distToCoffee = dist(pa, COFFEE_MACHINE_POS);
  const distToMeeting = dist(pa, MEETING_ROOM_CENTER);

  // Arrived at home desk
  if (distToDesk < 25) {
    pa.behavior = "at_desk";
    pa.visitTarget = null;
    pa.nextBehaviorTick = tick + randomInt(200, 500);
    return;
  }

  // Arrived at Mother Brain — ONLY for real work reporting
  if (distToOrb < 40) {
    if (pa.behavior === "reporting_to_mb") {
      // Real report: agent just finished a task
      const msgs = MB_REPORT[pa.name] || ["Done!"];
      pa.bubble = makeBubble(randomFrom(msgs), "purple", tick, 200);
      pa.waitTicks = randomInt(120, 200);
      pa.behavior = "at_orb";
    } else {
      // Just wandered near the orb — look at it briefly, then leave
      pa.bubble = makeBubble("🧬", "white", tick, 60);
      pa.waitTicks = randomInt(30, 60);
      pa.behavior = "at_orb";
    }
    return;
  }

  // Arrived at water cooler / coffee
  if (distToCooler < 35 || distToCoffee < 35) {
    pa.behavior = "coffee_break";
    pa.bubble = makeBubble(randomFrom(COFFEE_BUBBLES), "white", tick, 160);
    pa.waitTicks = randomInt(150, 300);
    return;
  }

  // Arrived at meeting room — only real meetings when work status demands it
  // Otherwise just passing through or hanging out
  if (distToMeeting < 50) {
    pa.behavior = "at_meeting";
    pa.waitTicks = randomInt(100, 200);
    pa.bubble = makeBubble("Just passing by", "white", tick, 100);
    return;
  }

  // Arrived at friend's desk (collaborating or chatting)
  if (pa.visitTarget) {
    const friend = allAgents.find(a => a.name === pa.visitTarget);
    if (pa.behavior === "collaborating" && friend) {
      // Work handoff
      const msgs = HANDOFF_BUBBLES[pa.name] || ["Here you go!"];
      pa.bubble = makeBubble(randomFrom(msgs), "green", tick, 180);
      // Friend responds
      if (!friend.bubble) {
        const responses = ["Got it!", "Thanks!", "On it!", "Roger!"];
        friend.bubble = makeBubble(randomFrom(responses), "blue", tick + 30, 150);
      }
      pa.waitTicks = randomInt(80, 140);
      pa.behavior = "at_friend";
    } else {
      // Casual chat — NOT work, just friends hanging out
      pa.behavior = "chatting";
      const msgs = CASUAL_CHAT[pa.name] || ["Hey!"];
      pa.bubble = makeBubble(randomFrom(msgs), "white", tick, 150);
      // Friend responds with their own casual personality
      if (friend && !friend.bubble) {
        const friendMsgs = CASUAL_CHAT[friend.name] || ["Hey!"];
        friend.bubble = makeBubble(randomFrom(friendMsgs), "white", tick + 40, 140);
      }
      pa.waitTicks = randomInt(120, 250);
    }
    return;
  }

  // Default: go home
  pa.behavior = "at_desk";
  pa.nextBehaviorTick = tick + randomInt(200, 400);
}

// ============================================
// IDLE BEHAVIORS — pure leisure, NO fake work
// Only triggers when API status is "idle" (no task assigned)
// ============================================
function triggerIdleBehavior(
  pa: PixelAgent,
  allAgents: PixelAgent[],
  tick: number
): void {
  // Only chat with friends who are ALSO idle (don't bother workers)
  const idleFriends = allAgents.filter(a =>
    a.name !== pa.name &&
    (a.behavior === "at_desk" || a.behavior === "idle_anim" ||
     a.behavior === "coffee_break" || a.behavior === "chatting")
  );

  const roll = Math.random();

  if (roll < 0.28 && idleFriends.length > 0) {
    // CHAT WITH A FRIEND — casual conversation, not work
    const friend = randomFrom(idleFriends);
    pa.visitTarget = friend.name;
    const friendPos = DESK_POSITIONS[friend.name];
    if (friendPos) {
      startWalking(pa, friendPos.x + 20, friendPos.y);
    }
  } else if (roll < 0.45) {
    // COFFEE / WATER BREAK — take a breather
    const target = Math.random() < 0.5 ? COFFEE_MACHINE_POS : WATER_COOLER_POS;
    startWalking(pa, target.x + randomInt(-5, 10), target.y);
  } else if (roll < 0.58) {
    // WALK AROUND — just stretching legs, no destination
    const wanderX = pa.x + randomInt(-100, 100);
    const wanderY = pa.y + randomInt(-60, 60);
    // Clamp to office bounds
    const clampedX = Math.max(80, Math.min(750, wanderX));
    const clampedY = Math.max(200, Math.min(580, wanderY));
    startWalking(pa, clampedX, clampedY);
    if (Math.random() < 0.3) {
      pa.bubble = makeBubble(randomFrom(WALK_THOUGHTS), "white", tick, 80);
    }
  } else if (roll < 0.70 && idleFriends.length >= 2) {
    // HANG OUT NEAR FRIENDS — go sit near someone, maybe they'll chat
    const friend = randomFrom(idleFriends);
    const friendPos = DESK_POSITIONS[friend.name];
    if (friendPos) {
      startWalking(pa, friendPos.x + randomInt(-25, 25), friendPos.y + randomInt(-15, 15));
    }
  } else {
    // STAY AT DESK — idle animations (stretch, yawn, phone, hum)
    pa.behavior = "idle_anim";
    pa.bubble = makeBubble(randomFrom(IDLE_DESK), "white", tick, 100);
    pa.nextBehaviorTick = tick + randomInt(400, 800);
    return;
  }

  pa.nextBehaviorTick = tick + randomInt(500, 1000);
}

// ---- Bubble alpha fade ----
export function bubbleAlpha(bubble: SpeechBubble, tick: number): number {
  const elapsed = tick - bubble.createdAt;
  const remaining = bubble.duration - elapsed;
  if (remaining <= 0) return 0;
  if (remaining < 30) return remaining / 30;
  if (elapsed < 10) return elapsed / 10;
  return 1;
}
