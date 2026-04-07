"use client";
import { Header } from "@/components/layout/Header";
import { GatePipeline } from "@/components/gates/GatePipeline";

export default function GatesPage() {
  return (
    <div>
      <Header title="Quality Gates" />
      <div className="p-6">
        <GatePipeline />
      </div>
    </div>
  );
}
