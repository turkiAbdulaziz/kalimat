# Inspiration — app-wide motion & game feel (2026-09-03)

## References
- https://blog.duolingo.com/streak-milestone-design-animation — Duolingo's streak-milestone
  animation postmortem (fetched). Key transferables: timing/rhythm mattered more than the
  artwork ("multiple passes of rough animation"), and restraint — elaborate concepts were
  rejected as unscalable. Celebration is gated to landmarks so it stays rare.
- https://duolingo.deconstructoroffun.com/mechanics/streaks — analysis of the streak
  mechanic: reserving celebration for landmarks is what keeps it powerful (day 47 gets a
  counter tick; day 50 gets the moment). Redesigning one milestone animation moved day-7
  retention +1.7%.
- https://material.io/archive/guidelines/motion/choreography.html — Material choreography:
  staggered list entrances begin ≤20ms apart; never wait for one item to finish before the
  next starts; order must be scannable, not chaotic.
- https://iq.opengenus.org/wordle-using-html-css-and-js/ — Wordle clone animation breakdown:
  per-tile flip stagger, typed-letter bounce, shake on invalid; the win moment is the same
  vocabulary (a hop) staggered across the winning row — celebration by choreography, not by
  new effects or color.
- https://developer.apple.com/design/human-interface-guidelines/patterns/feedback/ — HIG
  feedback: pair a crisp light haptic with a sharp quick animation, fired exactly at the
  visual peak; multi-modal feedback (visual + haptic) is also an accessibility win when
  motion is reduced.
- https://developer.apple.com/videos/play/wwdc2023/10158/ — "Animate with springs" (WWDC23,
  not opened; from search): springs earn their keep on gesture-driven, interruptible motion
  because they preserve velocity. Kalimat has no gesture-driven surfaces, so cubics suffice.
- https://css-tricks.com/almanac/rules/m/media/prefers-reduced-motion/ — reduced-motion
  etiquette: *replace* motion (opacity-only, short) rather than delete all state-change cues.
- https://uxdesign.cc/what-you-should-know-about-skeleton-screens-a820c45a571a — Bill Chung's
  skeleton-screen research: slow, steady motion is perceived as shorter than fast motion;
  wave/shimmer beats pulse — but both loop, which Kalimat forbids (see below).
- https://pub.dev/packages/flutter_animate — flutter_animate (fetched): effect library with
  `AnimateList` interval staggers and `Animate.defaultDuration/defaultCurve`; no built-in
  reduced-motion gate.
- https://arwordle.netlify.app/ and
  https://play.google.com/store/apps/details?id=app.knz.wordlearabic — Arabic Wordle
  implementations (AlWird, كنز الكلمات) found via search (not opened). Both appear to keep
  the stock green/yellow palette and stock motion; none surfaced a distinctive win moment —
  a restrained, choreographed brown celebration would be a genuine differentiator in the
  Arabic dailies space. (unverified beyond search listings)

## What fits the doctrine
- **The win "wave" — Wordle's dance, domesticated.** Wordle celebrates by replaying its own
  vocabulary: the winning row hops, one tile after another. Kalimat already owns both halves:
  `kalimat-pop` (scale 1→1.08→1, `Motion.easePop`, `Motion.base`) and RTL stagger
  (`Motion.flipStagger`). A pop wave across the winning row — rightmost tile first, ~60–80ms
  apart — after the flip reveal and before the stats dialog rises is a celebration made of
  zero new tokens. `easePop` is the one allowed overshoot, and this is exactly the tile
  context it was reserved for.
- **Milestone rarity without the phoenix.** Duolingo's real lesson is scheduling, not
  spectacle: celebrate rarely so celebration means something. Kalimat mapping: the streak
  badge («سلسلة ١٢») does a single `kalimat-pop` only when the number *increments*; at
  landmark values (٧، ٣٠، ١٠٠) it gets one extra beat — e.g. badge fill steps `accentSoft`
  → `accent` over `Motion.fast` and back. Copy never changes (doctrine: praise is one word,
  once; no streak celebration copy).
- **Counted stats.** Count-up numbers with ease-out deceleration give a number "a sense of
  arrival." In the stats dialog: the four `StatCard` values tick up in Arabic-Indic digits
  over `Motion.slow`/`Motion.easeOut`; distribution bars keep their existing 420ms growth
  but gain a top-to-bottom stagger (~60ms/row) so the sequence *ends* on today's
  highlighted `tileCorrect` row — the eye is delivered to the result.
- **Staggered list entrances.** Material choreography (≤20ms–30ms apart, overlapping, never
  serial) maps directly onto the house `kalimat-rise`: challenges/friends/duel rows fade+rise
  8px with a ~30ms per-row offset, capped at the first ~8 rows (the rest appear together).
  One `AnimationController`, `Interval` curves, `Motion.base` total feel.
- **Loss that respects the player.** NYT-style neutrality: no sad motion, no droop. The
  answer is revealed inside the stats dialog as a filled tile row (the board's own visual
  language), entering with the same rise as everything else. The absence of celebration *is*
  the loss state; the doctrine's "neutral, never scolding" already says this.
- **Event-driven live elements.** The Realtime opponent pill and the «دورك» badge animate
  only when their *value changes*: digit swaps via a mini rise (old digit fades down, new
  fades up, `Motion.fast`), container does one `kalimat-pop`. Motion as information — "she
  just played" — never as decoration. No idle pulses.
- **Empty states that breathe once.** The sign-in hero already demonstrates the pattern: a
  sample tile row flipping in with stagger on mount. Empty challenges/friends states can
  reuse it — a 44px tile row spelling a relevant word flips in once, then rests. A single
  breath, never a loop.
- **Haptics as the second channel.** `HapticFeedback.selectionClick` on key press (paired
  with the existing 80ms 0.94 scale), `lightImpact` at the start of the win wave, at the
  moment the peak visual event occurs (HIG). Bonus: when «حركة المربعات» is off, haptics
  still carry the "it worked" signal that motion no longer does.
- **Reduced-motion etiquette upgrade.** Current behavior (off ⇒ instant swap) is stricter
  than the accessibility guidance, which prefers *replacing* translation with a short
  opacity-only fade so state changes remain legible. Worth considering: off ⇒ 140ms
  fade-only (no translate, no scale) in `rise_route.dart` and dialogs. Record as an option;
  the current instant-swap is also defensible.

## What violates the doctrine (and why it's still interesting)
- **Confetti / particle bursts** (Duolingo, most win screens) — breaks brown monochrome and
  no-decoration-gradients; particles imply many hues and looping physics. Salvageable core:
  the *burst-outward-from-the-achievement* energy survives as the staggered pop wave — a
  spatial sequence radiating across the row.
- **Mascot/character takeovers** (Duo's phoenix, full-screen celebrations) — Kalimat has no
  imagery, no illustration, no logo even. Salvageable core: milestone *rarity scheduling*
  and the insight that timing passes matter more than asset quality.
- **Streak flames** — color iconography + implied looping flicker. Salvageable core: the
  streak number itself as the hero, set in the display font and popped once on increment.
- **Shimmer skeletons** — the wave is looping motion, forbidden outright. Salvageable core:
  the *layout-matching* insight. Static `surfaceSunken` placeholder blocks (12px card radius,
  1px `lineSoft`) that cross-fade to real content via `kalimat-rise` keep the perceived-speed
  benefit without the loop. Chung's "slow and steady beats fast" supports calm over flash.
- **Springs everywhere** (iOS default) — springs exist for interruptible, gesture-driven
  motion that preserves velocity. Kalimat has no draggable surfaces; adopting springs would
  smuggle bounce past the "no bounce outside easePop" rule. Salvageable core: if a
  gesture-driven surface ever ships (sheet drag, pull-to-refresh), that one surface may
  warrant a critically-damped spring — damped to zero overshoot, so it *feels* physical but
  never bounces.
- **Pull-to-refresh characters / custom looping spinners** — looping decoration. Salvageable
  core: nothing beyond tinting. Keep the existing `CircularProgressIndicator(strokeWidth: 2)`
  in `accent`; an indeterminate spinner is functional motion, the one loop that earns its
  keep, and it should stay system-standard rather than gain personality.
- **Screen shake / hit-stop** (game juice canon) — too violent for a calm daily.
  `kalimat-shake` on invalid words is already the domesticated version; do not extend it.

## Recommended direction
Adopt one house rule — **"motion is event-driven and runs once"** — and spend the entire
budget on choreography rather than new effects. Every currently-static surface gets exactly
one of the four existing keyframes, triggered by a state change, sequenced with the existing
stagger token: lists rise in offset by 30ms, stats count up and bars fill top-to-bottom,
badges and pills pop when their number changes, empty states flip in a tile row once. This
makes the whole app feel like one organism (everything speaks pop/flip/shake/rise) instead
of a lively board inside a dead shell — and it is cheap, testable, and trivially gated by
«حركة المربعات» because every animation is a one-shot with a known end state.

The flagship is the **win sequence**: flip reveal (exists) → 250ms hold → pop wave across
the winning row, rightmost first, 70ms apart, with one `lightImpact` on the first pop →
stats dialog rises (exists) → stat values count up in Arabic-Indic digits while distribution
bars fill in order, landing on today's highlighted row → streak badge pops once if the streak
grew. Total added vocabulary: zero. Total new code: two small helpers. On loss, the same
sequence minus the wave and haptic, plus the answer revealed as a filled tile row. Skip
flutter_animate: it is a fine library, but it has no reduced-motion gate, its effect
vocabulary is far wider than the doctrine allows, and Kalimat's hand-rolled controllers plus
a strict token file are precisely the situation where a second animation dialect creates
drift. Build the two helpers in-house.
