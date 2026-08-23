import * as React from "react";

/**
 * The Arabic on-screen keyboard: three alphabetical rows plus إدخال / حذف.
 * @startingPoint section="Game" subtitle="Arabic keyboard with letter states" viewport="700x220"
 */
export interface KeyboardProps {
  /** Map of letter -> best known state, e.g. { "ك": "correct" }. */
  letterStates?: Record<string, "idle" | "correct" | "present" | "absent">;
  onKey?: (letter: string) => void;
  onEnter?: () => void;
  onDelete?: () => void;
  disabled?: boolean;
}
export function Keyboard(props: KeyboardProps): JSX.Element;
export const ARABIC_ROWS: string[][];
