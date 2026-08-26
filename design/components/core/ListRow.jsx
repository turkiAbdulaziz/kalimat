import React from "react";

export function ListRow({ icon, label, value, onClick, danger = false }) {
  const [hover, setHover] = React.useState(false);
  React.useEffect(() => { if (window.lucide) window.lucide.createIcons({ nameAttr: "data-lucide" }); });
  const rowStyle = {
    display: "flex", alignItems: "center", gap: "var(--space-3)",
    width: "100%", boxSizing: "border-box",
    padding: "var(--space-3) var(--space-2)",
    background: hover && onClick ? "var(--surface-sunken)" : "transparent",
    border: "none", borderBottom: "1px solid var(--line-soft)",
    borderRadius: "var(--radius-md)",
    fontFamily: "var(--font-ui)", fontSize: "var(--text-sm)",
    color: danger ? "var(--text-danger)" : "var(--text-body)",
    cursor: onClick ? "pointer" : "default", textAlign: "start",
    transition: "background var(--dur-fast) var(--ease-out)"
  };
  return (
    <button type="button" dir="rtl" style={rowStyle} onClick={onClick}
      onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}>
      {icon && <i data-lucide={icon} style={{ width: 18, height: 18, color: "var(--text-subtle)" }}></i>}
      <span style={{ flex: 1 }}>{label}</span>
      {value && <span style={{ color: "var(--text-subtle)", fontSize: "var(--text-xs)" }}>{value}</span>}
      {onClick && <i data-lucide="chevron-left" style={{ width: 16, height: 16, color: "var(--text-subtle)" }}></i>}
    </button>
  );
}
