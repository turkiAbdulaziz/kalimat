import * as React from "react";

/** Round monogram built from the first letter of the player's display name. No photo uploads exist in this product. */
export interface AvatarProps {
  name?: string;
  size?: number;
  tone?: "accent" | "soft";
}
export function Avatar(props: AvatarProps): JSX.Element;
