import React from "react";

const TILE_STATE_STYLES = {
  empty:   { background: "var(--tile-empty-bg)", borderColor: "var(--tile-empty-border)", color: "var(--text-body)" },
  filled:  { background: "var(--tile-empty-bg)", borderColor: "var(--tile-filled-border)", color: "var(--text-body)" },
  correct: { background: "var(--tile-correct-bg)", borderColor: "var(--tile-correct-border)", color: "var(--tile-text-on-state)" },
  present: { background: "var(--tile-present-bg)", borderColor: "var(--tile-present-border)", color: "var(--tile-text-on-state)" },
  absent:  { background: "var(--tile-absent-bg)", borderColor: "var(--tile-absent-border)", color: "var(--tile-text-on-state)" }
};

export function Tile({ letter = "", state = "empty", size, animate = false, revealDelay = 0, style, ...rest }) {
  const dim = size || "var(--tile-size)";
  const tileStyle = {
    width: dim, height: dim,
    display: "flex", alignItems: "center", justifyContent: "center",
    boxSizing: "border-box",
    border: "2px solid",
    borderRadius: "var(--radius-tile)",
    fontFamily: "var(--font-display)",
    fontSize: "var(--text-tile)",
    fontWeight: "var(--weight-bold)",
    lineHeight: 1,
    userSelect: "none",
    transition: "background var(--dur-fast) var(--ease-out), border-color var(--dur-fast) var(--ease-out)",
    animation: animate
      ? (state === "empty" || state === "filled"
          ? "kalimat-pop var(--dur-base) var(--ease-pop) " + revealDelay + "ms both"
          : "kalimat-flip var(--dur-slow) var(--ease-in-out) " + revealDelay + "ms both")
      : "none",
    ...TILE_STATE_STYLES[state],
    ...style
  };
  return <div dir="rtl" aria-label={letter || "فارغ"} style={tileStyle} {...rest}>{letter}</div>;
}
