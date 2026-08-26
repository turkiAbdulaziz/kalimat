import React from "react";

export function Input({ label, hint, value = "", onChange, placeholder, type = "text", invalid = false, id, ...rest }) {
  const [focus, setFocus] = React.useState(false);
  const fieldId = id || "in-" + (label || type);
  const inputStyle = {
    width: "100%", height: 52, boxSizing: "border-box",
    padding: "0 var(--space-4)",
    background: "var(--surface-card)",
    border: "1px solid " + (invalid ? "var(--text-danger)" : focus ? "var(--accent)" : "var(--line)"),
    borderRadius: "var(--radius-lg)",
    boxShadow: focus ? "var(--focus-ring)" : "none",
    fontFamily: "var(--font-ui)", fontSize: "var(--text-md)", color: "var(--text-body)",
    outline: "none",
    transition: "border-color var(--dur-fast) var(--ease-out), box-shadow var(--dur-fast) var(--ease-out)"
  };
  return (
    <div dir="rtl" style={{ display: "grid", gap: "var(--space-2)", width: "100%" }}>
      {label && <label htmlFor={fieldId} style={{ fontFamily: "var(--font-ui)", fontSize: "var(--text-xs)", fontWeight: "var(--weight-medium)", color: "var(--text-muted)" }}>{label}</label>}
      <input id={fieldId} type={type} value={value} placeholder={placeholder} style={inputStyle}
        onChange={e => onChange && onChange(e.target.value)}
        onFocus={() => setFocus(true)} onBlur={() => setFocus(false)} {...rest} />
      {hint && <div style={{ fontFamily: "var(--font-ui)", fontSize: "var(--text-2xs)", color: invalid ? "var(--text-danger)" : "var(--text-subtle)" }}>{hint}</div>}
    </div>
  );
}
