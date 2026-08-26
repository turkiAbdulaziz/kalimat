import React from "react";
import { Tile } from "../game/Tile.jsx";

export function CodeInput({ length = 4, value = "", onChange, size = 52 }) {
  const ref = React.useRef(null);
  const cells = [];
  for (let i = 0; i < length; i++) {
    const ch = value[i] || "";
    cells.push(<Tile key={i} letter={ch} state={ch ? "filled" : "empty"} size={size} animate={!!ch && i === value.length - 1} />);
  }
  const onType = (e) => {
    const digits = e.target.value.replace(/[^0-9\u0660-\u0669]/g, "").slice(0, length);
    onChange && onChange(digits);
  };
  return (
    <div dir="rtl" style={{ position: "relative", display: "flex", gap: "var(--tile-gap)", justifyContent: "center", cursor: "text" }}
      onClick={() => ref.current && ref.current.focus()}>
      {cells}
      <input ref={ref} value={value} onChange={onType} inputMode="numeric" aria-label="رمز الدخول"
        style={{ position: "absolute", inset: 0, opacity: 0, border: "none", background: "transparent", font: "inherit" }} />
    </div>
  );
}
