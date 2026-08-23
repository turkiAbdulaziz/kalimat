import React from "react";

const BUTTON_VARIANTS = {
  primary: { background: "var(--accent)", color: "var(--text-on-accent)", border: "1px solid var(--accent)" },
  secondary: { background: "var(--surface-card)", color: "var(--text-body)", border: "1px solid var(--line)" },
  ghost: { background: "transparent", color: "var(--text-muted)", border: "1px solid transparent" },
  inverse: { background: "var(--brown-100)", color: "var(--brown-900)", border: "1px solid var(--brown-100)" }
};
const BUTTON_SIZES = {
  sm: { height: 36, padding: "0 14px", fontSize: "var(--text-xs)" },
  md: { height: 44, padding: "0 20px", fontSize: "var(--text-sm)" },
  lg: { height: 52, padding: "0 28px", fontSize: "var(--text-md)" }
};

export function Button({ variant = "primary", size = "md", block = false, disabled = false, children, style, ...rest }) {
  const [hover, setHover] = React.useState(false);
  const [press, setPress] = React.useState(false);
  const v = BUTTON_VARIANTS[variant] || BUTTON_VARIANTS.primary;
  const btnStyle = {
    ...v, ...BUTTON_SIZES[size],
    width: block ? "100%" : "auto",
    display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
    borderRadius: "var(--radius-pill)",
    fontFamily: "var(--font-ui)",
    fontWeight: "var(--weight-semibold)",
    cursor: disabled ? "not-allowed" : "pointer",
    opacity: disabled ? .45 : 1,
    transform: press && !disabled ? "scale(.97)" : "scale(1)",
    filter: hover && !disabled && variant === "primary" ? "brightness(.93)" : "none",
    background: hover && !disabled && (variant === "secondary" || variant === "ghost") ? "var(--surface-sunken)" : v.background,
    transition: "background var(--dur-fast) var(--ease-out), transform var(--dur-instant) var(--ease-out), filter var(--dur-fast) var(--ease-out)",
    ...style
  };
  return (
    <button type="button" dir="rtl" disabled={disabled} style={btnStyle}
      onMouseEnter={() => setHover(true)} onMouseLeave={() => { setHover(false); setPress(false); }}
      onMouseDown={() => setPress(true)} onMouseUp={() => setPress(false)} {...rest}>{children}</button>
  );
}
