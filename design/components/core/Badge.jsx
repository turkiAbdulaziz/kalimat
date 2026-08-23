import React from "react";

const BADGE_TONES = {
  neutral: { background: "var(--surface-sunken)", color: "var(--text-muted)" },
  accent: { background: "var(--accent-soft)", color: "var(--brown-800)" },
  solid: { background: "var(--accent)", color: "var(--text-on-accent)" }
};

export function Badge({ tone = "neutral", children }) {
  return <span dir="rtl" style={{ ...BADGE_TONES[tone], display: "inline-block", padding: "3px 10px", borderRadius: "var(--radius-pill)", fontFamily: "var(--font-ui)", fontSize: "var(--text-2xs)", fontWeight: "var(--weight-semibold)" }}>{children}</span>;
}
