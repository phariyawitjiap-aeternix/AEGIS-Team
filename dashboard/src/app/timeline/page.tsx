import { Header } from "@/components/layout/Header";
import { ActivityFeed } from "@/components/timeline/ActivityFeed";

export default function TimelinePage() {
  return (
    <div>
      <Header title="Activity Timeline" />
      <div className="p-6">
        <ActivityFeed />
      </div>
    </div>
  );
}
