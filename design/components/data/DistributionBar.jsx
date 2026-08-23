import React from "react";

const ARABIC_INDIC = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"];
const toArabicDigits = (v) => String(v).replace(/[0-9]/g, d => ARABIC_INDIC[Number(d)]);

export function DistributionBar({ guess, count = 0, max = 1, highlight = false }) {
  const pct = Math.max(6, Math.round((count / (max || 1)) * 100));
  return (
    <div dir="rtl" style={{ display: "flex", alignItems: "center", gap: "var(--space-2)", fontFamily: "var(--font-ui)", fontSize: "var(--text-xs)" }}>
      <span style={{ width: 14, color: "var(--text-muted)", fontWeight: "var(--weight-medium)" }}>{toArabicDigits(guess)}</span>
      <div style={{ flex: 1, height: 22, background: "var(--surface-sunken)", borderRadius: "var(--radius-sm)", overflow: "hidden" }}>
        <div style={{ width: pct + "%", height: "100%", background: highlight ? "var(--tile-correct-bg)" : "var(--tile-absent-bg)", color: "var(--text-inverse)", display: "flex", alignItems: "center", justifyContent: "flex-start", paddingInlineStart: 8, boxSizing: "border-box", borderRadius: "var(--radius-sm)", transition: "width var(--dur-slow) var(--ease-out)", fontWeight: "var(--weight-semibold)" }}>{toArabicDigits(count)}</div>
      </div>
    </div>
  );
}
