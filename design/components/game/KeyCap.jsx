import React from "react";

const KEYCAP_STATE_BG = {
  idle: "var(--key-bg)",
  correct: "var(--tile-correct-bg)",
  present: "var(--tile-present-bg)",
  absent: "var(--tile-absent-bg)"
};

const KEYCAP_STATE_FG = {
  idle: "var(--key-text)",
  correct: "var(--tile-text-correct)",
  present: "var(--tile-text-present)",
  absent: "var(--tile-text-absent)"
};

export function KeyCap({ label, state = "idle", wide = false, onPress, disabled = false, children }) {
  const [held, setHeld] = React.useState(false);
  const isStated = state !== "idle";
  const capStyle = {
    minWidth: wide ? 62 : 30,
    flex: wide ? "0 0 auto" : "1 1 0",
    height: "var(--key-height)",
    display: "flex", alignItems: "center", justifyContent: "center",
    gap: 4,
    padding: wide ? "0 10px" : 0,
    border: "none",
    borderRadius: "var(--radius-key)",
    background: wide && !isStated ? "var(--key-wide-bg)" : KEYCAP_STATE_BG[state],
    color: KEYCAP_STATE_FG[state],
    fontFamily: "var(--font-ui)",
    fontSize: wide ? "var(--text-xs)" : "var(--text-lg)",
    fontWeight: "var(--weight-semibold)",
    cursor: disabled ? "default" : "pointer",
    opacity: disabled ? .5 : 1,
    transform: held ? "scale(.94)" : "scale(1)",
    transition: "background var(--dur-fast) var(--ease-out), transform var(--dur-instant) var(--ease-out)",
    boxShadow: "var(--shadow-inset)"
  };
  return (
    <button type="button" dir="rtl" disabled={disabled} style={capStyle}
      onMouseDown={() => setHeld(true)} onMouseUp={() => setHeld(false)} onMouseLeave={() => setHeld(false)}
      onClick={() => !disabled && onPress && onPress(label)}>
      {children || label}
    </button>
  );
}
