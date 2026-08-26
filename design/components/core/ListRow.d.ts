import * as React from "react";

/** Hairline-separated row for the profile screen: an optional Lucide icon, a label, a trailing value, and a chevron when tappable. */
export interface ListRowProps {
  /** Lucide icon name. */
  icon?: string;
  label?: React.ReactNode;
  value?: React.ReactNode;
  onClick?: () => void;
  /** Taupe label, for sign-out and destructive rows. */
  danger?: boolean;
}
export function ListRow(props: ListRowProps): JSX.Element;
