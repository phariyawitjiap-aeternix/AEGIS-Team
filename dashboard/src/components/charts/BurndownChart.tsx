"use client";
import { useMetrics } from "@/hooks/useMetrics";

export function BurndownChart() {
  const { metrics, isLoading } = useMetrics();

  if (isLoading || !metrics) {
    return (
      <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-6 animate-pulse h-80" />
    );
  }

  const { committed_pts, completed_pts, daily_burndown, started, planned_end } =
    metrics;
  const remaining = committed_pts - completed_pts;

  // Calculate sprint days
  const startDate = new Date(started);
  const endDate = new Date(planned_end);
  const totalDays = Math.ceil(
    (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24)
  );
  const todayDay = Math.ceil(
    (Date.now() - startDate.getTime()) / (1000 * 60 * 60 * 24)
  );

  // SVG dimensions
  const W = 800;
  const H = 300;
  const PAD = { top: 20, right: 20, bottom: 40, left: 50 };
  const chartW = W - PAD.left - PAD.right;
  const chartH = H - PAD.top - PAD.bottom;

  // Scale functions
  const xScale = (day: number) =>
    PAD.left + (day / totalDays) * chartW;
  const yScale = (pts: number) =>
    PAD.top + chartH - (pts / committed_pts) * chartH;

  // Ideal burndown line
  const idealLine = `M${xScale(0)},${yScale(committed_pts)} L${xScale(totalDays)},${yScale(0)}`;

  // Actual burndown line (from daily_burndown data or estimate from current)
  let actualPath = "";
  if (daily_burndown && daily_burndown.length > 0) {
    actualPath = daily_burndown
      .map(
        (d, i) =>
          `${i === 0 ? "M" : "L"}${xScale(d.day)},${yScale(d.remaining)}`
      )
      .join(" ");
  } else {
    // Simple: start to current
    actualPath = `M${xScale(0)},${yScale(committed_pts)} L${xScale(Math.min(todayDay, totalDays))},${yScale(remaining)}`;
  }

  // Grid lines
  const yTicks = [0, Math.round(committed_pts / 4), Math.round(committed_pts / 2), Math.round((committed_pts * 3) / 4), committed_pts];
  const xTicks = Array.from({ length: totalDays + 1 }, (_, i) => i).filter(
    (d) => d % Math.max(1, Math.floor(totalDays / 7)) === 0 || d === totalDays
  );

  return (
    <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-surface)] p-6">
      <div className="text-xs text-[var(--text-secondary)] mb-4 uppercase tracking-wider">
        Sprint Burndown
      </div>
      <svg
        viewBox={`0 0 ${W} ${H}`}
        className="w-full h-auto"
        aria-label="Sprint burndown chart"
      >
        {/* Grid lines */}
        {yTicks.map((pts) => (
          <g key={`y-${pts}`}>
            <line
              x1={PAD.left}
              y1={yScale(pts)}
              x2={W - PAD.right}
              y2={yScale(pts)}
              stroke="var(--border)"
              strokeDasharray="4,4"
            />
            <text
              x={PAD.left - 8}
              y={yScale(pts) + 4}
              textAnchor="end"
              className="fill-[var(--text-secondary)]"
              fontSize={11}
            >
              {pts}
            </text>
          </g>
        ))}
        {xTicks.map((day) => (
          <text
            key={`x-${day}`}
            x={xScale(day)}
            y={H - 10}
            textAnchor="middle"
            className="fill-[var(--text-secondary)]"
            fontSize={11}
          >
            D{day}
          </text>
        ))}

        {/* Ideal line */}
        <path
          d={idealLine}
          fill="none"
          stroke="var(--text-secondary)"
          strokeWidth={1.5}
          strokeDasharray="6,4"
          opacity={0.5}
        />

        {/* Actual line */}
        <path
          d={actualPath}
          fill="none"
          stroke="var(--accent)"
          strokeWidth={2.5}
          strokeLinejoin="round"
        />

        {/* Today marker */}
        {todayDay <= totalDays && (
          <line
            x1={xScale(todayDay)}
            y1={PAD.top}
            x2={xScale(todayDay)}
            y2={H - PAD.bottom}
            stroke="var(--warning)"
            strokeWidth={1}
            strokeDasharray="4,4"
          />
        )}

        {/* Current point */}
        <circle
          cx={xScale(Math.min(todayDay, totalDays))}
          cy={yScale(remaining)}
          r={5}
          fill="var(--accent)"
          stroke="var(--bg-surface)"
          strokeWidth={2}
        />
      </svg>

      <div className="flex gap-6 mt-4 text-xs text-[var(--text-secondary)]">
        <span>Committed: {committed_pts} pts</span>
        <span>Completed: {completed_pts} pts</span>
        <span>Remaining: {remaining} pts</span>
      </div>
    </div>
  );
}
