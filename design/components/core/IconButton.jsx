import React from "react";

export function IconButton({ icon = "settings", label, size = 40, onClick, style, ...rest }) {
  const [hover, setHover] = React.useState(false);
  const ref = React.useRef(null);
  React.useEffect(() => { if (window.lucide) window.lucide.createIcons({ nameAttr: "data-lucide" }); });
  const iconBtnStyle = {
    width: size, height: size,
    display: "inline-flex", alignItems: "center", justifyContent: "center",
    border: "none", borderRadius: "var(--radius-pill)",
    background: hover ? "var(--surface-sunken)" : "transparent",
    color: "var(--text-muted)", cursor: "pointer",
    transition: "background var(--dur-fast) var(--ease-out)",
    ...style
  };
  return (
    <button type="button" aria-label={label || icon} ref={ref} onClick={onClick} style={iconBtnStyle}
      onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)} {...rest}>
      <i data-lucide={icon} style={{ width: 20, height: 20 }}></i>
    </button>
  );
}
