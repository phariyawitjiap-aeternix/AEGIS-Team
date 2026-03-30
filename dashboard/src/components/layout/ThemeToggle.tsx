"use client";
import { useTheme } from "@/hooks/useTheme";

export function ThemeToggle() {
  const { theme, toggle } = useTheme();

  return (
    <button
      onClick={toggle}
      className="px-3 py-1.5 rounded-lg border border-[var(--border)] bg-[var(--bg-surface)] text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors"
      aria-label={`Switch to ${theme === "dark" ? "light" : "dark"} theme`}
    >
      {theme === "dark" ? "Light" : "Dark"}
    </button>
  );
}
