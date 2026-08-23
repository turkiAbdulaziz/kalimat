import * as React from "react";

/**
 * A single letter cell of the كلمات board.
 * @startingPoint section="Game" subtitle="Letter tile in all five states" viewport="700x150"
 */
export interface TileProps extends React.HTMLAttributes<HTMLDivElement> {
  /** Single Arabic letter to display. Empty string renders a blank tile. */
  letter?: string;
  /** Evaluation state. */
  state?: "empty" | "filled" | "correct" | "present" | "absent";
  /** Override the tile edge length (defaults to var(--tile-size)). */
  size?: string | number;
  /** Play the pop (typing) or flip (reveal) animation. */
  animate?: boolean;
  /** Stagger in ms, used to cascade a row reveal. */
  revealDelay?: number;
}
export function Tile(props: TileProps): JSX.Element;
