import { NextResponse } from "next/server";
import fs from "fs/promises";
import path from "path";
import { OUTPUT_DIR } from "@/lib/constants";
import type { ApiResponse } from "@/types";

export const dynamic = "force-dynamic";

interface FileTreeNode {
  name: string;
  path: string;
  type: "file" | "directory";
  children?: FileTreeNode[];
}

async function buildTree(dirPath: string, basePath: string): Promise<FileTreeNode[]> {
  try {
    const entries = await fs.readdir(dirPath, { withFileTypes: true });
    const nodes: FileTreeNode[] = [];

    for (const entry of entries.sort((a, b) => a.name.localeCompare(b.name))) {
      const fullPath = path.join(dirPath, entry.name);
      const relativePath = path.relative(basePath, fullPath);

      if (entry.isDirectory()) {
        const children = await buildTree(fullPath, basePath);
        nodes.push({
          name: entry.name,
          path: relativePath,
          type: "directory",
          children,
        });
      } else if (
        entry.name.endsWith(".md") ||
        entry.name.endsWith(".json") ||
        entry.name.endsWith(".txt")
      ) {
        nodes.push({
          name: entry.name,
          path: relativePath,
          type: "file",
        });
      }
    }

    return nodes;
  } catch {
    return [];
  }
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const filePath = searchParams.get("file");

    // If a file path is provided, return its content
    if (filePath) {
      if (filePath.includes("..")) {
        return NextResponse.json(
          { ok: false, data: null, error: "Path traversal denied", timestamp: new Date().toISOString() },
          { status: 403 }
        );
      }
      const specsDir = path.join(OUTPUT_DIR, "specs");
      const fullPath = path.resolve(specsDir, filePath);
      if (!fullPath.startsWith(specsDir)) {
        return NextResponse.json(
          { ok: false, data: null, error: "Path outside specs directory", timestamp: new Date().toISOString() },
          { status: 403 }
        );
      }
      const content = await fs.readFile(fullPath, "utf-8");
      return NextResponse.json({
        ok: true,
        data: content,
        timestamp: new Date().toISOString(),
      });
    }

    // Otherwise return the file tree
    const specsDir = path.join(OUTPUT_DIR, "specs");
    const tree = await buildTree(specsDir, specsDir);

    const response: ApiResponse<FileTreeNode[]> = {
      ok: true,
      data: tree,
      timestamp: new Date().toISOString(),
    };

    return NextResponse.json(response);
  } catch (err) {
    return NextResponse.json({
      ok: false,
      data: [],
      error: String(err),
      timestamp: new Date().toISOString(),
    });
  }
}
