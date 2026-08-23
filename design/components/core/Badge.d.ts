import * as React from "react";

/** Small pill label: puzzle number, streak flag, "جديد". */
export interface BadgeProps {
  tone?: "neutral" | "accent" | "solid";
  children?: React.ReactNode;
}
export function Badge(props: BadgeProps): JSX.Element;
