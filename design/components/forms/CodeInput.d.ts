import * as React from "react";

/**
 * One-time-code entry rendered as game tiles — the brand's signature sign-in moment.
 * @startingPoint section="Forms" subtitle="Tile-based one-time code entry" viewport="700x150"
 */
export interface CodeInputProps {
  length?: number;
  value?: string;
  onChange?: (next: string) => void;
  size?: string | number;
}
export function CodeInput(props: CodeInputProps): JSX.Element;
