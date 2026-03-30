"use client";
import { useRef, useEffect, useState, useCallback } from "react";
import { useAgents } from "@/hooks/useAgents";
import { useHeartbeat } from "@/hooks/useHeartbeat";
import type { AgentState, HeartbeatStatus } from "@/types";

import type { PixelAgent } from "./types";
import {
  DESK_POSITIONS,
  ORB_POS,
  WATER_COOLER_POS,
  buildInitialPixelAgents,
  tickBehavior,
  bubbleAlpha,
} from "./behaviors";
import { stepAgent, advanceWalkFrame, resolveCollisions } from "./pathfinding";
import {
  drawNavi,
  drawSage,
  drawBolt,
  drawVigil,
  drawHavoc,
  drawForge,
  drawPixel,
  drawMuse,
  drawSentinel,
  drawProbe,
  drawScribe,
  drawOps,
  drawMotherBrainOrb,
  drawFloor,
  drawWalls,
  drawKanbanBoard,
  drawClock,
  drawAegisShield,
  drawPostItNotes,
  drawWhiteboard,
  drawDesk,
  drawWaterCooler,
  drawCoffeeMachine,
  drawPlant,
  drawMeetingRoom,
  drawSpeechBubble,
  drawStatusIndicator,
} from "./sprites";

// ---- Canvas dimensions ----
const CANVAS_W = 960;
const CANVAS_H = 640;
const SPRITE_W = 32;
const SPRITE_H = 32;

// ---- Sprite drawing dispatch ----
const SPRITE_DRAW: Record<
  string,
  (
    ctx: CanvasRenderingContext2D,
    ox: number,
    oy: number,
    walkFrame: number,
    status: string,
    tick: number
  ) => void
> = {
  Navi:     drawNavi,
  Sage:     drawSage,
  Bolt:     drawBolt,
  Vigil:    drawVigil,
  Havoc:    drawHavoc,
  Forge:    drawForge,
  Pixel:    drawPixel,
  Muse:     drawMuse,
  Sentinel: drawSentinel,
  Probe:    drawProbe,
  Scribe:   drawScribe,
  Ops:      drawOps,
};

interface Popup {
  agent: AgentState;
  x: number;
  y: number;
}

export function PixelOfficeCanvas() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const frameRef  = useRef(0);
  const tickRef   = useRef(0);
  const { agents } = useAgents();
  const { heartbeat } = useHeartbeat();
  const [popup, setPopup] = useState<Popup | null>(null);
  const [hoverName, setHoverName] = useState<string | null>(null);

  // Refs to avoid stale closures inside rAF
  const agentsRef    = useRef<AgentState[]>([]);
  const heartbeatRef = useRef<HeartbeatStatus | null>(null);
  const hoverRef     = useRef<string | null>(null);
  const pixelAgentsRef = useRef<PixelAgent[]>(buildInitialPixelAgents());

  agentsRef.current    = agents;
  heartbeatRef.current = heartbeat;
  hoverRef.current     = hoverName;

  // ---- Hit testing ----
  const getAgentAtPos = useCallback(
    (mx: number, my: number): AgentState | null => {
      const canvas = canvasRef.current;
      if (!canvas) return null;
      const rect   = canvas.getBoundingClientRect();
      const scaleX = CANVAS_W / rect.width;
      const scaleY = CANVAS_H / rect.height;
      const cx     = mx * scaleX;
      const cy     = my * scaleY;

      // Mother Brain orb
      const dOrb = Math.sqrt((cx - ORB_POS.x) ** 2 + (cy - ORB_POS.y) ** 2);
      if (dOrb < 50) {
        const mb = agentsRef.current.find((a) => a.name === "Mother Brain");
        if (mb) return mb;
      }

      // Agent sprites (use live pixel positions)
      for (const pa of pixelAgentsRef.current) {
        const spriteX = pa.x - SPRITE_W / 2;
        const spriteY = pa.y - SPRITE_H;
        if (
          cx >= spriteX - 8 &&
          cx <= spriteX + SPRITE_W + 8 &&
          cy >= spriteY - 8 &&
          cy <= pa.y + 8
        ) {
          const agent = agentsRef.current.find((a) => a.name === pa.name);
          if (agent) return agent;
        }
      }
      return null;
    },
    []
  );

  // ---- Main render loop ----
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animId: number;

    const draw = () => {
      tickRef.current++;
      const tick   = tickRef.current;
      const liveAgents = agentsRef.current;
      const hb     = heartbeatRef.current;
      const hover  = hoverRef.current;
      const pas    = pixelAgentsRef.current;

      ctx.imageSmoothingEnabled = false;

      // ==================== BEHAVIOR + MOVEMENT ====================

      // Tick behaviors for all agents
      for (const pa of pas) {
        const live = liveAgents.find((a) => a.name === pa.name);
        tickBehavior(pa, live, pas, tick);
      }

      // Step walking agents
      for (const pa of pas) {
        if (pa.behavior === "walking") {
          const arrived = stepAgent(pa);
          if (!arrived) {
            advanceWalkFrame(pa, tick);
          } else {
            pa.walkFrame = 1; // reset to standing
          }
        } else {
          pa.walkFrame = 1; // standing
        }
      }

      // Resolve collisions
      resolveCollisions(pas);

      // ==================== DRAW ====================

      // Floor
      drawFloor(ctx, CANVAS_W, CANVAS_H);

      // Walls + lights
      drawWalls(ctx, CANVAS_W, tick);

      // Wall decorations
      drawKanbanBoard(ctx);
      drawClock(ctx);
      drawAegisShield(ctx);
      drawPostItNotes(ctx);
      drawWhiteboard(ctx);

      // ---- Desks (back row first for painter's algorithm) ----
      for (const [name, dpos] of Object.entries(DESK_POSITIONS)) {
        const live = liveAgents.find((a) => a.name === name);
        const isWorking = live?.status === "working";
        // Desk top-left: center the desk under the agent foot position
        drawDesk(ctx, dpos.x - 40, dpos.y - 50, isWorking, tick);
      }

      // ---- Meeting room ----
      drawMeetingRoom(ctx, 490, 390, 260, 190);

      // ---- Mother Brain orb ----
      drawMotherBrainOrb(ctx, ORB_POS.x, ORB_POS.y, hb, tick);

      // ---- Water cooler ----
      drawWaterCooler(ctx, WATER_COOLER_POS.x - 13, WATER_COOLER_POS.y - 38, tick);

      // ---- Coffee machine ----
      drawCoffeeMachine(ctx, 185, 517, tick);

      // ---- Plants (variety) ----
      drawPlant(ctx, 42,  560, tick, 0);
      drawPlant(ctx, 78,  560, tick, 1);
      drawPlant(ctx, 430, 575, tick, 2);
      drawPlant(ctx, 460, 570, tick, 0);
      drawPlant(ctx, 760, 580, tick, 1);
      drawPlant(ctx, 920, 580, tick, 2);

      // ---- Agents (sorted by y so lower agents render in front) ----
      const sortedPas = [...pas].sort((a, b) => a.y - b.y);

      for (const pa of sortedPas) {
        const live   = liveAgents.find((a) => a.name === pa.name);
        const status = live?.status ?? "idle";

        const drawFn = SPRITE_DRAW[pa.name];
        if (!drawFn) continue;

        // Compute sprite top-left from feet position
        let spriteOX = Math.round(pa.x) - SPRITE_W / 2;
        let spriteOY = Math.round(pa.y) - SPRITE_H;

        // Status-based vertical offset animations
        if (pa.behavior === "celebrating" || (status === "done" && pa.behavior === "at_desk")) {
          spriteOY -= Math.abs(Math.sin(tick * 0.15)) * 10; // bounce!
        } else if (status === "waiting" && pa.behavior === "at_desk") {
          spriteOY += Math.sin(tick * 0.05) * 1.5;
        } else if (pa.behavior === "coffee_break" || pa.behavior === "chatting") {
          spriteOY += Math.sin(tick * 0.03) * 1; // gentle sway
        }

        // Flip sprite horizontally when facing left
        ctx.save();
        if (pa.facing === -1) {
          ctx.translate(spriteOX + SPRITE_W / 2, 0);
          ctx.scale(-1, 1);
          ctx.translate(-(spriteOX + SPRITE_W / 2), 0);
        }

        drawFn(ctx, spriteOX, spriteOY, pa.walkFrame, status, tick);

        ctx.restore();

        // Sparkles for celebrating/done agents
        if ((status === "done" || pa.behavior === "celebrating") && tick % 10 < 5) {
          ctx.fillStyle = "#FFD700";
          ctx.fillRect(spriteOX - 4, spriteOY - 4, 3, 3);
          ctx.fillRect(spriteOX + SPRITE_W + 2, spriteOY - 6, 3, 3);
          ctx.fillRect(spriteOX + SPRITE_W / 2, spriteOY - 10, 3, 3);
        }

        // Status dot above head
        drawStatusIndicator(ctx, spriteOX + SPRITE_W / 2, spriteOY - 6, status, tick);

        // Speech bubble
        if (pa.bubble) {
          const alpha = bubbleAlpha(pa.bubble, tick);
          if (alpha > 0) {
            drawSpeechBubble(
              ctx,
              spriteOX + SPRITE_W / 2,
              spriteOY - 8,
              pa.bubble.text,
              pa.bubble.color,
              alpha
            );
          }
        }

        // Hover name tag
        if (hover === pa.name) {
          const tagW = pa.name.length * 7 + 16;
          ctx.fillStyle = "rgba(0,0,0,0.85)";
          ctx.beginPath();
          ctx.roundRect(spriteOX + SPRITE_W / 2 - tagW / 2, spriteOY - 32, tagW, 16, 3);
          ctx.fill();
          ctx.fillStyle = "#FFFFFF";
          ctx.font = "bold 10px monospace";
          ctx.textAlign = "center";
          ctx.fillText(pa.name, spriteOX + SPRITE_W / 2, spriteOY - 20);
          ctx.textAlign = "left";
        }
      }

      animId = requestAnimationFrame(draw);
    };

    animId = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(animId);
  }, []);

  // ---- Event handlers ----
  const handleClick = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const rect = canvasRef.current!.getBoundingClientRect();
    const agent = getAgentAtPos(e.clientX - rect.left, e.clientY - rect.top);
    if (agent) {
      setPopup({ agent, x: e.clientX, y: e.clientY });
    } else {
      setPopup(null);
    }
  };

  const handleMouseMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const rect  = canvasRef.current!.getBoundingClientRect();
    const agent = getAgentAtPos(e.clientX - rect.left, e.clientY - rect.top);
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
        aria-label="AEGIS Pixel Office — animated visualization of 13 AI agents working in a virtual office"
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
              <td>{a.emoji} {a.name}</td>
              <td>{a.role}</td>
              <td>{a.status}</td>
              <td>{a.active_task?.title || "None"}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* Popup card on click */}
      {popup && (
        <div
          className="fixed z-50 bg-[var(--bg-elevated)] border border-[var(--border)] rounded-xl p-4 shadow-xl min-w-[220px]"
          style={{
            left: Math.min(popup.x + 12, window.innerWidth - 260),
            top:  Math.min(popup.y + 12, window.innerHeight - 220),
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
              <span className="text-[var(--text-primary)]">{popup.agent.status}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-[var(--text-secondary)]">Model:</span>
              <span className="text-[var(--text-primary)]">{popup.agent.model}</span>
            </div>
            {popup.agent.active_task && (
              <div className="flex justify-between">
                <span className="text-[var(--text-secondary)]">Task:</span>
                <span className="text-[var(--accent)]">{popup.agent.active_task.id}</span>
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
