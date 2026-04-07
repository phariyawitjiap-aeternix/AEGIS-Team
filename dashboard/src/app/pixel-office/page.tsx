"use client";

import dynamic from "next/dynamic";
import { Header } from "@/components/layout/Header";

const PixelOfficeCanvas = dynamic(
  () =>
    import("@/components/pixel-office/PixelOfficeCanvas").then(
      (mod) => mod.PixelOfficeCanvas
    ),
  { ssr: false, loading: () => <div className="p-6 text-[var(--text-secondary)]">Loading Pixel Office...</div> }
);

export default function PixelOfficePage() {
  return (
    <div>
      <Header title="Pixel Office" />
      <div className="p-6">
        <div className="text-sm text-[var(--text-secondary)] mb-4">
          Click on any agent sprite to see their current status and task.
          The Mother Brain orb in the meeting room pulses with the heartbeat.
        </div>
        <PixelOfficeCanvas />
      </div>
    </div>
  );
}
