"use client";
import Link from "next/link";
import { ThemeToggle } from "./ThemeToggle";

export function Header({ title }: { title?: string }) {
  return (
    <header className="h-14 border-b border-[var(--border)] bg-[var(--bg-elevated)] flex items-center justify-between px-6 sticky top-0 z-10">
      <div className="flex items-center gap-3">
        {title && (
          <h1 className="text-lg font-semibold text-[var(--text-primary)]">
            {title}
          </h1>
        )}
      </div>
      <div className="flex items-center gap-3">
        <Link
          href="/pixel-office"
          className="px-3 py-1.5 rounded-lg bg-[var(--accent)]/10 text-[var(--accent)] text-sm hover:bg-[var(--accent)]/20 transition-colors"
        >
          Pixel Office
        </Link>
        <ThemeToggle />
      </div>
    </header>
  );
}
