import React from "react";
import { IconButton } from "./IconButton.jsx";

export function Dialog({ open = true, title, onClose, footer, children, width = 380 }) {
  if (!open) return null;
  const overlayStyle = { position: "fixed", inset: 0, background: "var(--surface-overlay)", backdropFilter: "blur(2px)", display: "flex", alignItems: "center", justifyContent: "center", padding: "var(--space-4)", zIndex: 40 };
  const panelStyle = { width: "100%", maxWidth: width, background: "var(--surface-card)", borderRadius: "var(--radius-card)", border: "1px solid var(--line-soft)", boxShadow: "var(--shadow-lg)", padding: "var(--space-6)", direction: "rtl", fontFamily: "var(--font-ui)", color: "var(--text-body)", animation: "kalimat-rise var(--dur-base) var(--ease-out)" };
  const headStyle = { display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "var(--space-4)" };
  return (
    <div style={overlayStyle} onClick={onClose}>
      <div style={panelStyle} onClick={e => e.stopPropagation()}>
        <div style={headStyle}>
          <h2 style={{ margin: 0, fontFamily: "var(--font-display)", fontSize: "var(--text-lg)", fontWeight: "var(--weight-bold)" }}>{title}</h2>
          {onClose && <IconButton icon="x" label="إغلاق" onClick={onClose} />}
        </div>
        <div style={{ fontSize: "var(--text-sm)", lineHeight: "var(--leading-body)", color: "var(--text-muted)" }}>{children}</div>
        {footer && <div style={{ marginTop: "var(--space-6)" }}>{footer}</div>}
      </div>
    </div>
  );
}
