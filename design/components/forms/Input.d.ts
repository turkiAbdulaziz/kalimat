import * as React from "react";

/**
 * Single-line text field, RTL, 52px tall.
 * @startingPoint section="Forms" subtitle="Labelled text field with hint and invalid state" viewport="700x150"
 */
export interface InputProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, "onChange" | "value"> {
  label?: React.ReactNode;
  /** Helper line under the field; turns taupe when invalid. */
  hint?: React.ReactNode;
  value?: string;
  onChange?: (next: string) => void;
  invalid?: boolean;
}
export function Input(props: InputProps): JSX.Element;
