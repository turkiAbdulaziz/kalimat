import * as React from "react";

/** Transient pill message above the board ("الكلمة غير موجودة", "أحسنت!"). */
export interface ToastProps {
  message: React.ReactNode;
  tone?: "neutral" | "success";
  visible?: boolean;
}
export function Toast(props: ToastProps): JSX.Element | null;
