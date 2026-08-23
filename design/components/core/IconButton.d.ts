import * as React from "react";

/** Bare 40px round icon button for header affordances (help, stats, settings, share). */
export interface IconButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  /** Lucide icon name, e.g. "circle-help", "bar-chart-3", "settings", "share-2". */
  icon?: string;
  /** Accessible Arabic label. */
  label?: string;
  size?: number;
}
export function IconButton(props: IconButtonProps): JSX.Element;
