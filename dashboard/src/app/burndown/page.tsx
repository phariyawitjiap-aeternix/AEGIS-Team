import { Header } from "@/components/layout/Header";
import { BurndownChart } from "@/components/charts/BurndownChart";

export default function BurndownPage() {
  return (
    <div>
      <Header title="Sprint Burndown" />
      <div className="p-6">
        <BurndownChart />
      </div>
    </div>
  );
}
