import { Header } from "@/components/layout/Header";
import { PixelOfficeCanvas } from "@/components/pixel-office/PixelOfficeCanvas";

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
