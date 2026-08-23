import * as React from "react";

/** One number in the stats row (played, win %, streak, best streak). */
export interface StatCardProps {
  value: React.ReactNode;
  label: React.ReactNode;
  /** Brown accent number — use for the single headline stat. */
  emphasis?: boolean;
}
export function StatCard(props: StatCardProps): JSX.Element;
