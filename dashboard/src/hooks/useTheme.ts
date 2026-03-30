"use client";
import { useState, useEffect, useCallback } from "react";

export function useTheme() {
  const [theme, setThemeState] = useState<"dark" | "light">("dark");

  useEffect(() => {
    const stored = localStorage.getItem("aegis-theme");
    if (stored === "light" || stored === "dark") {
      setThemeState(stored);
      document.documentElement.classList.toggle("dark", stored === "dark");
    } else {
      document.documentElement.classList.add("dark");
    }
  }, []);

  const setTheme = useCallback((t: "dark" | "light") => {
    setThemeState(t);
    localStorage.setItem("aegis-theme", t);
    document.documentElement.classList.toggle("dark", t === "dark");
  }, []);

  const toggle = useCallback(() => {
    setTheme(theme === "dark" ? "light" : "dark");
  }, [theme, setTheme]);

  return { theme, setTheme, toggle };
}
