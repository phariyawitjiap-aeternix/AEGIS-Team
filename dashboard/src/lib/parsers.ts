import type { ActivityLogEntry, KanbanBoard, KanbanColumn, KanbanTask, TaskStatus } from "@/types";

/**
 * Parse activity.log lines into structured entries.
 */
export function parseActivityLog(content: string): ActivityLogEntry[] {
  const lines = content.split("\n").filter((l) => l.trim() && !l.startsWith("#"));
  return lines.map((raw) => {
    // Format: [timestamp] EMOJI? EVENT_TYPE | rest...
    // or: [timestamp] EVENT_TYPE | rest...
    const match = raw.match(
      /^\[([^\]]+)\]\s*([^\w\s]*)?\s*(\w+)\s*[|—-]\s*(.*)$/
    );
    if (!match) {
      return {
        timestamp: "",
        event_type: "UNKNOWN",
        message: raw,
        raw,
      };
    }
    return {
      timestamp: match[1].trim(),
      agent_emoji: match[2]?.trim() || undefined,
      event_type: match[3].trim(),
      message: match[4].trim(),
      raw,
    };
  });
}

/**
 * Parse kanban.md into structured KanbanBoard.
 */
export function parseKanbanMd(content: string): KanbanBoard {
  const columns: KanbanColumn[] = [];
  let currentColumn: KanbanColumn | null = null;
  let sprint = "";
  let updated = "";

  const lines = content.split("\n");

  for (const line of lines) {
    // Extract metadata
    const updatedMatch = line.match(/Updated:\s*([^\|]+)/);
    if (updatedMatch) {
      updated = updatedMatch[1].trim();
    }

    // Match column headers like "## TODO (1 task, 5 pts)"
    const colMatch = line.match(
      /^##\s+(TODO|IN_PROGRESS|IN_REVIEW|QA|DONE|BLOCKED)\s*\((\d+)\s*tasks?,\s*(\d+)\s*pts?\)/
    );
    if (colMatch) {
      if (currentColumn) columns.push(currentColumn);
      currentColumn = {
        name: colMatch[1] as TaskStatus,
        tasks: [],
        task_count: parseInt(colMatch[2]),
        point_sum: parseInt(colMatch[3]),
      };
      continue;
    }

    // Match table rows: | PROJ-T-001 | title | pts | @assignee | priority |
    if (currentColumn && line.startsWith("|") && !line.includes("---")) {
      const cells = line
        .split("|")
        .map((c) => c.trim())
        .filter(Boolean);
      if (cells.length >= 5 && cells[0].startsWith("PROJ-")) {
        const task: KanbanTask = {
          id: cells[0],
          title: cells[1],
          points: parseInt(cells[2]) || 0,
          assignee: cells[3].replace("@", ""),
          priority: cells[4] as KanbanTask["priority"],
        };
        currentColumn.tasks.push(task);
      }
    }

    // Sprint header
    const sprintMatch = line.match(/^#\s+Sprint\s+(\d+)/);
    if (sprintMatch) {
      sprint = `sprint-${sprintMatch[1]}`;
    }
  }

  if (currentColumn) columns.push(currentColumn);

  // Ensure all columns exist
  const allStatuses: TaskStatus[] = [
    "TODO",
    "IN_PROGRESS",
    "IN_REVIEW",
    "QA",
    "DONE",
    "BLOCKED",
  ];
  for (const status of allStatuses) {
    if (!columns.find((c) => c.name === status)) {
      columns.push({ name: status, tasks: [], task_count: 0, point_sum: 0 });
    }
  }

  // Sort columns in canonical order
  columns.sort(
    (a, b) => allStatuses.indexOf(a.name) - allStatuses.indexOf(b.name)
  );

  return { columns, sprint, updated };
}
