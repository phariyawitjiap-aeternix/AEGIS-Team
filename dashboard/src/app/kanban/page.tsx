"use client";
import { Header } from "@/components/layout/Header";
import { KanbanBoard } from "@/components/kanban/KanbanBoard";

export default function KanbanPage() {
  return (
    <div>
      <Header title="Kanban Board" />
      <div className="p-6">
        <KanbanBoard />
      </div>
    </div>
  );
}
