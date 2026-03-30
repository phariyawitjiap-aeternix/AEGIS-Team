import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";
import { BRAIN_DIR } from "@/lib/constants";
import type { ApiResponse } from "@/types";

export const dynamic = "force-dynamic";

interface ContextBudget {
  used_pct: number;
  total_tokens: number;
  used_tokens: number;
  breakdown: {
    category: string;
    tokens: number;
    pct: number;
  }[];
  health: "green" | "yellow" | "red";
}

export async function GET() {
  try {
    // Try reading token-usage.json
    let tokenData: Record<string, number> = {};
    try {
      const tokenPath = path.join(
        BRAIN_DIR,
        "metrics",
        "token-usage.json"
      );
      const content = await fs.readFile(tokenPath, "utf-8");
      tokenData = JSON.parse(content);
    } catch {
      // no token data available
    }

    // Try reading skill-cache stats
    let cacheStats = { total_patterns: 0 };
    try {
      const statsPath = path.join(
        BRAIN_DIR,
        "skill-cache",
        "stats.json"
      );
      const content = await fs.readFile(statsPath, "utf-8");
      cacheStats = JSON.parse(content);
    } catch {
      // no cache stats
    }

    // Estimate context usage (simplified model)
    const totalTokens = 200000; // 200k context window
    const skillTokens = cacheStats.total_patterns * 500;
    const brainTokens = 15000; // estimated brain files loaded
    const conversationTokens = tokenData.conversation || 50000;
    const usedTokens = skillTokens + brainTokens + conversationTokens;
    const usedPct = Math.min(100, Math.round((usedTokens / totalTokens) * 100));

    let health: ContextBudget["health"] = "green";
    if (usedPct >= 80) health = "red";
    else if (usedPct >= 60) health = "yellow";

    const data: ContextBudget = {
      used_pct: usedPct,
      total_tokens: totalTokens,
      used_tokens: usedTokens,
      breakdown: [
        {
          category: "Skills",
          tokens: skillTokens,
          pct: Math.round((skillTokens / totalTokens) * 100),
        },
        {
          category: "Brain Files",
          tokens: brainTokens,
          pct: Math.round((brainTokens / totalTokens) * 100),
        },
        {
          category: "Conversation",
          tokens: conversationTokens,
          pct: Math.round((conversationTokens / totalTokens) * 100),
        },
      ],
      health,
    };

    const response: ApiResponse<ContextBudget> = {
      ok: true,
      data,
      timestamp: new Date().toISOString(),
    };

    return NextResponse.json(response);
  } catch (err) {
    return NextResponse.json(
      {
        ok: false,
        data: null,
        error: process.env.NODE_ENV === "development" ? String(err) : "Internal error",
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}
