import * as React from "react";

/**
 * Pill action button, RTL by default.
 * @startingPoint section="Core" subtitle="Button variants and sizes" viewport="700x150"
 */
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "ghost" | "inverse";
  size?: "sm" | "md" | "lg";
  /** Full-width — the default inside dialogs on mobile. */
  block?: boolean;
}
export function Button(props: ButtonProps): JSX.Element;
