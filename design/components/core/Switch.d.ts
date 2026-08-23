import * as React from "react";

/** Settings row with a toggle on the leading (left, in RTL) edge. */
export interface SwitchProps {
  checked?: boolean;
  onChange?: (next: boolean) => void;
  label?: React.ReactNode;
  hint?: React.ReactNode;
}
export function Switch(props: SwitchProps): JSX.Element;
