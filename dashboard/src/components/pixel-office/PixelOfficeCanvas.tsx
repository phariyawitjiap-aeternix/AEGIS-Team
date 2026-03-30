"use client";
import { useRef, useEffect, useState, useCallback } from "react";
import { useAgents } from "@/hooks/useAgents";
import { useHeartbeat } from "@/hooks/useHeartbeat";
import type { AgentState, HeartbeatStatus } from "@/types";

// ---- Constants ----
const CANVAS_W = 960;
const CANVAS_H = 640;
const TILE = 16;
const SCALE = 3;
const SPRITE_SIZE = 16;

// ---- Agent Colors ----
const AGENT_COLORS: Record<string, string> = {
  "Mother Brain": "#FF00FF",
  Navi: "#00CED1",
  Sage: "#4B0082",
  Bolt: "#FFD700",
  Vigil: "#4682B4",
  Havoc: "#DC143C",
  Forge: "#B87333",
  Pixel: "#E6E6FA",
  Muse: "#B76E79",
  Sentinel: "#355E3B",
  Probe: "#FFBF00",
  Scribe: "#F5DEB3",
  Ops: "#2C3539",
};

// ---- Desk positions (pixel coords at 1x scale, top-left of desk) ----
const DESK_POSITIONS: Record<string, { x: number; y: number }> = {
  Navi: { x: 80, y: 180 },
  Sage: { x: 220, y: 180 },
  Bolt: { x: 360, y: 180 },
  Vigil: { x: 500, y: 180 },
  Havoc: { x: 640, y: 180 },
  Forge: { x: 80, y: 310 },
  Pixel: { x: 220, y: 310 },
  Muse: { x: 360, y: 310 },
  Sentinel: { x: 500, y: 310 },
  Probe: { x: 640, y: 310 },
  Scribe: { x: 80, y: 440 },
  Ops: { x: 220, y: 440 },
};

const ORB_POS = { x: 620, y: 470 };

interface Popup {
  agent: AgentState;
  x: number;
  y: number;
}

export function PixelOfficeCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const frameRef = useRef(0);
  const tickRef = useRef(0);
  const { agents } = useAgents();
  const { heartbeat } = useHeartbeat();
  const [popup, setPopup] = useState<Popup | null>(null);
  const [hoverName, setHoverName] = useState<string | null>(null);
  const agentsRef = useRef<AgentState[]>([]);
  const heartbeatRef = useRef<HeartbeatStatus | null>(null);

  agentsRef.current = agents;
  heartbeatRef.current = heartbeat;

  // ---- Hit testing ----
  const getAgentAtPos = useCallback(
    (mx: number, my: number): AgentState | null => {
      const canvas = canvasRef.current;
      if (!canvas) return null;
      const rect = canvas.getBoundingClientRect();
      const scaleX = CANVAS_W / rect.width;
      const scaleY = CANVAS_H / rect.height;
      const cx = mx * scaleX;
      const cy = my * scaleY;

      // Check Mother Brain orb
      const orbCx = ORB_POS.x + 24;
      const orbCy = ORB_POS.y + 24;
      const dist = Math.sqrt((cx - orbCx) ** 2 + (cy - orbCy) ** 2);
      if (dist < 40) {
        const mb = agentsRef.current.find((a) => a.name === "Mother Brain");
        if (mb) return mb;
      }

      // Check agent sprites
      for (const [name, pos] of Object.entries(DESK_POSITIONS)) {
        const sx = pos.x + 8; // center of desk
        const sy = pos.y - SPRITE_SIZE * SCALE + 8;
        if (
          cx >= sx - 20 &&
          cx <= sx + SPRITE_SIZE * SCALE + 20 &&
          cy >= sy - 10 &&
          cy <= sy + SPRITE_SIZE * SCALE + 10
        ) {
          const agent = agentsRef.current.find((a) => a.name === name);
          if (agent) return agent;
        }
      }
      return null;
    },
    []
  );

  // ---- Drawing ----
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animId: number;

    const draw = () => {
      tickRef.current++;
      const tick = tickRef.current;
      const agents = agentsRef.current;
      const hb = heartbeatRef.current;

      ctx.imageSmoothingEnabled = false;

      // ---- Floor ----
      ctx.fillStyle = "#2A1F14";
      ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);

      // Floor tiles
      for (let y = 0; y < CANVAS_H; y += TILE) {
        for (let x = 0; x < CANVAS_W; x += TILE) {
          const isLight = ((x / TILE + y / TILE) % 2) === 0;
          ctx.fillStyle = isLight ? "#3D2E1C" : "#342816";
          ctx.fillRect(x, y, TILE, TILE);
        }
      }

      // ---- Walls ----
      ctx.fillStyle = "#4A4A5A";
      ctx.fillRect(0, 0, CANVAS_W, 120);
      ctx.fillStyle = "#5A5A6A";
      ctx.fillRect(0, 115, CANVAS_W, 5);

      // ---- Wall decorations ----
      // Kanban board
      ctx.fillStyle = "#F5F5F0";
      ctx.fillRect(60, 20, 150, 80);
      ctx.strokeStyle = "#333";
      ctx.lineWidth = 2;
      ctx.strokeRect(60, 20, 150, 80);
      // Kanban columns
      ctx.strokeStyle = "#999";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(110, 20);
      ctx.lineTo(110, 100);
      ctx.moveTo(160, 20);
      ctx.lineTo(160, 100);
      ctx.stroke();
      ctx.fillStyle = "#333";
      ctx.font = "bold 8px monospace";
      ctx.fillText("TODO", 68, 35);
      ctx.fillText("WIP", 120, 35);
      ctx.fillText("DONE", 168, 35);
      // Mini cards (colored dots)
      const miniColors = ["#FFD700", "#00CED1", "#4B0082"];
      miniColors.forEach((c, i) => {
        ctx.fillStyle = c;
        ctx.fillRect(75 + (i % 2) * 15, 45 + Math.floor(i / 2) * 15, 10, 8);
      });

      // Clock
      ctx.fillStyle = "#222";
      ctx.fillRect(400, 30, 60, 50);
      ctx.fillStyle = "#0F0";
      ctx.font = "bold 16px monospace";
      const now = new Date();
      const timeStr = `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
      ctx.fillText(timeStr, 408, 62);

      // AEGIS Shield
      ctx.fillStyle = "#6C5CE7";
      ctx.beginPath();
      ctx.moveTo(750, 25);
      ctx.lineTo(790, 40);
      ctx.lineTo(790, 75);
      ctx.lineTo(770, 95);
      ctx.lineTo(750, 75);
      ctx.lineTo(710, 75);
      ctx.lineTo(710, 40);
      ctx.closePath();
      ctx.fill();
      ctx.fillStyle = "#FFF";
      ctx.font = "bold 14px monospace";
      ctx.fillText("A", 743, 67);

      // ---- Desks and Agents ----
      for (const [name, pos] of Object.entries(DESK_POSITIONS)) {
        const agent = agents.find((a) => a.name === name);
        const color = AGENT_COLORS[name] || "#888";

        // Desk
        ctx.fillStyle = "#6B4226";
        ctx.fillRect(pos.x, pos.y, SPRITE_SIZE * SCALE + 16, 20);
        ctx.fillStyle = "#8B5E3C";
        ctx.fillRect(pos.x + 2, pos.y + 2, SPRITE_SIZE * SCALE + 12, 16);

        // Monitor on desk
        ctx.fillStyle = "#111";
        ctx.fillRect(pos.x + 4, pos.y - 12, 20, 14);
        // Screen glow if working
        if (agent?.status === "working") {
          ctx.fillStyle =
            tick % 20 < 10 ? "#4488FF" : "#3377DD";
          ctx.fillRect(pos.x + 6, pos.y - 10, 16, 10);
        } else {
          ctx.fillStyle = "#223";
          ctx.fillRect(pos.x + 6, pos.y - 10, 16, 10);
        }

        // Chair
        ctx.fillStyle = "#555";
        ctx.fillRect(pos.x + 16, pos.y + 22, 20, 16);

        // Agent sprite (simple pixel character)
        const spriteX = pos.x + 12;
        let spriteY = pos.y - SPRITE_SIZE * SCALE + 4;

        // Breathing animation (idle bob)
        if (agent?.status === "idle" || !agent) {
          spriteY += tick % 40 < 20 ? 0 : 1;
        }
        // Working: slight lean
        if (agent?.status === "working") {
          spriteY += tick % 30 < 15 ? -1 : 0;
        }
        // Waiting: side sway
        if (agent?.status === "waiting") {
          const sway = Math.sin(tick * 0.05) * 2;
          spriteY += 4; // standing
          ctx.save();
          ctx.translate(sway, 0);
        }
        // Done: jump
        if (agent?.status === "done") {
          spriteY -= Math.abs(Math.sin(tick * 0.15)) * 8;
        }

        // Draw sprite body
        drawAgentSprite(ctx, spriteX, spriteY, color, agent?.status || "idle", tick, name);

        if (agent?.status === "waiting") {
          ctx.restore();
        }

        // Hover name tag
        if (hoverName === name) {
          ctx.fillStyle = "rgba(0,0,0,0.8)";
          const tagW = name.length * 8 + 16;
          ctx.fillRect(spriteX - 4, spriteY - 18, tagW, 16);
          ctx.fillStyle = "#FFF";
          ctx.font = "10px monospace";
          ctx.fillText(name, spriteX + 4, spriteY - 6);
        }
      }

      // ---- Meeting Room ----
      ctx.strokeStyle = "#6A6A7A";
      ctx.lineWidth = 3;
      ctx.strokeRect(500, 400, 250, 180);
      ctx.fillStyle = "#3D2E1C";
      ctx.fillRect(502, 402, 246, 176);

      // Meeting room label
      ctx.fillStyle = "#6A6A7A";
      ctx.font = "bold 10px monospace";
      ctx.fillText("MEETING ROOM", 555, 420);

      // ---- Mother Brain Orb ----
      drawMotherBrainOrb(ctx, ORB_POS.x + 24, ORB_POS.y + 24, hb, tick);

      // ---- Props ----
      // Water cooler
      ctx.fillStyle = "#88BBDD";
      ctx.fillRect(100, 530, 20, 30);
      ctx.fillStyle = "#AADDFF";
      ctx.fillRect(102, 532, 16, 10);
      // Bubble animation
      if (tick % 150 < 10) {
        ctx.fillStyle = "#CCEFFF";
        ctx.beginPath();
        ctx.arc(112, 530 - (tick % 150) * 2, 3, 0, Math.PI * 2);
        ctx.fill();
      }

      // Plants
      drawPlant(ctx, 160, 525, tick);
      drawPlant(ctx, 180, 525, tick + 20);

      animId = requestAnimationFrame(draw);
    };

    animId = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(animId);
  }, [hoverName]);

  // ---- Event handlers ----
  const handleClick = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const rect = canvasRef.current!.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;
    const agent = getAgentAtPos(mx, my);
    if (agent) {
      setPopup({ agent, x: e.clientX, y: e.clientY });
    } else {
      setPopup(null);
    }
  };

  const handleMouseMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const rect = canvasRef.current!.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;
    const agent = getAgentAtPos(mx, my);
    setHoverName(agent?.name ?? null);
    if (canvasRef.current) {
      canvasRef.current.style.cursor = agent ? "pointer" : "default";
    }
  };

  return (
    <div className="relative">
      <canvas
        ref={canvasRef}
        width={CANVAS_W}
        height={CANVAS_H}
        onClick={handleClick}
        onMouseMove={handleMouseMove}
        className="w-full max-w-[960px] border border-[var(--border)] rounded-xl"
        style={{ imageRendering: "pixelated" }}
        aria-label="AEGIS Pixel Office - animated visualization of 13 AI agents working in a virtual office"
      />

      {/* Accessible table for screen readers */}
      <table className="sr-only" aria-label="Agent status table">
        <thead>
          <tr>
            <th>Agent</th>
            <th>Role</th>
            <th>Status</th>
            <th>Current Task</th>
          </tr>
        </thead>
        <tbody>
          {agents.map((a) => (
            <tr key={a.name}>
              <td>
                {a.emoji} {a.name}
              </td>
              <td>{a.role}</td>
              <td>{a.status}</td>
              <td>{a.active_task?.title || "None"}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* Popup card */}
      {popup && (
        <div
          className="fixed z-50 bg-[var(--bg-elevated)] border border-[var(--border)] rounded-xl p-4 shadow-xl min-w-[220px]"
          style={{
            left: Math.min(popup.x + 10, window.innerWidth - 260),
            top: Math.min(popup.y + 10, window.innerHeight - 200),
          }}
        >
          <div className="flex items-center gap-2 mb-2">
            <span className="text-xl">{popup.agent.emoji}</span>
            <div>
              <div className="font-semibold text-[var(--text-primary)]">
                {popup.agent.name}
              </div>
              <div className="text-xs text-[var(--text-secondary)]">
                {popup.agent.role}
              </div>
            </div>
          </div>
          <div className="text-xs space-y-1">
            <div className="flex justify-between">
              <span className="text-[var(--text-secondary)]">Status:</span>
              <span className="text-[var(--text-primary)]">
                {popup.agent.status}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-[var(--text-secondary)]">Model:</span>
              <span className="text-[var(--text-primary)]">
                {popup.agent.model}
              </span>
            </div>
            {popup.agent.active_task && (
              <div className="flex justify-between">
                <span className="text-[var(--text-secondary)]">Task:</span>
                <span className="text-[var(--accent)]">
                  {popup.agent.active_task.id}
                </span>
              </div>
            )}
            <div className="flex justify-between">
              <span className="text-[var(--text-secondary)]">Done:</span>
              <span className="text-[var(--text-primary)]">
                {popup.agent.tasks_completed} tasks / {popup.agent.points_completed} pts
              </span>
            </div>
          </div>
          <button
            onClick={() => setPopup(null)}
            className="mt-3 w-full text-xs text-center text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
          >
            Close
          </button>
        </div>
      )}
    </div>
  );
}

// ---- Helper draw functions ----

function drawAgentSprite(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  color: string,
  status: string,
  tick: number,
  name: string
) {
  const s = SCALE;

  // Head
  ctx.fillStyle = "#FFCC99"; // skin
  ctx.fillRect(x + 4 * s, y, 8 * s, 8 * s);

  // Hair / accessory color
  ctx.fillStyle = color;
  ctx.fillRect(x + 4 * s, y, 8 * s, 3 * s);

  // Eyes
  ctx.fillStyle = "#333";
  ctx.fillRect(x + 6 * s, y + 4 * s, 2 * s, 2 * s);
  ctx.fillRect(x + 10 * s, y + 4 * s, 2 * s, 2 * s);
  // Blink
  if (tick % 120 > 115) {
    ctx.fillStyle = "#FFCC99";
    ctx.fillRect(x + 6 * s, y + 4 * s, 2 * s, 1 * s);
    ctx.fillRect(x + 10 * s, y + 4 * s, 2 * s, 1 * s);
  }

  // Body
  ctx.fillStyle = color;
  ctx.fillRect(x + 2 * s, y + 8 * s, 12 * s, 8 * s);

  // Arms
  if (status === "working") {
    // Arms forward (typing)
    const armFrame = tick % 20 < 10;
    ctx.fillRect(
      x + (armFrame ? 0 : 1) * s,
      y + 9 * s,
      3 * s,
      5 * s
    );
    ctx.fillRect(
      x + (armFrame ? 13 : 12) * s,
      y + 9 * s,
      3 * s,
      5 * s
    );
  } else if (status === "done") {
    // Arms up (celebrating)
    ctx.fillRect(x, y + 4 * s, 3 * s, 5 * s);
    ctx.fillRect(x + 13 * s, y + 4 * s, 3 * s, 5 * s);
    // Sparkles
    if (tick % 10 < 5) {
      ctx.fillStyle = "#FFD700";
      ctx.fillRect(x - 4 * s, y - 2 * s, 2 * s, 2 * s);
      ctx.fillRect(x + 16 * s, y - 4 * s, 2 * s, 2 * s);
      ctx.fillRect(x + 8 * s, y - 6 * s, 2 * s, 2 * s);
    }
  } else {
    // Arms at sides
    ctx.fillRect(x, y + 9 * s, 3 * s, 6 * s);
    ctx.fillRect(x + 13 * s, y + 9 * s, 3 * s, 6 * s);
  }

  // Name badge under desk area (subtle)
  ctx.fillStyle = "rgba(255,255,255,0.6)";
  ctx.font = "8px monospace";

  // Agent-specific accessories
  drawAccessory(ctx, x, y, name, color, s);
}

function drawAccessory(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  name: string,
  color: string,
  s: number
) {
  ctx.fillStyle = color;
  switch (name) {
    case "Navi":
      // Compass pendant
      ctx.fillStyle = "#FFD700";
      ctx.fillRect(x + 7 * s, y + 8 * s, 2 * s, 2 * s);
      break;
    case "Bolt":
      // Lightning bolt hair spike
      ctx.fillStyle = "#FFD700";
      ctx.fillRect(x + 8 * s, y - 2 * s, 2 * s, 3 * s);
      ctx.fillRect(x + 6 * s, y - 1 * s, 2 * s, 2 * s);
      break;
    case "Havoc":
      // Horns
      ctx.fillStyle = "#DC143C";
      ctx.fillRect(x + 3 * s, y - 2 * s, 2 * s, 3 * s);
      ctx.fillRect(x + 11 * s, y - 2 * s, 2 * s, 3 * s);
      break;
    case "Vigil":
      // Shield emblem
      ctx.fillStyle = "#4682B4";
      ctx.fillRect(x + 6 * s, y + 10 * s, 4 * s, 4 * s);
      break;
    case "Forge":
      // Wrench
      ctx.fillStyle = "#888";
      ctx.fillRect(x + 14 * s, y + 8 * s, 3 * s, 1 * s);
      ctx.fillRect(x + 16 * s, y + 7 * s, 1 * s, 3 * s);
      break;
    case "Pixel":
      // Paint brush
      ctx.fillStyle = "#E6E6FA";
      ctx.fillRect(x + 12 * s, y + 1 * s, 1 * s, 5 * s);
      ctx.fillStyle = "#FF6B6B";
      ctx.fillRect(x + 12 * s, y, 1 * s, 2 * s);
      break;
    case "Muse":
      // Beret
      ctx.fillStyle = "#B76E79";
      ctx.fillRect(x + 3 * s, y - 1 * s, 10 * s, 2 * s);
      ctx.fillRect(x + 5 * s, y - 2 * s, 6 * s, 2 * s);
      break;
    case "Sentinel":
      // Monocle
      ctx.fillStyle = "#FFD700";
      ctx.strokeStyle = "#FFD700";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.arc(x + 11 * s, y + 5 * s, 2 * s, 0, Math.PI * 2);
      ctx.stroke();
      break;
    case "Probe":
      // Magnifying glass
      ctx.fillStyle = "#FFBF00";
      ctx.beginPath();
      ctx.arc(x + 15 * s, y + 6 * s, 2 * s, 0, Math.PI * 2);
      ctx.stroke();
      ctx.fillRect(x + 16 * s, y + 8 * s, 1 * s, 3 * s);
      break;
    case "Scribe":
      // Quill
      ctx.fillStyle = "#F5DEB3";
      ctx.fillRect(x + 14 * s, y + 3 * s, 1 * s, 6 * s);
      ctx.fillStyle = "#FFF";
      ctx.fillRect(x + 14 * s, y + 2 * s, 1 * s, 2 * s);
      break;
    case "Ops":
      // Rocket pin
      ctx.fillStyle = "#FF4444";
      ctx.fillRect(x + 7 * s, y + 8 * s, 2 * s, 3 * s);
      ctx.fillStyle = "#FF8844";
      ctx.fillRect(x + 7 * s, y + 11 * s, 2 * s, 1 * s);
      break;
  }
}

function drawMotherBrainOrb(
  ctx: CanvasRenderingContext2D,
  cx: number,
  cy: number,
  hb: HeartbeatStatus | null,
  tick: number
) {
  const health = hb?.health || "unknown";

  const colorMap: Record<string, string[]> = {
    healthy: ["#FF00FF", "#FF66FF", "#CC00CC"],
    stale: ["#AAAA00", "#DDDD44", "#888800"],
    dead: ["#880000", "#AA2222", "#660000"],
    unknown: ["#666666", "#888888", "#444444"],
  };
  const colors = colorMap[health] || colorMap.unknown;

  // Pulse
  const pulseScale =
    health === "healthy"
      ? 1 + Math.sin(tick * 0.1) * 0.05
      : health === "stale"
      ? 1 + Math.sin(tick * 0.03) * 0.03
      : 1;

  const r = 32 * pulseScale;

  // Glow
  if (health === "healthy") {
    const gradient = ctx.createRadialGradient(cx, cy, r * 0.5, cx, cy, r * 2);
    gradient.addColorStop(0, colors[1] + "44");
    gradient.addColorStop(1, "transparent");
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.arc(cx, cy, r * 2, 0, Math.PI * 2);
    ctx.fill();
  }

  // Orb body
  const orbGrad = ctx.createRadialGradient(
    cx - r * 0.2,
    cy - r * 0.2,
    r * 0.1,
    cx,
    cy,
    r
  );
  orbGrad.addColorStop(0, colors[1]);
  orbGrad.addColorStop(0.7, colors[0]);
  orbGrad.addColorStop(1, colors[2]);
  ctx.fillStyle = orbGrad;
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.fill();

  // Particle ring
  const particleCount = health === "healthy" ? 8 : health === "stale" ? 4 : 0;
  for (let i = 0; i < particleCount; i++) {
    const angle = (tick * 0.02) + (i * Math.PI * 2) / particleCount;
    const px = cx + Math.cos(angle) * (r + 15);
    const py = cy + Math.sin(angle) * (r + 15);
    ctx.fillStyle = colors[1];
    ctx.beginPath();
    ctx.arc(px, py, 3, 0, Math.PI * 2);
    ctx.fill();
  }

  // Label
  ctx.fillStyle = "#FFF";
  ctx.font = "bold 10px monospace";
  ctx.textAlign = "center";
  ctx.fillText("MOTHER BRAIN", cx, cy + r + 20);
  ctx.textAlign = "left";
}

function drawPlant(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  tick: number
) {
  // Pot
  ctx.fillStyle = "#8B4513";
  ctx.fillRect(x, y + 15, 18, 12);
  ctx.fillRect(x - 2, y + 14, 22, 4);

  // Stem
  const sway = Math.sin(tick * 0.02) * 1;
  ctx.fillStyle = "#228B22";
  ctx.fillRect(x + 7 + sway, y, 4, 16);

  // Leaves
  ctx.fillStyle = "#32CD32";
  ctx.fillRect(x + 2 + sway, y + 2, 8, 5);
  ctx.fillRect(x + 10 + sway, y + 5, 8, 5);
  ctx.fillRect(x + 4 + sway, y - 3, 6, 5);
}
