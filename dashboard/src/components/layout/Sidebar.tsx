"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV_ITEMS = [
  { href: "/", label: "Home", icon: "H" },
  { href: "/kanban", label: "Kanban", icon: "K" },
  { href: "/burndown", label: "Burndown", icon: "B" },
  { href: "/timeline", label: "Timeline", icon: "T" },
  { href: "/agents", label: "Agents", icon: "A" },
  { href: "/gates", label: "Gates", icon: "G" },
  { href: "/pixel-office", label: "Pixel Office", icon: "P" },
  { href: "/specs", label: "Specs", icon: "S" },
  { href: "/context", label: "Context", icon: "C" },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-56 shrink-0 border-r border-[var(--border)] bg-[var(--bg-elevated)] flex flex-col h-screen sticky top-0">
      <div className="p-4 border-b border-[var(--border)]">
        <Link href="/" className="flex items-center gap-2">
          <span className="text-xl font-bold text-[var(--accent)]">AEGIS</span>
          <span className="text-xs text-[var(--text-secondary)]">Dashboard</span>
        </Link>
      </div>
      <nav className="flex-1 py-2 overflow-y-auto">
        {NAV_ITEMS.map((item) => {
          const isActive =
            item.href === "/"
              ? pathname === "/"
              : pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-2.5 text-sm transition-colors ${
                isActive
                  ? "bg-[var(--accent)]/10 text-[var(--accent)] border-r-2 border-[var(--accent)]"
                  : "text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--bg-surface)]"
              }`}
            >
              <span className="w-6 h-6 rounded bg-[var(--bg-surface)] flex items-center justify-center text-xs font-mono">
                {item.icon}
              </span>
              {item.label}
            </Link>
          );
        })}
      </nav>
      <div className="p-3 border-t border-[var(--border)] text-xs text-[var(--text-secondary)]">
        AEGIS v8.3
      </div>
    </aside>
  );
}
