import React from "react";
import { KeyCap } from "./KeyCap.jsx";

export const ARABIC_ROWS = [
  ["ا","ب","ت","ث","ج","ح","خ","د","ذ","ر","ز"],
  ["س","ش","ص","ض","ط","ظ","ع","غ","ف","ق","ك"],
  ["ل","م","ن","ه","و","ي","ة","ى","ء","أ","إ"]
];

export function Keyboard({ letterStates = {}, onKey, onEnter, onDelete, disabled = false }) {
  const wrapStyle = { display: "flex", flexDirection: "column", gap: "var(--key-gap)", width: "100%", direction: "rtl" };
  const rowStyle = { display: "flex", gap: "var(--key-gap)" };
  return (
    <div style={wrapStyle}>
      {ARABIC_ROWS.map((row, i) => (
        <div key={i} style={rowStyle}>
          {i === 2 && <KeyCap label="إدخال" wide disabled={disabled} onPress={() => onEnter && onEnter()} />}
          {row.map(l => (
            <KeyCap key={l} label={l} state={letterStates[l] || "idle"} disabled={disabled} onPress={onKey} />
          ))}
          {i === 2 && <KeyCap label="حذف" wide disabled={disabled} onPress={() => onDelete && onDelete()} />}
        </div>
      ))}
    </div>
  );
}
