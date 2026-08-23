import React from "react";

export function Toast({ message, tone = "neutral", visible = true }) {
  if (!visible) return null;
  const toastStyle = {
    display: "inline-block",
    padding: "10px 18px",
    borderRadius: "var(--radius-pill)",
    background: tone === "success" ? "var(--tile-correct-bg)" : "var(--surface-inverse)",
    color: "var(--text-inverse)",
    fontFamily: "var(--font-ui)", fontSize: "var(--text-xs)", fontWeight: "var(--weight-semibold)",
    boxShadow: "var(--shadow-md)", direction: "rtl",
    animation: "kalimat-rise var(--dur-fast) var(--ease-out)"
  };
  return <div role="status" style={toastStyle}>{message}</div>;
}
