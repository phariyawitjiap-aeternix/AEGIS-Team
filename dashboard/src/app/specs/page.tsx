"use client";
import { Header } from "@/components/layout/Header";
import useSWR from "swr";
import { useState } from "react";
import type { ApiResponse } from "@/types";

const fetcher = (url: string) => fetch(url).then((r) => r.json());

interface FileNode {
  name: string;
  path: string;
  type: "file" | "directory";
  children?: FileNode[];
}

function TreeItem({
  node,
  onSelect,
  selected,
  depth = 0,
}: {
  node: FileNode;
  onSelect: (path: string) => void;
  selected: string | null;
  depth?: number;
}) {
  const [open, setOpen] = useState(depth < 1);

  if (node.type === "directory") {
    return (
      <div>
        <button
          onClick={() => setOpen(!open)}
          className="flex items-center gap-1 w-full text-left px-2 py-1 text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
          style={{ paddingLeft: `${depth * 16 + 8}px` }}
        >
          <span className="text-xs">{open ? "v" : ">"}</span>
          <span>{node.name}/</span>
        </button>
        {open &&
          node.children?.map((child) => (
            <TreeItem
              key={child.path}
              node={child}
              onSelect={onSelect}
              selected={selected}
              depth={depth + 1}
            />
          ))}
      </div>
    );
  }

  return (
    <button
      onClick={() => onSelect(node.path)}
      className={`w-full text-left px-2 py-1 text-sm transition-colors ${
        selected === node.path
          ? "text-[var(--accent)] bg-[var(--accent)]/10"
          : "text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
      }`}
      style={{ paddingLeft: `${depth * 16 + 8}px` }}
    >
      {node.name}
    </button>
  );
}

export default function SpecsPage() {
  const { data } = useSWR<ApiResponse<FileNode[]>>("/api/specs", fetcher, {
    refreshInterval: 30000,
  });
  const [selectedPath, setSelectedPath] = useState<string | null>(null);
  const [content, setContent] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const tree = data?.data ?? [];

  const handleSelect = async (filePath: string) => {
    setSelectedPath(filePath);
    setLoading(true);
    try {
      const res = await fetch(
        `/api/specs?file=${encodeURIComponent(filePath)}`
      );
      const json = await res.json();
      setContent(json.data || "No content");
    } catch {
      setContent("Error loading file");
    }
    setLoading(false);
  };

  return (
    <div>
      <Header title="Spec Viewer" />
      <div className="flex h-[calc(100vh-3.5rem)]">
        {/* File tree sidebar */}
        <div className="w-64 shrink-0 border-r border-[var(--border)] bg-[var(--bg-surface)] overflow-y-auto py-2">
          {tree.length === 0 ? (
            <div className="p-4 text-xs text-[var(--text-secondary)]">
              No specs found
            </div>
          ) : (
            tree.map((node) => (
              <TreeItem
                key={node.path}
                node={node}
                onSelect={handleSelect}
                selected={selectedPath}
              />
            ))
          )}
        </div>

        {/* Content pane */}
        <div className="flex-1 overflow-y-auto p-6">
          {loading ? (
            <div className="animate-pulse text-[var(--text-secondary)]">
              Loading...
            </div>
          ) : content ? (
            <pre className="text-sm text-[var(--text-primary)] whitespace-pre-wrap font-mono leading-relaxed">
              {content}
            </pre>
          ) : (
            <div className="text-center text-[var(--text-secondary)] py-20">
              Select a spec file from the sidebar
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
