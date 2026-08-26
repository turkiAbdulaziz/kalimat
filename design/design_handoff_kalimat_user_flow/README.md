# Handoff: كلمات (Kalimat) — sign-in to gameplay user flow

## Overview
The complete first-run flow for **كلمات**, a daily Arabic word game (an Arabic-language five-guess word puzzle). A player arrives cold, authenticates with an emailed one-time code, picks a display name, plays the day's puzzle on a 5×6 board with an Arabic on-screen keyboard, sees their result, and can reach an account screen with stats and preferences. Right-to-left throughout; the palette is a single brown hue plus one taupe.

## About the design files
The files in this bundle are **design references created in HTML** — React-in-the-browser prototypes (Babel-transpiled `.jsx`, no build step) showing intended look and behaviour. They are **not production code to copy directly**.

The task is to **recreate these designs in the target codebase's existing environment** (React, Next.js, React Native, SwiftUI, Flutter, whatever is in use) following its established patterns, routing, state management and component library. If no environment exists yet, pick the framework that best fits the product — a mobile-first web app is the natural choice for this design — and implement there.

The design tokens are the exception: `styles.css` and `tokens/*.css` are real, portable CSS custom properties and can be adopted as-is.

## Fidelity
**High-fidelity.** Final colours, typography, spacing, radii, motion timings and copy. Recreate pixel-perfectly using the target codebase's libraries. Every value in this document is exact and comes from `tokens/*.css`; prefer referencing the token name over the literal.

Deliberately out of scope (never designed, do not invent): password or social sign-in, real email delivery, account deletion, leaderboards, friend lists, desktop/tablet layouts, and the actual Arabic dictionary.

---

## Global frame

Applies to every screen.

- `dir="rtl"`, `lang="ar"`. Right-to-left is structural, not a mirror of an LTR design: the board fills right-to-left, the keyboard's first letter (ا) is rightmost, back chevrons point **left** (`chevron-left`), the back arrow points **right** (`arrow-right`).
- Single centred column, `width: min(500px, 100vw)` (`--app-max-width`), `min-height: 100vh`, page background `--surface-page`. Horizontal gutter 16px (`--gutter`).
- Header, where present: 56px tall (`--header-height`), `--surface-card` background, 1px `--line-soft` bottom border, three slots (leading icon / centred title / trailing actions). Static, not sticky — the app never scrolls on the game screen.
- Type: display font **Noto Kufi Arabic** (700/800) for the wordmark, tiles and dialog titles; UI font **IBM Plex Sans Arabic** (400/500/600) for everything else. `letter-spacing` is **always 0** — spacing Arabic breaks the cursive joins. Line-height 1.75 for body copy.
- Numerals: **Arabic-Indic** (٠١٢٣٤٥٦٧٨٩) everywhere user-facing, including the puzzle number, scores and stats.
- Touch targets: 44px minimum (`--hit-min`); keyboard keys are 52px tall.
- Theme: a single root element carries `data-theme="dark"`; all tokens are remapped in that scope. **No component branches on theme.** Two rules that matter — set `color` on the same element that carries `data-theme` (inherited colour is a resolved literal, so a `body { color: … }` outside the wrapper never re-resolves), and never hardcode a base-ramp value (`--brown-800`) where a semantic token exists.

---

## Flow map

```
signin ──(valid email, "أرسل رمز الدخول")──> code ──(4 digits)──> name ──("ابدأ اللعب"/"تخطّي")──> game(firstRun)
   │                                           │
   └──("المتابعة كزائر", user = زائر)──────────┼───────────────────────────────────────────────> game(firstRun)
                                               └──("تغيير البريد")──> signin

game ──(avatar in header)──> profile ──("العودة إلى اللعبة" / back arrow)──> game   [board state preserved]
profile ──("تسجيل الخروج")──> signin   [board state cleared]
game ──(win, or 6 guesses used)──> stats dialog ──("عرض حسابي")──> profile
```

Steps `game` and `game-first` are the same screen; `game-first` additionally opens the help dialog on mount.

---

## Screen 1 — Sign in (`SignInScreen`)

**Purpose:** explain the game in one line and collect an email address.

**Layout:** single column, `padding: 40px 16px 32px`, `gap: 32px`, three blocks: centred hero (top margin 32px), form, legal line pinned to the bottom via `margin-top: auto`.

**Components, top to bottom**
1. **Wordmark** — "كلمات", display font, weight 800, 52px (`--text-4xl`), colour `--text-wordmark` (#4A3728 light / #F5EADC dark), line-height 1.
2. **Pitch** — "خمّن كلمة اليوم في ست محاولات. كلمة جديدة كل يوم." UI font, 17px (`--text-md`), `--text-muted` (#6B4F3A), line-height 1.75, `max-width: 300px`, centred.
3. **Sample row** — five 44px tiles, 6px gaps, letters ك ل م ا ت with states correct / correct / present / absent / correct, flip-animating in with a 120ms per-tile stagger on mount.
4. **Email field** (`Input`) — label "البريد الإلكتروني" (13px, 500, `--text-muted`), 52px tall input, `--surface-card` fill, 1px `--line` border, 10px radius (`--radius-lg`), 17px text, 16px horizontal padding, placeholder `name@example.com`. Focus: border `--accent`, plus `box-shadow: 0 0 0 3px rgba(138,101,68,.35)` (`--focus-ring`). Hint line below, 11px, `--text-subtle`: "سنرسل لك رمز دخول من أربعة أرقام."
5. **Primary button** — "أرسل رمز الدخول", `Button variant="primary" size="lg" block`: 52px tall, fully pill (`--radius-pill`), `--accent` fill, `--text-on-accent` label, 17px, weight 600. Disabled (opacity .45, `cursor: not-allowed`) until the email matches `/^[^@\s]+@[^@\s]+\.[^@\s]+$/`.
6. **Ghost button** — "المتابعة كزائر", transparent, `--text-muted` label, hover fills `--surface-sunken`.
7. **Legal line** — "بالمتابعة أنت توافق على الشروط وسياسة الخصوصية." 11px, `--text-subtle`, centred.

**Validation:** the invalid state appears only after the user has typed more than 3 characters and the address is still malformed — border and hint switch to `--text-danger` (#7C7168 light / #C3BAB1 dark) and the hint text becomes "بريد غير صحيح". **Errors are taupe, never red** — the system has no red.

---

## Screen 2 — One-time code (`CodeScreen`)

**Purpose:** verify the address with a 4-digit code.

**Layout:** same shell. Hero block (top margin 40px) / code block / buttons pinned bottom.

**Components**
1. **Wordmark** at 30px (`--text-2xl`).
2. **Title** "أدخل رمز الدخول" — display font, 24px (`--text-xl`), weight 700, `--text-body`.
3. **Caption** "أرسلنا رمزاً إلى" — 15px, `--text-muted`.
4. **Email badge** — `Badge tone="accent"`: `--accent-soft` fill, `--text-on-soft` text, 11px, weight 600, 3px/10px padding, pill radius.
5. **CodeInput** — four 52px tiles, 6px gaps, **built from the same `Tile` component as the board**. This is deliberate and is the signature moment of the sign-in: the first thing a new player touches already looks like the game. Empty tiles use `--tile-empty-border`; a filled tile switches to `--tile-filled-border` and pops (`kalimat-pop`, 220ms, `--ease-pop`). A visually hidden `<input inputMode="numeric">` overlays the row and owns focus, so tapping anywhere in the row raises the numeric keypad. Accepts Western **and** Arabic-Indic digits (`[0-9\u0660-\u0669]`), truncated to 4.
6. **Toast** "رمز غير صحيح" on rejection — `--brown-800` pill, `--brown-50` text, 13px, weight 600.
7. **Demo hint** "أي أربعة أرقام تعمل في هذا العرض التوضيحي." 11px, `--text-subtle`. **Remove in production.**
8. **Buttons** — "تأكيد" (primary, disabled until 4 digits) and "تغيير البريد" (ghost, returns to Screen 1).

**Behaviour:** the code auto-submits 350ms after the fourth digit lands. In the prototype any four digits pass and `٠٠٠٠`/`0000` demonstrates the error state; in production this is the real verification call. Editing the code clears the error.

---

## Screen 3 — Display name (`NameScreen`)

**Purpose:** capture the name shown on the account screen and in shared results.

**Components:** wordmark at 30px; title "ما اسمك؟" (display, 24px, 700); explainer "يظهر هذا الاسم في صفحتك وعند مشاركة نتيجتك." (15px, `--text-muted`, max-width 280px); `Input` labelled "الاسم الظاهر", placeholder "ليلى", `maxLength: 20`; primary "ابدأ اللعب" (disabled until the trimmed name is at least 2 characters); ghost "تخطّي" which sets the name to "زائر".

---

## Screen 4 — Game (`GameScreen`)

**Purpose:** play the day's puzzle. Prototype target word: **مدرسة** (م د ر س ة). Word length 5, max guesses 6.

**Layout:** column, `min-height: 100vh` — header (56px, fixed) / board area (`flex: 1`, centred both axes, 16px padding, 16px gap) / keyboard (8px side padding, 16px bottom). The board is vertically centred in whatever space is left; the keyboard is not fixed-positioned, it is simply the last flex child.

**Header**
- Leading: `IconButton` `circle-help` → help dialog.
- Centre: wordmark "كلمات", display 24px, weight 800, `--text-wordmark`.
- Trailing: `IconButton` `bar-chart-3` → stats dialog, then a 34px **Avatar** monogram button → account screen. This avatar is the only route into the account screen.
- `IconButton`: 40px round hit area, transparent, 20px stroke icon in `--text-muted`, hover fills `--surface-sunken`.

**Status line** (34px reserved height, above the board, so the board never shifts): a `Badge` reading "كلمة اليوم ٢٤٧" by default, replaced by a `Toast` for 1300ms when there is a message.

**Board** (`GuessGrid`) — 6 rows × 5 tiles, 6px gaps both axes, RTL fill order. Tile: 58px square (`--tile-size`), 2px border, 6px radius (`--radius-tile`), display font 30px weight 700, letter centred.

| State | Background | Border | Text | Meaning |
|---|---|---|---|---|
| empty | transparent | `--tile-empty-border` #DDBD97 | — | not yet typed |
| filled | transparent | `--tile-filled-border` #A97F55 | `--text-body` | typed, unsubmitted |
| correct | `--brown-700` #6B4F3A | same | #FFFDFA | right letter, right place |
| present | `--brown-400` #C69C6D | same | #FFFDFA | right letter, wrong place |
| absent | `--taupe-500` #988D83 | same | #FFFDFA | not in the word |

**Keyboard** (`Keyboard`) — three **alphabetically ordered** Arabic rows (never a QWERTY-mapped Arabic layout; players scan alphabetically):
```
ا ب ت ث ج ح خ د ذ ر ز
س ش ص ض ط ظ ع غ ف ق ك
إدخال  ل م ن ه و ي ة ى ء أ إ  حذف
```
Letter keys `flex: 1` (min-width 30px), action keys fixed at min-width 62px. All keys 52px tall (`--key-height`), 5px gaps, 6px radius, `--key-bg` fill (action keys `--key-wide-bg`), `--key-text` label, letters 20px / actions 13px, weight 600, plus `inset 0 -2px 0 rgba(46,33,26,.06)` as a tactile lip. A key adopts the best state seen for that letter (correct > present > absent) and then uses the tile state colours with #FFFDFA text. Press: `scale(.94)` over 80ms. Suppressed entirely when the "تلميحات الحروف" preference is off.

**Game rules**
- Tapping a letter appends it while the row has room; حذف removes the last; إدخال submits.
- Submitting fewer than 5 letters: shake the active row (`kalimat-shake`, 420ms) and toast "الكلمة قصيرة". Nothing is consumed. (A real dictionary check belongs here too, with the toast "الكلمة غير موجودة".)
- Scoring is two-pass, so duplicate letters are correct: mark exact positions first, then mark `present` only while unmatched copies of that letter remain in the target. A naive single pass over-reports `present`.
- On submit the row reveals with `kalimat-flip` (420ms, `--ease-in-out`), staggered 120ms per tile; the reveal flag clears after 900ms.
- Win: set won, toast "أحسنت!", open the stats dialog after 1400ms, disable the keyboard.
- Loss (6 rows used): open the stats dialog after 1000ms.

**Help dialog** — title "كيف تلعب"; on first arrival it becomes "أهلاً {name}" instead, which is the only time the product addresses the player by name. Body: "خمّن كلمة اليوم في ست محاولات. كل محاولة يجب أن تكون كلمة عربية من خمسة حروف."; a five-tile example row (م correct, ك absent, ت present, ب absent, ة absent) at 44px; three bullets — "الحرف بالبني الغامق في مكانه الصحيح." / "الحرف بالبني الفاتح موجود في الكلمة لكن في مكان آخر." / "الحرف الرمادي غير موجود في الكلمة." Footer: full-width primary "ابدأ".

**Stats dialog** — title "أحسنت!" on a win, otherwise "الإحصائيات". On a win, an accent badge "كلمات ٢٤٧ — {n}/٦". Then four stats in a row and the six-bar distribution (today's row highlighted `--tile-correct-bg`). Footer: primary "مشاركة النتيجة", ghost "عرض حسابي" → account screen.

**Dialog spec** (both) — fixed overlay `rgba(46,33,26,.55)` with `backdrop-filter: blur(2px)`, click-outside closes. Panel: `--surface-card`, max-width 380px, 12px radius (`--radius-card`), 1px `--line-soft` border, `0 12px 32px rgba(46,33,26,.16)`, 24px padding, entering with `kalimat-rise` (220ms). Header row: display title 20px weight 700, `x` `IconButton` on the **left** (RTL trailing edge). Body 15px, line-height 1.75, `--text-muted`.

---

## Screen 5 — Account (`ProfileScreen`)

**Purpose:** identity, lifetime stats, preferences, sign out.

**Layout:** header (back `arrow-right` / centred title "حسابي" / 40px spacer for optical balance) then `padding: 24px 16px` with `gap: 24px` between sections. Section pattern: an 11px weight-600 `--text-subtle` label above a card — `--surface-card`, 1px `--line-soft`, 12px radius, 16px padding, `0 1px 2px rgba(46,33,26,.06)`.

**Sections**
1. **Identity** — 64px Avatar monogram (`--accent` fill, `--text-on-accent` letter, display font at 42% of the diameter, pill radius) beside the display name (display, 24px, 700), email (13px, `--text-subtle`), and an accent Badge "سلسلة ١٢". **Monogram only — the product has no photo uploads.**
2. **الإحصائيات** — four `StatCard`s in a space-between row: لُعبت ٨٦ / نسبة الفوز ٦٤٪ (accent-coloured, the one emphasised stat) / السلسلة ١٢ / الأفضل ٢١. Value: display font 30px weight 700; label 11px `--text-subtle` 6px below.
3. **توزيع المحاولات** — six `DistributionBar`s: guess label (14px wide, `--text-muted`), then a 22px `--surface-sunken` track with a 4px-radius fill that **grows from the right** (RTL). Fill is `--tile-absent-bg`, or `--tile-correct-bg` for the highlighted row; the count sits inside the fill in `--text-inverse`, weight 600, 8px from the leading edge. Width is `max(6%, count/max)` so a zero row is still visible. Animates over 420ms. The component converts counts to Arabic-Indic digits internally — pass plain numbers.
4. **التفضيلات** — three `Switch` rows then three `ListRow`s in one card. Switch: label 15px weight 500 with an optional 11px `--text-subtle` hint, a 46×28 pill track (`--accent` on / `--taupe-300` off) and a 22px `--brown-0` knob that slides 18px over 220ms, each row separated by a 1px `--line-soft` divider. Rows: "الوضع الليلي" / hint "خلفية بنية غامقة"; "تلميحات الحروف" / hint "إظهار الحروف المستبعدة على لوحة المفاتيح"; "حركة المربعات". Then ListRow: 18px `--text-subtle` leading icon, 15px label, optional 12px `--text-subtle` trailing value, `chevron-left` when tappable, hover `--surface-sunken` — "التنبيه اليومي" (value ٩:٠٠ ص), "مشاركة النتيجة الأخيرة", and "تسجيل الخروج" with `danger` (label `--text-danger`).
5. **Footer** — "عضو منذ {joined} · نسخة ١٫٤", 11px `--text-subtle`, centred; then a secondary full-width "العودة إلى اللعبة".

---

## Interactions & behaviour summary

| Trigger | Result |
|---|---|
| Valid email + "أرسل رمز الدخول" | → code screen, email carried through |
| "المتابعة كزائر" | user = { name: "زائر" }, → game (first run) |
| 4th digit entered | auto-verify after 350ms |
| Verified | → name screen |
| "ابدأ اللعب" / "تخطّي" | → game (first run), help dialog opens |
| Letter key | append to current row if it has room and the game is unwon |
| حذف | drop the last letter |
| إدخال, row incomplete | shake row + toast, nothing consumed |
| إدخال, row complete | evaluate, flip-reveal, update keyboard states |
| Win | toast "أحسنت!", stats dialog after 1400ms, keyboard disabled |
| 6 guesses used | stats dialog after 1000ms |
| Header avatar | → account screen |
| "العودة إلى اللعبة" / back arrow | → game, **same board preserved** |
| "تسجيل الخروج" | board cleared, → sign in |
| "الوضع الليلي" | `data-theme="dark"` on the app root, instantly, on whatever screen you are on |

**Motion** — `--ease-out` cubic-bezier(.2,.8,.3,1) is the default; `--ease-pop` cubic-bezier(.34,1.4,.64,1) is the only springy curve and only for the type pop. Durations: 80ms instant (presses), 140ms fast (hover, colour), 220ms base (pop, dialog rise, screen rise), 420ms slow (flip, shake, bar growth). Keyframes `kalimat-pop`, `kalimat-flip`, `kalimat-shake`, `kalimat-rise` live in `tokens/motion.css`. No looping motion, no parallax, no bounce elsewhere. Honour `prefers-reduced-motion` by treating it like the "حركة المربعات" preference being off.

**Hover** — ghost/secondary surfaces fill `--surface-sunken`; primary buttons darken with `filter: brightness(.93)` rather than swapping colour; keys step one rung up the ramp. **Press** — scale only (.97 buttons, .94 keys), never a colour change. **Disabled** — opacity .45 buttons / .5 keys, never a colour swap. **Focus** — `--focus-ring`.

---

## State management

Owned by the flow root (`App`), which is the single source of truth:

```js
step:     "signin" | "code" | "name" | "game" | "game-first" | "profile"
email:    string
user:     { name, email, joined }
settings: { dark: boolean, hints: boolean, motion: boolean }
board:    { rows: {letter,state}[][], current: string[], letterStates: Record<letter,state>, won: boolean }
stats:    { played, winRate, streak, best }   // static in the prototype
```

`board` is deliberately **not** local to the game screen — that is what lets the account screen be visited mid-puzzle without losing progress. Only sign-out resets it. The game screen keeps genuinely ephemeral UI state locally: `toast`, `shakeRow`, `revealRow`, `dialog`.

**Production data needs, none of which the prototype implements:** request/verify the one-time code; persist the profile; a daily word by date (server-side, so the answer is not shippable in the client bundle); a validation dictionary for guesses; per-user puzzle progress keyed by date so a refresh resumes rather than restarts; lifetime stats and distribution; a share string built from the result grid.

---

## Design tokens

Adopt `styles.css` and `tokens/*.css` directly if the target allows CSS custom properties; otherwise port these values.

**Brown ramp — the only hue:** 950 #231911 · 900 #2E211A · 800 #4A3728 · 700 #6B4F3A · 600 #8A6544 · 500 #A97F55 · 400 #C69C6D · 300 #DDBD97 · 200 #EBD9C0 · 100 #F5EADC · 50 #FBF6EF · 0 #FFFDFA
**Taupe — the only off-hue, for eliminated letters:** 600 #7C7168 · 500 #988D83 · 300 #C3BAB1 · 100 #E4DED8
There is no red, green, or accent second colour. State is carried by brown value: darker = better.

**Semantic (light):** `--surface-page` brown-50 · `--surface-card` brown-0 · `--surface-sunken` brown-100 · `--surface-inverse` brown-900 · `--surface-overlay` rgba(46,33,26,.55) · `--text-body` brown-900 · `--text-muted` brown-700 · `--text-subtle` taupe-600 · `--text-on-accent` #FFFDFA · `--text-on-soft` brown-800 · `--text-wordmark` brown-800 · `--text-danger` taupe-600 · `--line-strong` brown-400 · `--line` brown-300 · `--line-soft` brown-200 · `--accent` brown-600 · `--accent-hover` brown-700 · `--accent-press` brown-800 · `--accent-soft` brown-200

**Dark (`[data-theme="dark"]`):** surfaces brown-950/900/800, overlay rgba(15,10,6,.7) · text brown-100/300/400, `--text-on-soft` brown-200, `--text-wordmark` brown-100, `--text-danger` taupe-300 · lines brown-600/800/800 · accent brown-500 (hover 400, press 300, soft 800) · tile states one rung lighter: correct brown-500, present brown-700, absent taupe-600, empty border brown-800, filled border brown-600 · keys brown-800 (wide 700, hover 700) with brown-100 text · shadows switch to black alphas.

**Spacing** (4px base): 4 8 12 16 20 24 32 40 48 64. **Game metrics:** tile 58, tile gap 6, key height 52, key gap 5, min hit 44, gutter 16, header 56, app max-width min(500px,100vw).
**Radii:** sm 4 · md 6 · lg 10 · xl 16 · tile 6 · key 6 · card 12 · pill 999.
**Type sizes:** 11 13 15 17 20 24 30 38 52, tile 30. **Weights:** 400/500/600/700/800. **Leading:** 1.3 tight · 1.5 snug · 1.75 body.
**Shadows** (warm brown, never neutral black): sm `0 1px 2px rgba(46,33,26,.06)` · md `0 2px 8px rgba(46,33,26,.08)` · lg `0 12px 32px rgba(46,33,26,.16)` · inset `inset 0 -2px 0 rgba(46,33,26,.06)` · focus `0 0 0 3px rgba(138,101,68,.35)`.

**Backgrounds are flat.** No gradients, no photography, no illustration, no texture, no pattern. Transparency and blur appear in exactly one place: the dialog overlay.

## Copy & tone

Arabic (MSA), no diacritics. Second person, imperative, unadorned — the product instructs and confirms, it never chats. Buttons 1–2 words; toasts 2–4 ("الكلمة غير موجودة", "الكلمة قصيرة", "أحسنت!"). Praise is one word, once. Failure copy is neutral, never scolding. **No emoji anywhere** — a shared result is drawn as coloured square elements, not emoji. Hierarchy comes from size and weight only: Arabic has no case, and all-caps or letter-spacing is never used.

## Assets

- **Fonts** — Noto Kufi Arabic and IBM Plex Sans Arabic (UI), IBM Plex Mono (code/tokens only), all from Google Fonts via `tokens/fonts.css`. ⚠️ **Substitution:** no brand font files were supplied for this design system; these are the closest matches. Confirm before shipping.
- **Icons** — Lucide 0.454.0 from CDN, stroke only, 20px in a 40px hit area, always `currentColor`. Six glyphs in total: `circle-help`, `bar-chart-3`, `settings`, `share-2`, `x`, `arrow-right`, `chevron-left`, `bell`, `log-out`. ⚠️ **Substitution:** no icon set was supplied. Swap for the codebase's own set, matching the 2px stroke weight and unfilled style.
- **Logo** — **none exists.** No mark was supplied and none was drawn. The brand mark is the word "كلمات" set in the display font at weight 800. Do not invent a logo.
- No images, illustrations or raster assets of any kind.

## Reference files

**This document is self-sufficient** — everything needed to implement the flow is above. The prototype it describes lives in the same design-system project, one level up:

| Path | What it is |
|---|---|
| `ui_kits/kalimat_app/index.html` | Entry point — mounts the flow at the sign-in step |
| `ui_kits/kalimat_app/signin.html`, `game.html`, `profile.html` | The same app seeded at a later step, for reviewing one screen in isolation |
| `ui_kits/kalimat_app/App.jsx` | Flow router, theme boundary, and the single store of user/settings/board state |
| `ui_kits/kalimat_app/SignIn.jsx` | `AuthShell`, `Wordmark`, `SignInScreen`, `CodeScreen`, `NameScreen` |
| `ui_kits/kalimat_app/Game.jsx` | `GameScreen`, `GameHeader`, `HelpDialog`, `StatsDialog`, guess evaluation |
| `ui_kits/kalimat_app/Profile.jsx` | `ProfileScreen` |
| `components/game|core|forms|data/` | The design system's primitives — Tile, GuessGrid, KeyCap, Keyboard, Button, IconButton, Dialog, Toast, Badge, Switch, Avatar, ListRow, Input, CodeInput, StatCard, DistributionBar. Each has a `.d.ts` props contract and a `.prompt.md` usage note — read those for the intended API. |
| `styles.css`, `tokens/` | The real design tokens — portable, adopt as-is |
| `readme.md`, `guidelines/` | Brand, content and visual foundations, plus specimen cards — read before extending the design with new screens |

The copies are deliberately **not** duplicated into this folder: the design-system compiler indexes every `.jsx` in the project, and a second copy of each component collides with the original on the shared namespace. Download the whole project instead of this folder alone if you want the runnable prototype.

To run the prototype, serve the project root over HTTP (`python3 -m http.server`) and open `ui_kits/kalimat_app/index.html` — the `.jsx` files are fetched and transpiled in the browser, so `file://` will not work.
