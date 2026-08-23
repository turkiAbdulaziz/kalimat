import React from "react";
import { Tile } from "./Tile.jsx";

export function GuessGrid({ rows = [], wordLength = 5, maxGuesses = 6, shakeRow = -1, revealRow = -1, tileSize }) {
  const gridStyle = { display: "grid", gap: "var(--grid-gap)", justifyContent: "center", direction: "rtl" };
  const rowStyle = { display: "grid", gridTemplateColumns: "repeat(" + wordLength + ", auto)", gap: "var(--tile-gap)" };
  const all = [];
  for (let r = 0; r < maxGuesses; r++) {
    const row = rows[r] || [];
    const cells = [];
    for (let c = 0; c < wordLength; c++) {
      const cell = row[c] || {};
      cells.push(
        <Tile key={c} letter={cell.letter || ""} state={cell.state || (cell.letter ? "filled" : "empty")}
              size={tileSize} animate={r === revealRow} revealDelay={r === revealRow ? c * 120 : 0} />
      );
    }
    all.push(
      <div key={r} style={{ ...rowStyle, animation: r === shakeRow ? "kalimat-shake var(--dur-slow) var(--ease-in-out)" : "none" }}>
        {cells}
      </div>
    );
  }
  return <div style={gridStyle}>{all}</div>;
}
