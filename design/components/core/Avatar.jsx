import React from "react";

export function Avatar({ name = "", size = 44, tone = "accent" }) {
  const initial = (name || "؟").trim().charAt(0);
  const palette = tone === "accent"
    ? { background: "var(--accent)", color: "var(--text-on-accent)" }
    : { background: "var(--accent-soft)", color: "var(--text-on-soft)" };
  return (
    <div dir="rtl" aria-hidden="true" style={{
      width: size, height: size, flex: "0 0 auto",
      borderRadius: "var(--radius-pill)",
      display: "flex", alignItems: "center", justifyContent: "center",
      fontFamily: "var(--font-display)", fontWeight: "var(--weight-bold)",
      fontSize: Math.round(size * 0.42), lineHeight: 1, ...palette
    }}>{initial}</div>
  );
}
