import * as React from "react";

export interface GuessCell {
  letter?: string;
  state?: "empty" | "filled" | "correct" | "present" | "absent";
}

/**
 * The full board: maxGuesses rows of wordLength tiles, laid out right-to-left.
 * @startingPoint section="Game" subtitle="Six-row Arabic guess board" viewport="700x400"
 */
export interface GuessGridProps {
  /** Rows of cells, oldest first. Short/absent rows render empty. */
  rows?: GuessCell[][];
  wordLength?: number;
  maxGuesses?: number;
  /** Index of a row to shake (invalid word). */
  shakeRow?: number;
  /** Index of a row to flip-reveal. */
  revealRow?: number;
  tileSize?: string | number;
}
export function GuessGrid(props: GuessGridProps): JSX.Element;
