import * as React from "react";

/** Centred modal sheet used for help, stats and settings. */
export interface DialogProps {
  open?: boolean;
  title?: React.ReactNode;
  onClose?: () => void;
  footer?: React.ReactNode;
  children?: React.ReactNode;
  width?: number;
}
export function Dialog(props: DialogProps): JSX.Element | null;
