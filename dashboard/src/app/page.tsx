import { Header } from "@/components/layout/Header";
import { HeartbeatIndicator } from "@/components/dashboard/HeartbeatIndicator";
import { SprintSummaryCard } from "@/components/dashboard/SprintSummaryCard";
import { QuickStats } from "@/components/dashboard/QuickStats";
import { AgentGrid } from "@/components/dashboard/AgentGrid";

export default function HomePage() {
  return (
    <div>
      <Header title="Dashboard Home" />
      <div className="p-6 space-y-6">
        {/* Top row: Heartbeat + Sprint Summary */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <HeartbeatIndicator />
          <div className="lg:col-span-2">
            <SprintSummaryCard />
          </div>
        </div>

        {/* Quick Stats */}
        <QuickStats />

        {/* Agent Grid */}
        <AgentGrid />
      </div>
    </div>
  );
}
