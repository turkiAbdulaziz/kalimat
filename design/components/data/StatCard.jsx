import React from "react";

export function StatCard({ value, label, emphasis = false }) {
  return (
    <div dir="rtl" style={{ textAlign: "center", minWidth: 64, fontFamily: "var(--font-ui)" }}>
      <div style={{ fontFamily: "var(--font-display)", fontSize: "var(--text-2xl)", fontWeight: "var(--weight-bold)", color: emphasis ? "var(--accent)" : "var(--text-body)", lineHeight: 1 }}>{value}</div>
      <div style={{ fontSize: "var(--text-2xs)", color: "var(--text-subtle)", marginTop: 6, lineHeight: "var(--leading-snug)" }}>{label}</div>
    </div>
  );
}
