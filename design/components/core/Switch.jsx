import React from "react";

export function Switch({ checked = false, onChange, label, hint }) {
  const trackStyle = { width: 46, height: 28, flex: "0 0 auto", borderRadius: "var(--radius-pill)", background: checked ? "var(--accent)" : "var(--taupe-300)", position: "relative", cursor: "pointer", transition: "background var(--dur-base) var(--ease-out)", border: "none" };
  const knobStyle = { position: "absolute", top: 3, right: checked ? 21 : 3, width: 22, height: 22, borderRadius: "var(--radius-pill)", background: "var(--brown-0)", boxShadow: "var(--shadow-sm)", transition: "right var(--dur-base) var(--ease-out)" };
  return (
    <div dir="rtl" style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: "var(--space-4)", fontFamily: "var(--font-ui)", padding: "var(--space-3) 0", borderBottom: "1px solid var(--line-soft)" }}>
      <div>
        <div style={{ fontSize: "var(--text-sm)", fontWeight: "var(--weight-medium)", color: "var(--text-body)" }}>{label}</div>
        {hint && <div style={{ fontSize: "var(--text-2xs)", color: "var(--text-subtle)", marginTop: 2 }}>{hint}</div>}
      </div>
      <button role="switch" aria-checked={checked} aria-label={label} style={trackStyle} onClick={() => onChange && onChange(!checked)}>
        <span style={knobStyle}></span>
      </button>
    </div>
  );
}
