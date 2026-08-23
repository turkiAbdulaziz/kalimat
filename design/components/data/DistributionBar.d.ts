import * as React from "react";

/** One row of the guess-distribution chart. */
export interface DistributionBarProps {
  /** Guess number label (1–6). */
  guess: React.ReactNode;
  /** Western digits are converted to Arabic-Indic for display. */
  count?: number;
  /** Largest count in the set, used to scale the bar. */
  max?: number;
  /** Dark-brown fill marking today's result. */
  highlight?: boolean;
}
export function DistributionBar(props: DistributionBarProps): JSX.Element;
