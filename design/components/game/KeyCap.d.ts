import * as React from "react";

/** One key of the Arabic on-screen keyboard. */
export interface KeyCapProps {
  /** Arabic letter, or an action name like "إدخال" / "حذف". */
  label: string;
  /** Colours the cap with the best result seen for that letter. */
  state?: "idle" | "correct" | "present" | "absent";
  /** Action keys are wider and use the smaller UI size. */
  wide?: boolean;
  disabled?: boolean;
  onPress?: (label: string) => void;
  children?: React.ReactNode;
}
export function KeyCap(props: KeyCapProps): JSX.Element;
