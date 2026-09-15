# Letter-state color consistency audit

Date: 2026-09-15

Implementation status: fixed on 2026-09-15. The findings below describe the
pre-fix behavior and the plan used for the correction.

## Verdict

Confirmed. The app renders each state consistently between the board and keyboard
inside a single theme, but the visual meaning of `correct` and `present` reverses
between light and dark mode.

Severity: medium. Gameplay remains functionally correct, but a player who changes
themes must relearn the two brown state colors. This conflicts with the design rule
that game state is communicated by value and that darker brown means `correct`.

## Evidence

### Current mappings

| State | Light | Dark | Cross-theme effect |
|---|---|---|---|
| Correct / في مكانه | brown-700 `#6B4F3A` | brown-500 `#A97F55` | Becomes substantially lighter |
| Present / موجود | brown-400 `#C69C6D` | brown-700 `#6B4F3A` | Becomes substantially darker |
| Absent / غير موجود | taupe-500 `#988D83` | taupe-600 `#7C7168` | Becomes moderately darker |

In light mode, `correct` is the darkest brown and `present` is the light tan. In
dark mode, `present` becomes the darkest brown and `correct` becomes the light tan.
The two meanings therefore exchange their visual roles.

The mismatch is visible in the identical duel fixtures in
`store/screenshots/07-duel.png` and `store/screenshots/08-duel-dark.png`.

### Source trace

- `lib/core/theme/kalimat_colors.dart` declares the intended rule as “dark =
  correct”, then maps light `correct/present` to brown-700/brown-400 and dark
  `correct/present` to brown-500/brown-700.
- `design/tokens/colors.css` contains the same cross-theme remap, so Flutter matches
  the current design tokens exactly. The problem is in the token decision, not a
  Flutter-only implementation error.
- `lib/game/widgets/tile.dart` consumes `tileCorrect`, `tilePresent`, and
  `tileAbsent` directly.
- `lib/game/widgets/key_cap.dart` consumes those same tokens directly. Board tiles
  and keyboard hints therefore agree within each theme.
- Git history shows the dark remap was introduced in commit `5022be0` as part of the
  “official dark color mapping”. Before that commit, game-state colors were unchanged
  between themes.

## Contrast check

All evaluated letters currently use `#FFFDFA` text.

| Theme/state | Text contrast |
|---|---:|
| Light correct | 7.37:1 |
| Light present | 2.47:1 |
| Light absent | 3.20:1 |
| Dark correct | 3.53:1 |
| Dark present | 7.37:1 |
| Dark absent | 4.68:1 |

The light `present` combination is below the 3:1 threshold normally expected for
large text. The three state fills are also close to one another in places, especially
light `present` versus `absent` (1.29:1) and dark `correct` versus `absent` (1.32:1).
Because color/value is the only visible state cue, the fix should consider state
distinguishability as well as theme consistency.

## Test gap

The focused widget tests pass, but they do not protect the intended cross-theme
semantics:

- `test/widget/tile_state_test.dart` mounts only the light theme.
- `test/widget/keyboard_layout_test.dart` verifies canonical Arabic letters share a
  state, but it does not assert rendered key colors.
- `test/widget/four_letter_boards_test.dart` exercises both themes for layout and
  exceptions, not palette values or semantic ordering.

Focused baseline run on 2026-09-15:

```text
flutter test test/widget/tile_state_test.dart test/widget/keyboard_layout_test.dart
12 tests passed
```

## Recommended direction

Treat gameplay result colors as stable semantic identity colors, not adaptive
surface colors:

1. Keep the same `correct`, `present`, and `absent` fills in light and dark mode.
2. Preserve the hierarchy “correct is the darkest brown, present is the lighter
   brown, absent is taupe” in every theme.
3. Give each state its own foreground token if needed to meet contrast; one shared
   white foreground cannot make the current light palette fully compliant.
4. Keep board tiles and keyboard hints on the same state palette.

A strong starting candidate is to retain the established light-mode fills in both
themes: correct brown-700, present brown-400, absent taupe-500. Pair correct with
brown-0 text and evaluate dark text for the lighter `present` and `absent` fills.
Final foreground values should be chosen from rendered comparison frames, not from
hex values alone.

## Fix plan

1. **Approve the invariant** — lock the cross-theme rule that a result state keeps
   one visual identity and that `correct` remains darker than `present`.
2. **Prototype the state swatches** — compare the stable-fill candidate in light and
   dark surfaces, including board-size and keyboard-size Arabic letters; select
   per-state foregrounds that meet at least 3:1 and remain visually balanced.
3. **Update the source tokens** — change `design/tokens/colors.css` first, including
   any new per-state text tokens, and update the color guidance cards.
4. **Mirror tokens in Flutter** — update `KalimatColors.light/dark`, then wire the
   selected foreground for each state through both `Tile` and `KeyCap`.
5. **Add regression coverage** — parameterize tile tests across both brightnesses;
   assert all three board and keyboard state colors, semantic ordering, board/key
   equality, and minimum text contrast.
6. **Run focused and full checks** — run the state widget tests, all Flutter tests,
   `flutter analyze`, and deterministic word-list verification.
7. **Regenerate visual fixtures** — recapture the affected light/dark App Store and
   integration screenshots, then compare identical game states side by side before
   release.

## Expected files in the fix

- `design/tokens/colors.css`
- `design/guidelines/colors-game-states.card.html`
- `design/guidelines/colors-dark.card.html`
- `lib/core/theme/kalimat_colors.dart`
- `lib/game/widgets/tile.dart`
- `lib/game/widgets/key_cap.dart`
- `test/widget/tile_state_test.dart`
- `test/widget/keyboard_layout_test.dart`
- affected screenshot fixtures under `store/screenshots/`

## Implemented resolution

- Stable fills in both themes: correct brown-700, present brown-400, absent taupe-500.
- Foregrounds: correct brown-0, present brown-900, absent brown-900.
- Resulting text contrast: correct 7.37:1, present 6.21:1, absent 4.80:1.
- Board tiles, keyboard hints, design tokens, component references and guidance cards
  now use the same semantic palette.
- Regression coverage runs all evaluated states in light and dark mode and checks
  theme identity, semantic ordering, board/key equality and minimum contrast.
- Verification: 173 Flutter tests passed, `flutter analyze` clean, deterministic
  word-list check passed, eight iOS screenshots regenerated and visually reviewed.
