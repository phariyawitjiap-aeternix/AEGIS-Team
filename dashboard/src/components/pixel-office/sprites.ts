// ---- Programmatic sprite drawing (32x32 characters, drawn via Canvas API) ----
// All coordinates are in canvas pixels (no external scale multiplier).
// Sprites are drawn at (x, y) where (x, y) is the TOP-LEFT of the 32x32 bounding box.

import type { HeartbeatStatus } from "@/types";

// ---- Pixel helpers ----

/** Fill a rectangle of pixels relative to the sprite origin. */
function px(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  col: string,
  x: number,
  y: number,
  w: number,
  h: number
): void {
  ctx.fillStyle = col;
  ctx.fillRect(ox + x, oy + y, w, h);
}

// ---- Shared palette ----
const SKIN = "#FFCC99";
const SKIN_SHADOW = "#E8A87C";
const EYE = "#2A2A2A";
const WHITE = "#FFFFFF";

// ---- Base 32x32 humanoid ----
// Layout (y offsets):
//   0–7   : head
//   8–15  : torso / arms
//   16–23 : hips / legs upper
//   24–31 : legs lower / feet

/**
 * Draw a generic humanoid at (ox, oy).
 * hairColor: top of head / body color
 * bodyColor: shirt / outfit
 * walkFrame: 0-3 (0=left foot, 1=stand, 2=right foot, 3=stand)
 * status: used for arm pose
 */
function drawBase(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  hairColor: string,
  bodyColor: string,
  pantsColor: string,
  shoeColor: string,
  walkFrame: number,
  status: string,
  tick: number
): void {
  // ---- Head ----
  px(ctx, ox, oy, SKIN, 10, 0, 12, 10);
  px(ctx, ox, oy, SKIN_SHADOW, 10, 8, 12, 2);

  // Hair (top 3 rows)
  px(ctx, ox, oy, hairColor, 10, 0, 12, 4);

  // Eyes (row 5)
  px(ctx, ox, oy, EYE, 13, 5, 2, 2);
  px(ctx, ox, oy, EYE, 17, 5, 2, 2);

  // Blink every ~120 ticks for 4 ticks
  if (tick % 120 > 116) {
    px(ctx, ox, oy, SKIN, 13, 5, 2, 1);
    px(ctx, ox, oy, SKIN, 17, 5, 2, 1);
  }

  // Mouth (row 8)
  if (status === "done") {
    // Big smile
    px(ctx, ox, oy, "#CC4444", 13, 8, 6, 1);
    px(ctx, ox, oy, EYE, 12, 7, 1, 1);
    px(ctx, ox, oy, EYE, 19, 7, 1, 1);
  } else if (status === "blocked") {
    // Flat mouth
    px(ctx, ox, oy, "#884444", 13, 8, 6, 1);
  } else {
    // Neutral
    px(ctx, ox, oy, "#CC8866", 14, 8, 4, 1);
  }

  // ---- Torso ----
  px(ctx, ox, oy, bodyColor, 9, 10, 14, 10);

  // ---- Arms ----
  if (status === "working") {
    // Arms forward / typing — alternate frames
    const armY = tick % 20 < 10 ? 12 : 13;
    px(ctx, ox, oy, bodyColor, 5, armY, 4, 7);
    px(ctx, ox, oy, bodyColor, 23, armY, 4, 7);
    // Hands
    px(ctx, ox, oy, SKIN, 5, armY + 7, 4, 3);
    px(ctx, ox, oy, SKIN, 23, armY + 7, 4, 3);
  } else if (status === "done") {
    // Arms raised
    px(ctx, ox, oy, bodyColor, 3, 6, 4, 8);
    px(ctx, ox, oy, bodyColor, 25, 6, 4, 8);
    px(ctx, ox, oy, SKIN, 3, 5, 4, 3);
    px(ctx, ox, oy, SKIN, 25, 5, 4, 3);
  } else if (walkFrame === 0) {
    // Left arm forward
    px(ctx, ox, oy, bodyColor, 5, 11, 4, 8);
    px(ctx, ox, oy, bodyColor, 23, 13, 4, 7);
    px(ctx, ox, oy, SKIN, 5, 19, 4, 3);
    px(ctx, ox, oy, SKIN, 23, 20, 4, 3);
  } else if (walkFrame === 2) {
    // Right arm forward
    px(ctx, ox, oy, bodyColor, 5, 13, 4, 7);
    px(ctx, ox, oy, bodyColor, 23, 11, 4, 8);
    px(ctx, ox, oy, SKIN, 5, 20, 4, 3);
    px(ctx, ox, oy, SKIN, 23, 19, 4, 3);
  } else {
    // Arms at sides
    px(ctx, ox, oy, bodyColor, 5, 12, 4, 8);
    px(ctx, ox, oy, bodyColor, 23, 12, 4, 8);
    px(ctx, ox, oy, SKIN, 5, 20, 4, 3);
    px(ctx, ox, oy, SKIN, 23, 20, 4, 3);
  }

  // ---- Hips ----
  px(ctx, ox, oy, pantsColor, 9, 20, 14, 4);

  // ---- Legs ----
  if (walkFrame === 0) {
    // Left leg forward
    px(ctx, ox, oy, pantsColor, 9, 24, 5, 6);
    px(ctx, ox, oy, pantsColor, 15, 22, 5, 8);
  } else if (walkFrame === 2) {
    // Right leg forward
    px(ctx, ox, oy, pantsColor, 9, 22, 5, 8);
    px(ctx, ox, oy, pantsColor, 15, 24, 5, 6);
  } else {
    // Standing
    px(ctx, ox, oy, pantsColor, 9, 24, 5, 6);
    px(ctx, ox, oy, pantsColor, 15, 24, 5, 6);
  }

  // ---- Shoes ----
  px(ctx, ox, oy, shoeColor, 8, 30, 7, 2);
  px(ctx, ox, oy, shoeColor, 15, 30, 7, 2);
}

// ============================================================
// Per-agent sprite functions
// ============================================================

export function drawNavi(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  walkFrame: number,
  status: string,
  tick: number
): void {
  drawBase(ctx, ox, oy, "#00CED1", "#00A8AD", "#1A5A6B", "#0D3B4A", walkFrame, status, tick);
  // Navigator hat (turquoise brim)
  px(ctx, ox, oy, "#007A80", 8, 0, 16, 3);
  px(ctx, ox, oy, "#00CED1", 10, -3, 12, 4);
  // Compass pendant
  px(ctx, ox, oy, "#FFD700", 14, 14, 4, 4);
  px(ctx, ox, oy, "#FFA500", 15, 15, 2, 2);
}

export function drawSage(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  walkFrame: number,
  status: string,
  tick: number
): void {
  drawBase(ctx, ox, oy, "#6A0DAD", "#4B0082", "#2D0060", "#1A003A", walkFrame, status, tick);
  // Hood / wide robe shoulders
  px(ctx, ox, oy, "#4B0082", 6, 10, 20, 2);
  // Triangle ruler accessory on chest
  px(ctx, ox, oy, "#C0A0FF", 12, 14, 1, 5);
  px(ctx, ox, oy, "#C0A0FF", 12, 18, 5, 1);
  px(ctx, ox, oy, "#C0A0FF", 12, 14, 5, 1);
  // Stars on robe (sparkle)
  if (tick % 60 < 30) {
    px(ctx, ox, oy, "#DDD0FF", 10, 16, 2, 2);
    px(ctx, ox, oy, "#DDD0FF", 19, 13, 2, 2);
  }
}

export function drawBolt(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  walkFrame: number,
  status: string,
  tick: number
): void {
  drawBase(ctx, ox, oy, "#FFD700", "#FF8C00", "#444444", "#222222", walkFrame, status, tick);
  // Spiky lightning hair (energetic)
  px(ctx, ox, oy, "#FFD700", 10, -4, 3, 5);
  px(ctx, ox, oy, "#FFD700", 14, -5, 4, 6);
  px(ctx, ox, oy, "#FFD700", 19, -3, 3, 4);
  // Lightning bolt on chest
  px(ctx, ox, oy, "#FFD700", 14, 11, 2, 3);
  px(ctx, ox, oy, "#FFD700", 12, 14, 2, 3);
  px(ctx, ox, oy, "#FFD700", 14, 15, 3, 2);
  // Energy glow
  if (tick % 20 < 10) {
    px(ctx, ox, oy, "#FFEE44", 7, 13, 2, 2);
    px(ctx, ox, oy, "#FFEE44", 22, 13, 2, 2);
  }
}

export function drawVigil(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  walkFrame: number,
  status: string,
  tick: number
): void {
  drawBase(ctx, ox, oy, "#4682B4", "#2860A0", "#1A3A6A", "#0A1E44", walkFrame, status, tick);
  // Blue armor plate on chest
  px(ctx, ox, oy, "#4682B4", 9, 10, 14, 10);
  px(ctx, ox, oy, "#5A9FCC", 11, 11, 10, 4);
  // Shield on left arm
  px(ctx, ox, oy, "#4682B4", 4, 11, 5, 8);
  px(ctx, ox, oy, "#5A9FCC", 5, 12, 3, 5);
  // Stern eyebrows
  px(ctx, ox, oy, "#3A3A3A", 13, 4, 3, 1);
  px(ctx, ox, oy, "#3A3A3A", 17, 4, 3, 1);
}

export function drawHavoc(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  walkFrame: number,
  status: string,
  tick: number
): void {
  drawBase(ctx, ox, oy, "#8B0000", "#DC143C", "#660000", "#330000", walkFrame, status, tick);
  // Horns
  px(ctx, ox, oy, "#DC143C", 9, -6, 3, 7);
  px(ctx, ox, oy, "#CC1030", 10, -8, 2, 3);
  px(ctx, ox, oy, "#DC143C", 20, -6, 3, 7);
  px(ctx, ox, oy, "#CC1030", 20, -8, 2, 3);
  // Mischievous grin (wide)
  px(ctx, ox, oy, "#CC4444", 12, 8, 8, 1);
  px(ctx, ox, oy, EYE, 11, 7, 1, 1);
  px(ctx, ox, oy, EYE, 20, 7, 1, 1);
  // Gleaming eyes
  px(ctx, ox, oy, "#FF4444", 13, 5, 2, 2);
  px(ctx, ox, oy, "#FF4444", 17, 5, 2, 2);
}

export function drawForge(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  walkFrame: number,
  status: string,
  tick: number
): void {
  drawBase(ctx, ox, oy, "#6B3A1F", "#8B6914", "#4A2000", "#2A1000", walkFrame, status, tick);
  // Brown leather apron
  px(ctx, ox, oy, "#8B4513", 9, 12, 14, 12);
  px(ctx, ox, oy, "#A0522D", 10, 13, 12, 3);
  // Goggles on head
  px(ctx, ox, oy, "#333", 9, 2, 4, 3);
  px(ctx, ox, oy, "#333", 19, 2, 4, 3);
  px(ctx, ox, oy, "#88AACC", 10, 3, 2, 2);
  px(ctx, ox, oy, "#88AACC", 20, 3, 2, 2);
  px(ctx, ox, oy, "#555", 13, 3, 6, 2);
  // Wrench in right hand
  px(ctx, ox, oy, "#888888", 23, 14, 4, 2);
  px(ctx, ox, oy, "#888888", 25, 12, 2, 6);
  px(ctx, ox, oy, "#AAAAAA", 24, 11, 3, 2);
}

export function drawPixel(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  walkFrame: number,
  status: string,
  tick: number
): void {
  drawBase(ctx, ox, oy, "#E6E6FA", "#DA70D6", "#8A4090", "#4A1060", walkFrame, status, tick);
  // Pink beret
  px(ctx, ox, oy, "#FF69B4", 8, -1, 16, 3);
  px(ctx, ox, oy, "#FF1493", 9, -4, 14, 4);
  px(ctx, ox, oy, "#FF69B4", 20, -2, 3, 3);
  // Paintbrush in right hand
  px(ctx, ox, oy, "#8B4513", 24, 10, 2, 12);
  px(ctx, ox, oy, "#FF4444", 24, 9, 2, 3);
  // Colorful paint splatters on apron
  px(ctx, ox, oy, "#FF4444", 11, 15, 2, 2);
  px(ctx, ox, oy, "#44FF44", 14, 17, 2, 2);
  px(ctx, ox, oy, "#4444FF", 17, 14, 2, 2);
  px(ctx, ox, oy, "#FFFF44", 13, 13, 2, 2);
}

export function drawMuse(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  walkFrame: number,
  status: string,
  tick: number
): void {
  drawBase(ctx, ox, oy, "#B76E79", "#CC8899", "#7A3044", "#3A1020", walkFrame, status, tick);
  // Rose-colored beret
  px(ctx, ox, oy, "#B76E79", 7, -1, 18, 3);
  px(ctx, ox, oy, "#CC7788", 9, -4, 14, 5);
  px(ctx, ox, oy, "#EE99AA", 19, -3, 3, 2);
  // Feather quill in right hand
  px(ctx, ox, oy, "#F5DEB3", 24, 9, 2, 14);
  px(ctx, ox, oy, "#FFFFF0", 23, 8, 4, 3);
  px(ctx, ox, oy, "#EEE8AA", 25, 11, 2, 8);
  // Ink bottle accent
  px(ctx, ox, oy, "#222244", 5, 18, 4, 5);
  px(ctx, ox, oy, "#4444AA", 6, 17, 2, 2);
}

export function drawSentinel(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  walkFrame: number,
  status: string,
  tick: number
): void {
  drawBase(ctx, ox, oy, "#2C5438", "#355E3B", "#1A3A1F", "#0A1E0F", walkFrame, status, tick);
  // Military cap
  px(ctx, ox, oy, "#2C5438", 7, -2, 18, 4);
  px(ctx, ox, oy, "#1A3A1F", 8, -5, 16, 4);
  px(ctx, ox, oy, "#FFD700", 14, -4, 4, 2);
  // Monocle (right eye)
  ctx.strokeStyle = "#FFD700";
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.arc(ox + 19, oy + 6, 3, 0, Math.PI * 2);
  ctx.stroke();
  // Target crosshair accent on chest
  px(ctx, ox, oy, "#AAFFAA", 15, 14, 2, 1);
  px(ctx, ox, oy, "#AAFFAA", 15, 14, 1, 2);
  px(ctx, ox, oy, "#AAFFAA", 15, 17, 1, 2);
  px(ctx, ox, oy, "#AAFFAA", 17, 15, 2, 1);
}

export function drawProbe(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  walkFrame: number,
  status: string,
  tick: number
): void {
  drawBase(ctx, ox, oy, "#A0840A", "#FFBF00", "#7A6000", "#3A2C00", walkFrame, status, tick);
  // Yellow lab coat (wider shoulders / chest)
  px(ctx, ox, oy, "#FFBF00", 7, 10, 18, 12);
  px(ctx, ox, oy, "#FFD740", 8, 11, 16, 4);
  // Lab coat lapels
  px(ctx, ox, oy, WHITE, 9, 12, 4, 8);
  px(ctx, ox, oy, WHITE, 19, 12, 4, 8);
  // Magnifying glass in right hand
  ctx.strokeStyle = "#FFBF00";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.arc(ox + 26, oy + 14, 4, 0, Math.PI * 2);
  ctx.stroke();
  px(ctx, ox, oy, "#CCAAFF", 24, 13, 4, 2);
  px(ctx, ox, oy, "#888", 28, 17, 2, 5);
}

export function drawScribe(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  walkFrame: number,
  status: string,
  tick: number
): void {
  drawBase(ctx, ox, oy, "#8B7355", "#C8A46E", "#7A5838", "#3A2810", walkFrame, status, tick);
  // Scroll headband / wheat decoration
  px(ctx, ox, oy, "#F5DEB3", 9, 0, 14, 2);
  px(ctx, ox, oy, "#DAA520", 10, -1, 12, 2);
  // Wheat scroll rolled on left arm
  px(ctx, ox, oy, "#F5DEB3", 4, 13, 6, 8);
  px(ctx, ox, oy, "#DEB887", 4, 13, 6, 2);
  px(ctx, ox, oy, "#DEB887", 4, 19, 6, 2);
  // Quill pen in right hand
  px(ctx, ox, oy, "#F5DEB3", 23, 10, 2, 13);
  px(ctx, ox, oy, "#FFF8DC", 22, 9, 4, 3);
  // Ink bottle on belt
  px(ctx, ox, oy, "#1A1A3A", 14, 20, 3, 4);
  px(ctx, ox, oy, "#2A2A5A", 14, 19, 3, 2);
}

export function drawOps(
  ctx: CanvasRenderingContext2D,
  ox: number,
  oy: number,
  walkFrame: number,
  status: string,
  tick: number
): void {
  drawBase(ctx, ox, oy, "#1A1A2A", "#2C3539", "#111520", "#050810", walkFrame, status, tick);
  // Dark jumpsuit (solid override)
  px(ctx, ox, oy, "#2C3539", 5, 10, 22, 20);
  px(ctx, ox, oy, "#1E2830", 6, 11, 20, 4);
  // Headset
  px(ctx, ox, oy, "#444", 9, 0, 14, 2);
  px(ctx, ox, oy, "#333", 9, 2, 2, 4);
  px(ctx, ox, oy, "#333", 21, 2, 2, 4);
  px(ctx, ox, oy, "#555", 7, 5, 4, 3);
  // Rocket pin on chest
  px(ctx, ox, oy, "#CCCCCC", 14, 12, 4, 6);
  px(ctx, ox, oy, "#FF4444", 15, 10, 2, 4);
  px(ctx, ox, oy, "#FF8844", 14, 17, 4, 2);
  // Status light (green if working)
  const lightColor = status === "working" ? "#00FF44" : status === "idle" ? "#FFFF00" : "#FF4444";
  px(ctx, ox, oy, lightColor, 20, 12, 3, 3);
}

// ============================================================
// Nick Fury Command Orb (larger, 80x80 bounding box)
// ============================================================

export function drawMotherBrainOrb(
  ctx: CanvasRenderingContext2D,
  cx: number,
  cy: number,
  hb: HeartbeatStatus | null,
  tick: number,
  hasWork: boolean = false // true if any agent is working/blocked/done
): void {
  const health = hb?.health || "unknown";

  // If no work happening, MB is SLEEPING regardless of heartbeat
  const sleeping = !hasWork && health !== "healthy" && health !== "working";

  const colorMap: Record<string, string[]> = {
    healthy: ["#FF00FF", "#FF66FF", "#CC00CC", "#FF88FF"],
    working: ["#FF44CC", "#FF88EE", "#BB0099", "#FFAAE8"],
    stale: ["#AAAA00", "#DDDD44", "#888800", "#EEFF22"],
    dead: ["#880000", "#AA2222", "#660000", "#FF2222"],
    unknown: ["#666666", "#888888", "#444444", "#AAAAAA"],
    sleeping: ["#332244", "#443355", "#221133", "#554466"],
  };
  const colors = sleeping
    ? colorMap.sleeping
    : (colorMap[health] || colorMap.unknown);

  const pulseScale = sleeping
    ? 1 + Math.sin(tick * 0.015) * 0.02 // very slow gentle breathing
    : health === "healthy" || health === "working"
      ? 1 + Math.sin(tick * 0.1) * 0.07
      : health === "stale"
        ? 1 + Math.sin(tick * 0.03) * 0.03
        : 1;

  const r = 38 * pulseScale;

  // Outer glow rings
  for (let ring = 3; ring >= 1; ring--) {
    const alpha = 0.06 * ring;
    const grad = ctx.createRadialGradient(cx, cy, r, cx, cy, r * (1 + ring * 0.6));
    grad.addColorStop(0, colors[0] + Math.round(alpha * 255).toString(16).padStart(2, "0"));
    grad.addColorStop(1, "transparent");
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.arc(cx, cy, r * (1 + ring * 0.6), 0, Math.PI * 2);
    ctx.fill();
  }

  // Orb body
  const orbGrad = ctx.createRadialGradient(
    cx - r * 0.25,
    cy - r * 0.25,
    r * 0.05,
    cx,
    cy,
    r
  );
  orbGrad.addColorStop(0, colors[3]);
  orbGrad.addColorStop(0.45, colors[1]);
  orbGrad.addColorStop(0.8, colors[0]);
  orbGrad.addColorStop(1, colors[2]);
  ctx.fillStyle = orbGrad;
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.fill();

  // Inner core highlight
  const coreGrad = ctx.createRadialGradient(cx - r * 0.2, cy - r * 0.2, 0, cx, cy, r * 0.5);
  coreGrad.addColorStop(0, "rgba(255,255,255,0.6)");
  coreGrad.addColorStop(1, "transparent");
  ctx.fillStyle = coreGrad;
  ctx.beginPath();
  ctx.arc(cx, cy, r * 0.5, 0, Math.PI * 2);
  ctx.fill();

  // Particle ring (orbit) — sleeping = no particles
  const particleCount = sleeping ? 0
    : (health === "healthy" || health === "working") ? 12
    : health === "stale" ? 6 : 0;
  for (let i = 0; i < particleCount; i++) {
    const angle = tick * 0.025 + (i * Math.PI * 2) / particleCount;
    const orbitR = r + 20;
    const px2 = cx + Math.cos(angle) * orbitR;
    const py2 = cy + Math.sin(angle) * orbitR;
    const pSize = i % 3 === 0 ? 4 : 2;
    ctx.fillStyle = colors[1];
    ctx.beginPath();
    ctx.arc(px2, py2, pSize, 0, Math.PI * 2);
    ctx.fill();
  }

  // Second orbit (counter-rotating, smaller) — not when sleeping
  if (!sleeping && (health === "healthy" || health === "working")) {
    const innerCount = 6;
    for (let i = 0; i < innerCount; i++) {
      const angle = -(tick * 0.04) + (i * Math.PI * 2) / innerCount;
      const orbitR = r + 10;
      const px2 = cx + Math.cos(angle) * orbitR;
      const py2 = cy + Math.sin(angle) * orbitR;
      ctx.fillStyle = colors[3];
      ctx.beginPath();
      ctx.arc(px2, py2, 2, 0, Math.PI * 2);
      ctx.fill();
    }
  }

  // Label
  ctx.fillStyle = sleeping ? "#776688" : "#FFF";
  ctx.font = "bold 11px monospace";
  ctx.textAlign = "center";
  ctx.fillText("MOTHER BRAIN", cx, cy + r + 22);

  // Sleeping indicator: floating "Zzz"
  if (sleeping) {
    const zFloat = Math.sin(tick * 0.02) * 5;
    const zAlpha = 0.4 + Math.sin(tick * 0.03) * 0.3;
    ctx.globalAlpha = zAlpha;
    ctx.fillStyle = "#9988BB";
    ctx.font = "bold 14px monospace";
    ctx.fillText("Z", cx + r + 8, cy - r - 5 + zFloat);
    ctx.font = "bold 11px monospace";
    ctx.fillText("z", cx + r + 18, cy - r - 15 + zFloat * 0.7);
    ctx.font = "bold 8px monospace";
    ctx.fillText("z", cx + r + 24, cy - r - 22 + zFloat * 0.4);
    ctx.globalAlpha = 1;

    ctx.fillStyle = "#776688";
    ctx.font = "8px monospace";
    ctx.fillText("sleeping — no work", cx, cy + r + 34);
  }

  ctx.textAlign = "left";
}

// ============================================================
// Office environment drawing
// ============================================================

export function drawFloor(ctx: CanvasRenderingContext2D, W: number, H: number): void {
  const TILE = 16;
  for (let y = 0; y < H; y += TILE) {
    for (let x = 0; x < W; x += TILE) {
      const isLight = (Math.floor(x / TILE) + Math.floor(y / TILE)) % 2 === 0;
      ctx.fillStyle = isLight ? "#3D2E1C" : "#342816";
      ctx.fillRect(x, y, TILE, TILE);
    }
  }
}

export function drawWalls(ctx: CanvasRenderingContext2D, W: number, tick: number): void {
  // Wall base
  ctx.fillStyle = "#4A4A5A";
  ctx.fillRect(0, 0, W, 120);
  // Wall trim
  ctx.fillStyle = "#5A5A6A";
  ctx.fillRect(0, 115, W, 5);

  // Flickering fluorescent lights
  const lights = [120, 320, 520, 720];
  lights.forEach((lx, i) => {
    // Each light flickers independently using different tick offsets
    const flicker = (tick + i * 37) % 200;
    const on = flicker < 195 || flicker % 3 === 0;
    ctx.fillStyle = on ? "#FFFFF0" : "#888877";
    ctx.fillRect(lx, 8, 80, 6);
    // Glow effect when on
    if (on) {
      const glow = ctx.createLinearGradient(lx, 14, lx, 50);
      glow.addColorStop(0, "rgba(255,255,220,0.18)");
      glow.addColorStop(1, "transparent");
      ctx.fillStyle = glow;
      ctx.fillRect(lx - 10, 14, 100, 36);
    }
    // Light housing
    ctx.strokeStyle = "#666";
    ctx.lineWidth = 1;
    ctx.strokeRect(lx - 1, 7, 82, 8);
  });
}

// Marvel character colors for kanban cards (assignee key = lowercase, hyphens stripped)
const AGENT_CARD_COLORS: Record<string, string> = {
  "spider-man":      "#E62429", // Spidey red
  "ironman":         "#A6192E", // Hot rod red
  "iron-man":        "#A6192E",
  "blackpanther":    "#3A1C71", // Wakandan purple
  "black-panther":   "#3A1C71",
  "loki":            "#1F7A3D", // Loki green
  "captainamerica":  "#1C3F94", // Cap blue
  "captain-america": "#1C3F94",
  "beast":           "#1E5BC6", // Beast blue fur
  "wasp":            "#FFC72C", // Wasp yellow
  "songbird":        "#FF1493", // Sonic pink
  "warmachine":      "#5A5A5A", // Gunmetal
  "war-machine":     "#5A5A5A",
  "vision":          "#FF8F00", // Vision amber/cape gold
  "coulson":         "#003F7F", // S.H.I.E.L.D. navy
  "thor":            "#B0C4DE", // Mjolnir silver
  "nickfury":        "#1C1C1C", // Black trench coat
  "nick-fury":       "#1C1C1C",
};

interface WallKanbanData {
  sprint: string;
  columns: Array<{
    name: string;
    tasks: Array<{ id: string; points: number; assignee: string }>;
    point_sum: number;
  }>;
}

export function drawWallKanban(
  ctx: CanvasRenderingContext2D,
  kanban: WallKanbanData | null,
  tick: number
): void {
  const BX = 40, BY = 12, BW = 260, BH = 95;

  // Board background (whiteboard style)
  ctx.fillStyle = "#F0EDE8";
  ctx.fillRect(BX, BY, BW, BH);
  ctx.strokeStyle = "#555";
  ctx.lineWidth = 2;
  ctx.strokeRect(BX, BY, BW, BH);

  // No data yet
  if (!kanban || !kanban.columns) {
    ctx.fillStyle = "#999";
    ctx.font = "bold 9px monospace";
    ctx.fillText("KANBAN — loading...", BX + 10, BY + 50);
    return;
  }

  // Consolidate columns into 4: TODO, WIP (IN_PROGRESS+IN_REVIEW+QA), DONE, BLOCKED
  const todo: WallKanbanData["columns"][0]["tasks"] = [];
  const wip: WallKanbanData["columns"][0]["tasks"] = [];
  const done: WallKanbanData["columns"][0]["tasks"] = [];
  let totalPts = 0, donePts = 0;

  for (const col of kanban.columns) {
    const n = col.name.toUpperCase();
    if (n === "TODO") { todo.push(...col.tasks); }
    else if (n === "DONE") { done.push(...col.tasks); donePts += col.point_sum; }
    else if (n !== "BLOCKED") { wip.push(...col.tasks); }
    totalPts += col.point_sum;
  }

  // Column layout: 4 columns
  const cols = [
    { label: "TODO", tasks: todo, color: "#888" },
    { label: "WIP",  tasks: wip,  color: "#4488CC" },
    { label: "DONE", tasks: done, color: "#44AA44" },
  ];
  const colW = Math.floor((BW - 8) / 3);
  const headerH = 14;
  const cardH = 11;
  const cardGap = 2;
  const maxCards = 4; // max visible per column

  // Sprint title + progress bar
  const pct = totalPts > 0 ? donePts / totalPts : 0;
  ctx.fillStyle = "#444";
  ctx.font = "bold 7px monospace";
  ctx.fillText(kanban.sprint?.toUpperCase() || "SPRINT", BX + 4, BY + 9);
  // Progress bar
  const barX = BX + 80, barY = BY + 4, barW = 100, barH = 6;
  ctx.fillStyle = "#DDD";
  ctx.fillRect(barX, barY, barW, barH);
  ctx.fillStyle = "#44AA44";
  ctx.fillRect(barX, barY, barW * pct, barH);
  ctx.strokeStyle = "#999";
  ctx.lineWidth = 1;
  ctx.strokeRect(barX, barY, barW, barH);
  // Percentage text
  ctx.fillStyle = "#444";
  ctx.font = "bold 7px monospace";
  ctx.fillText(`${Math.round(pct * 100)}%`, barX + barW + 4, BY + 10);
  // Points text
  ctx.fillText(`${donePts}/${totalPts}`, BX + 220, BY + 10);

  // Column headers + dividers
  const colStartY = BY + headerH;
  cols.forEach((col, ci) => {
    const cx = BX + 4 + ci * colW;

    // Divider
    if (ci > 0) {
      ctx.strokeStyle = "#CCC";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(cx - 1, colStartY);
      ctx.lineTo(cx - 1, BY + BH - 2);
      ctx.stroke();
    }

    // Header
    ctx.fillStyle = col.color;
    ctx.font = "bold 7px monospace";
    ctx.fillText(col.label, cx + 2, colStartY + 8);
    // Count
    ctx.fillStyle = "#999";
    ctx.font = "6px monospace";
    ctx.fillText(`${col.tasks.length}`, cx + colW - 12, colStartY + 8);

    // Cards
    const visibleTasks = col.tasks.slice(0, maxCards);
    visibleTasks.forEach((task, ti) => {
      const cy = colStartY + 12 + ti * (cardH + cardGap);
      const assignee = (task.assignee || "").replace(/^@/, "").toLowerCase();
      const cardColor = AGENT_CARD_COLORS[assignee] || "#AAA";

      // Card background
      ctx.fillStyle = cardColor;
      ctx.fillRect(cx + 2, cy, colW - 6, cardH);

      // WIP cards: pulsing border
      if (col.label === "WIP" && tick % 40 < 20) {
        ctx.strokeStyle = "#FFF";
        ctx.lineWidth = 1;
        ctx.strokeRect(cx + 2, cy, colW - 6, cardH);
      }

      // DONE cards: checkmark
      if (col.label === "DONE") {
        ctx.fillStyle = "#FFF";
        ctx.font = "bold 7px monospace";
        ctx.fillText("✓", cx + colW - 14, cy + 8);
      }

      // Task ID (abbreviated)
      ctx.fillStyle = col.label === "DONE" ? "#FFF" : "#222";
      ctx.font = "6px monospace";
      const shortId = task.id.replace("PROJ-T-", "T");
      ctx.fillText(`${shortId} ${task.points}p`, cx + 4, cy + 8);
    });

    // "+N more" indicator
    if (col.tasks.length > maxCards) {
      const moreY = colStartY + 12 + maxCards * (cardH + cardGap);
      ctx.fillStyle = "#999";
      ctx.font = "6px monospace";
      ctx.fillText(`+${col.tasks.length - maxCards} more`, cx + 4, moreY + 6);
    }
  });
}

export function drawClock(ctx: CanvasRenderingContext2D): void {
  ctx.fillStyle = "#1A1A1A";
  ctx.fillRect(395, 22, 80, 60);
  ctx.strokeStyle = "#444";
  ctx.lineWidth = 2;
  ctx.strokeRect(395, 22, 80, 60);
  ctx.fillStyle = "#00EE00";
  ctx.font = "bold 20px monospace";
  const now = new Date();
  const hh = String(now.getHours()).padStart(2, "0");
  const mm = String(now.getMinutes()).padStart(2, "0");
  ctx.fillText(`${hh}:${mm}`, 403, 58);
  // Seconds indicator
  ctx.fillStyle = "#006600";
  ctx.font = "9px monospace";
  const ss = String(now.getSeconds()).padStart(2, "0");
  ctx.fillText(ss, 440, 75);
}

export function drawAegisShield(ctx: CanvasRenderingContext2D): void {
  ctx.fillStyle = "#6C5CE7";
  ctx.beginPath();
  ctx.moveTo(755, 22);
  ctx.lineTo(798, 38);
  ctx.lineTo(798, 76);
  ctx.lineTo(776, 98);
  ctx.lineTo(754, 76);
  ctx.lineTo(712, 76);
  ctx.lineTo(712, 38);
  ctx.closePath();
  ctx.fill();
  // Inner highlight
  ctx.fillStyle = "#8B7FFF";
  ctx.beginPath();
  ctx.moveTo(762, 34);
  ctx.lineTo(790, 46);
  ctx.lineTo(790, 70);
  ctx.lineTo(776, 85);
  ctx.lineTo(762, 70);
  ctx.lineTo(720, 70);
  ctx.lineTo(720, 46);
  ctx.closePath();
  ctx.fill();
  ctx.fillStyle = "#FFF";
  ctx.font = "bold 18px monospace";
  ctx.textAlign = "center";
  ctx.fillText("A", 756, 72);
  ctx.textAlign = "left";
}

export function drawPostItNotes(ctx: CanvasRenderingContext2D): void {
  const notes = [
    { x: 260, y: 25, color: "#FFFF88", text: "Ship it!" },
    { x: 310, y: 20, color: "#FFBB88", text: "TODO" },
    { x: 355, y: 28, color: "#88FFBB", text: "BUG" },
    { x: 840, y: 25, color: "#FF88BB", text: "Review" },
    { x: 885, y: 20, color: "#88BBFF", text: "PR#42" },
  ];
  ctx.font = "7px monospace";
  notes.forEach(({ x, y, color, text }) => {
    ctx.fillStyle = color;
    ctx.fillRect(x, y, 38, 32);
    ctx.strokeStyle = "rgba(0,0,0,0.15)";
    ctx.lineWidth = 1;
    ctx.strokeRect(x, y, 38, 32);
    ctx.fillStyle = "#333";
    ctx.fillText(text, x + 4, y + 16);
  });
}

export function drawWhiteboard(ctx: CanvasRenderingContext2D): void {
  ctx.fillStyle = "#FAFAFA";
  ctx.fillRect(580, 20, 120, 85);
  ctx.strokeStyle = "#888";
  ctx.lineWidth = 2;
  ctx.strokeRect(580, 20, 120, 85);
  // Frame
  ctx.fillStyle = "#BBBBCC";
  ctx.fillRect(578, 18, 124, 6);
  ctx.fillRect(578, 100, 124, 6);

  // Random scribbles
  ctx.strokeStyle = "#4444DD";
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.moveTo(590, 40); ctx.lineTo(620, 35); ctx.lineTo(640, 50); ctx.lineTo(660, 38);
  ctx.stroke();
  ctx.strokeStyle = "#DD4444";
  ctx.beginPath();
  ctx.moveTo(590, 60); ctx.lineTo(610, 70); ctx.lineTo(640, 58); ctx.lineTo(680, 68);
  ctx.stroke();
  // Box diagram
  ctx.strokeStyle = "#333";
  ctx.lineWidth = 1;
  ctx.strokeRect(590, 78, 20, 14);
  ctx.strokeRect(618, 78, 20, 14);
  ctx.strokeRect(646, 78, 20, 14);
  ctx.beginPath();
  ctx.moveTo(610, 85); ctx.lineTo(618, 85);
  ctx.moveTo(638, 85); ctx.lineTo(646, 85);
  ctx.stroke();
  // Arrows
  ctx.fillStyle = "#333";
  ctx.beginPath();
  ctx.moveTo(618, 82); ctx.lineTo(615, 85); ctx.lineTo(618, 88);
  ctx.moveTo(646, 82); ctx.lineTo(643, 85); ctx.lineTo(646, 88);
  ctx.fill();
}

export function drawDesk(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  isWorking: boolean,
  tick: number
): void {
  // Desk surface
  ctx.fillStyle = "#6B4226";
  ctx.fillRect(x, y, 80, 22);
  ctx.fillStyle = "#8B5E3C";
  ctx.fillRect(x + 2, y + 2, 76, 18);
  // Desk legs
  ctx.fillStyle = "#5A3520";
  ctx.fillRect(x + 4, y + 22, 8, 10);
  ctx.fillRect(x + 68, y + 22, 8, 10);

  // Monitor
  ctx.fillStyle = "#1A1A1A";
  ctx.fillRect(x + 18, y - 28, 36, 28);
  ctx.fillStyle = "#111";
  ctx.fillRect(x + 19, y - 27, 34, 24);
  // Monitor stand
  ctx.fillStyle = "#222";
  ctx.fillRect(x + 33, y - 1, 6, 3);
  ctx.fillRect(x + 29, y + 1, 14, 3);

  // Screen content
  if (isWorking) {
    // Code lines on screen
    const lineColor = tick % 20 < 10 ? "#44FF88" : "#33CC66";
    ctx.fillStyle = lineColor;
    ctx.fillRect(x + 22, y - 24, 28, 1);
    ctx.fillStyle = "#44AAFF";
    ctx.fillRect(x + 22, y - 20, 20, 1);
    ctx.fillRect(x + 22, y - 16, 24, 1);
    ctx.fillStyle = "#FFAA44";
    ctx.fillRect(x + 22, y - 12, 16, 1);
  } else {
    // Idle screen (dim)
    ctx.fillStyle = "#112233";
    ctx.fillRect(x + 22, y - 22, 28, 16);
  }

  // Keyboard
  ctx.fillStyle = "#333";
  ctx.fillRect(x + 14, y + 4, 30, 8);
  ctx.fillStyle = "#444";
  for (let ki = 0; ki < 5; ki++) {
    ctx.fillRect(x + 16 + ki * 6, y + 6, 4, 4);
  }

  // Mouse
  ctx.fillStyle = "#333";
  ctx.fillRect(x + 50, y + 5, 10, 7);

  // Coffee mug on desk
  ctx.fillStyle = "#FFFFFF";
  ctx.fillRect(x + 62, y + 3, 8, 8);
  ctx.fillStyle = "#7B3F00";
  ctx.fillRect(x + 63, y + 4, 6, 5);
  ctx.strokeStyle = "#FFFFFF";
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.arc(x + 70, y + 7, 3, -Math.PI * 0.5, Math.PI * 0.5);
  ctx.stroke();

  // Chair
  ctx.fillStyle = "#3A3A3A";
  ctx.fillRect(x + 20, y + 32, 40, 5);
  ctx.fillStyle = "#444";
  ctx.fillRect(x + 22, y + 37, 36, 18);
  ctx.fillStyle = "#333";
  ctx.fillRect(x + 26, y + 30, 6, 8);
  ctx.fillRect(x + 48, y + 30, 6, 8);
}

export function drawWaterCooler(ctx: CanvasRenderingContext2D, x: number, y: number, tick: number): void {
  // Base / body
  ctx.fillStyle = "#AAAACC";
  ctx.fillRect(x, y + 20, 26, 38);
  ctx.fillStyle = "#CCCCEE";
  ctx.fillRect(x + 2, y + 22, 22, 10);
  // Water jug
  ctx.fillStyle = "#88BBDD";
  ctx.fillRect(x + 4, y, 18, 22);
  ctx.fillStyle = "#AADDFF";
  ctx.fillRect(x + 6, y + 2, 14, 8);
  ctx.fillStyle = "#EEF8FF";
  ctx.fillRect(x + 7, y + 3, 6, 4);
  // Spigot
  ctx.fillStyle = "#666";
  ctx.fillRect(x + 6, y + 34, 6, 6);
  ctx.fillRect(x + 3, y + 36, 6, 3);
  // Water bubbles (animated)
  if (tick % 150 < 15) {
    const bubbleProgress = (tick % 150) / 15;
    ctx.fillStyle = "rgba(200,230,255,0.7)";
    ctx.beginPath();
    ctx.arc(x + 13, y + 5 - bubbleProgress * 8, 2, 0, Math.PI * 2);
    ctx.fill();
  }
  // Drip cup
  ctx.fillStyle = "#88AACC";
  ctx.fillRect(x + 4, y + 56, 18, 5);
}

export function drawCoffeeMachine(ctx: CanvasRenderingContext2D, x: number, y: number, tick: number): void {
  // Body
  ctx.fillStyle = "#222222";
  ctx.fillRect(x, y, 36, 50);
  ctx.fillStyle = "#333333";
  ctx.fillRect(x + 2, y + 2, 32, 46);
  // Display panel
  ctx.fillStyle = "#004400";
  ctx.fillRect(x + 5, y + 5, 26, 12);
  ctx.fillStyle = "#00CC00";
  ctx.font = "6px monospace";
  ctx.fillText("BREW", x + 9, y + 13);
  // Cup holder area
  ctx.fillStyle = "#111";
  ctx.fillRect(x + 7, y + 28, 22, 16);
  // Cup
  ctx.fillStyle = "#FFFFFF";
  ctx.fillRect(x + 12, y + 30, 12, 12);
  ctx.fillStyle = "#7B3F00";
  ctx.fillRect(x + 13, y + 31, 10, 8);
  // Steam animation
  if (tick % 3 < 2) {
    const steamFrame = tick % 60;
    const steamAlpha = Math.max(0, 1 - steamFrame / 60);
    ctx.fillStyle = `rgba(200,200,200,${steamAlpha * 0.6})`;
    ctx.beginPath();
    ctx.arc(x + 16 + Math.sin(tick * 0.1) * 2, y + 25 - (steamFrame % 20), 3, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.arc(x + 22 + Math.sin(tick * 0.1 + 1) * 2, y + 22 - (steamFrame % 25), 2, 0, Math.PI * 2);
    ctx.fill();
  }
  // Buttons
  ctx.fillStyle = "#FF4444";
  ctx.fillRect(x + 5, y + 20, 6, 4);
  ctx.fillStyle = "#4444FF";
  ctx.fillRect(x + 14, y + 20, 6, 4);
  ctx.fillStyle = "#44AA44";
  ctx.fillRect(x + 23, y + 20, 6, 4);
}

export function drawPlant(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  tick: number,
  variant: number = 0
): void {
  const sway = Math.sin(tick * 0.02 + variant) * 1.5;

  if (variant % 3 === 0) {
    // Tall leafy plant
    ctx.fillStyle = "#8B4513";
    ctx.fillRect(x + 5, y + 22, 14, 14);
    ctx.fillRect(x + 3, y + 20, 18, 5);
    ctx.fillStyle = "#228B22";
    ctx.fillRect(x + 10 + sway, y, 4, 24);
    ctx.fillStyle = "#32CD32";
    ctx.fillRect(x + 2 + sway, y + 4, 10, 7);
    ctx.fillRect(x + 12 + sway, y + 8, 10, 7);
    ctx.fillRect(x + 5 + sway, y - 2, 8, 6);
    ctx.fillRect(x + 1 + sway, y + 12, 8, 5);
  } else if (variant % 3 === 1) {
    // Round cactus
    ctx.fillStyle = "#8B4513";
    ctx.fillRect(x + 4, y + 20, 16, 12);
    ctx.fillRect(x + 2, y + 18, 20, 5);
    ctx.fillStyle = "#2E8B57";
    ctx.fillRect(x + 6, y + 4, 12, 16);
    ctx.fillRect(x + 4, y + 6, 16, 12);
    // Cactus spines
    ctx.fillStyle = "#FFEECC";
    for (let si = 0; si < 4; si++) {
      ctx.fillRect(x + 5 + si * 5, y + 6 + (si % 2) * 6, 1, 4);
    }
    // Flower on top
    ctx.fillStyle = "#FF69B4";
    ctx.fillRect(x + 10, y + 2, 4, 3);
  } else {
    // Fern / bushy plant
    ctx.fillStyle = "#8B4513";
    ctx.fillRect(x + 3, y + 22, 18, 10);
    ctx.fillRect(x + 1, y + 20, 22, 5);
    ctx.fillStyle = "#228B22";
    ctx.fillRect(x + 10 + sway, y + 5, 3, 18);
    ctx.fillStyle = "#3CB371";
    // Multiple fronds
    for (let f = 0; f < 5; f++) {
      const fx = x + 2 + f * 5 + sway * (f % 2 === 0 ? 1 : -1);
      const fy = y + 5 + (f % 2) * 4;
      ctx.fillRect(fx, fy, 7, 4);
    }
  }
}

export function drawMeetingRoom(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  w: number,
  h: number
): void {
  // Room walls
  ctx.strokeStyle = "#6A6A7A";
  ctx.lineWidth = 3;
  ctx.strokeRect(x, y, w, h);
  ctx.fillStyle = "#2E2219";
  ctx.fillRect(x + 2, y + 2, w - 4, h - 4);

  // Oval meeting table
  ctx.fillStyle = "#5C3D1E";
  ctx.beginPath();
  ctx.ellipse(x + w / 2, y + h / 2 + 10, w / 2 - 20, h / 3 - 10, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = "#7A5230";
  ctx.beginPath();
  ctx.ellipse(x + w / 2, y + h / 2 + 8, w / 2 - 24, h / 3 - 14, 0, 0, Math.PI * 2);
  ctx.fill();

  // Chairs around table
  const chairPositions = [
    { cx: x + 50, cy: y + 80 }, { cx: x + 100, cy: y + 65 },
    { cx: x + 150, cy: y + 65 }, { cx: x + 200, cy: y + 80 },
    { cx: x + 100, cy: y + 130 }, { cx: x + 150, cy: y + 130 },
  ];
  chairPositions.forEach(({ cx: chairX, cy: chairY }) => {
    ctx.fillStyle = "#3A3A4A";
    ctx.fillRect(chairX - 8, chairY - 8, 16, 12);
  });

  // Room label
  ctx.fillStyle = "#888898";
  ctx.font = "bold 11px monospace";
  ctx.textAlign = "center";
  ctx.fillText("MEETING ROOM", x + w / 2, y + 22);
  ctx.textAlign = "left";
}

// ============================================================
// Speech bubbles
// ============================================================

export function drawSpeechBubble(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  text: string,
  color: "white" | "green" | "red" | "yellow" | "blue" | "purple",
  alpha: number
): void {
  const bgColors: Record<string, string> = {
    white: "#FFFFFF",
    green: "#44CC44",
    red: "#CC4444",
    yellow: "#DDCC00",
    blue: "#4488CC",
    purple: "#9944CC",
  };
  const textColors: Record<string, string> = {
    white: "#222222",
    green: "#FFFFFF",
    red: "#FFFFFF",
    yellow: "#222222",
    blue: "#FFFFFF",
    purple: "#FFFFFF",
  };

  const padding = 5;
  ctx.font = "bold 9px monospace";
  const textW = ctx.measureText(text).width;
  const bubbleW = textW + padding * 2 + 2;
  const bubbleH = 16;
  const bx = x - bubbleW / 2;
  const by = y - bubbleH - 8;

  ctx.save();
  ctx.globalAlpha = alpha;

  // Background
  ctx.fillStyle = bgColors[color] || "#FFF";
  ctx.beginPath();
  ctx.roundRect(bx, by, bubbleW, bubbleH, 4);
  ctx.fill();

  // Outline
  ctx.strokeStyle = "rgba(0,0,0,0.3)";
  ctx.lineWidth = 1;
  ctx.stroke();

  // Tail
  ctx.fillStyle = bgColors[color] || "#FFF";
  ctx.beginPath();
  ctx.moveTo(x - 4, by + bubbleH);
  ctx.lineTo(x, by + bubbleH + 6);
  ctx.lineTo(x + 4, by + bubbleH);
  ctx.closePath();
  ctx.fill();

  // Text
  ctx.fillStyle = textColors[color] || "#222";
  ctx.textAlign = "center";
  ctx.fillText(text, x, by + 11);
  ctx.textAlign = "left";

  ctx.restore();
}

// ============================================================
// Status indicator above agent head
// ============================================================

export function drawStatusIndicator(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  status: string,
  tick: number
): void {
  const dotColors: Record<string, string> = {
    idle: "#AAAAAA",
    working: "#4488FF",
    waiting: "#FFAA00",
    done: "#44CC44",
    blocked: "#CC4444",
  };
  const color = dotColors[status] || "#888";
  const pulse = status === "working" ? 0.7 + Math.sin(tick * 0.15) * 0.3 : 1;
  ctx.fillStyle = color;
  ctx.globalAlpha = pulse;
  ctx.beginPath();
  ctx.arc(x, y, 3, 0, Math.PI * 2);
  ctx.fill();
  ctx.globalAlpha = 1;
}
