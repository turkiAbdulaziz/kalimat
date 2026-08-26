# كلمات (Kalimat) — Design System

كلمات is a daily Arabic word game: an Arabic-language take on the five-guess word puzzle, built for Arabic speakers with Arabic vocabulary. The board layout follows the familiar grid-and-keyboard convention, but everything is optimised for Arabic — right-to-left rows, an alphabetically ordered Arabic keyboard (not a QWERTY-mapped one), generous line height for Arabic glyphs, and no letter-spacing anywhere. The palette is deliberately narrow: brown to light brown, with one desaturated taupe for "not in the word".

## Sources given
- A written company/product description only: *"(كلمات) is an Arabic wordle for Arabic speakers that uses Arabic words; it uses the same layout as wordle but optimized for Arabic language; minimal colors brown to light brown color schema."*
- **No codebase, no Figma file, no decks, no logo, and no font files were provided.** Everything below is authored from that description. All values are proposals to confirm, not recreations of an existing product.

## Products / surfaces
One surface: the mobile-web daily puzzle (`ui_kits/kalimat_app/`) — sign-in, one-time code, display name, board, and account screen. No marketing site, desktop app, or docs site exists in this system because none was supplied.

## CONTENT FUNDAMENTALS
- **Language.** Arabic (MSA), no diacritics in UI copy. Latin text appears only in developer-facing material. Never mix a Latin word into a sentence where an Arabic one exists.
- **Voice.** Second person, imperative, unadorned: *خمّن كلمة اليوم في ست محاولات.* / *ابدأ اللعب* / *مشاركة النتيجة*. The product instructs and confirms; it never chats. Onboarding is the one place it addresses the player directly — *ما اسمك؟*, then *أهلاً ليلى* once — and never again.
- **Length.** Buttons 1–2 words. Toasts 2–4 words (*الكلمة غير موجودة*, *الكلمة قصيرة*, *أحسنت!*). Help text: three short rules, one line each.
- **Praise is restrained.** A single word on a win (*أحسنت!*). No streak celebration copy, no exclamation stacking, no "you're on fire".
- **No casing system.** Arabic has no case, so hierarchy is carried by size and weight only — never by all-caps or small caps (and never by letter-spacing, which breaks Arabic joins).
- **Numerals.** Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩) everywhere in product UI, including puzzle number and score (*كلمات ٢٤٧ — ٤/٦*). Western digits only in tokens, code, and specimen cards.
- **Emoji.** None in the UI. The shared result uses the brand's own colour squares rendered as blocks, not emoji faces.
- **Tone in failure.** Neutral, never scolding: the invalid-word toast states the fact and disappears.

## VISUAL FOUNDATIONS
- **Colour.** One hue. `--brown-950 → --brown-50` carries text, surfaces, accents and the "correct" state; `--taupe-500` is the only off-hue and exists solely for eliminated letters. Page is warm off-white `#FBF6EF`; cards a shade lighter `#FFFDFA`. No second brand colour, no red/green success-error pair — state is communicated by brown value, dark = correct.
- **Dark surface.** `[data-theme="dark"]` in `tokens/colors.css` remaps the same semantic names (surfaces to `--brown-950/900/800`, text to `--brown-100/300/400`, tile states one rung lighter so they read against a dark page). Components never branch on theme — set `data-theme="dark"` on one root element and everything below follows. Two rules make that work: **never hardcode a hex or a base-ramp token (`--brown-800`) where a semantic one exists** — use `--text-on-soft` for text on `--accent-soft` and `--text-wordmark` for the brand mark — and **set `color` on the same element that carries `data-theme`**, because inherited colour is a resolved literal: a `body { color: var(--text-body) }` outside the wrapper stays light forever.
- **Type.** Display: Noto Kufi Arabic 700/800 (wordmark, tiles, dialog titles) — geometric, high-contrast letterforms that stay legible at tile size. UI: IBM Plex Sans Arabic 400–600 (body, labels, keys). Mono: IBM Plex Mono for tokens and code only. Leading is generous (`--leading-body: 1.75`); tracking is always 0 for Arabic.
- **Layout.** Single column capped at `--app-max-width: 500px`, centred, full viewport height. Header is 56px and static (not sticky — the app never scrolls). Board centred in the free space, keyboard pinned to the bottom with a 16px gutter. Keys stretch to fill width; tiles never do.
- **Backgrounds.** Flat warm off-white. No gradients, no photography, no illustration, no repeating pattern, no texture or grain. Emptiness is intentional: the board is the only figure on the page.
- **Cards & dialogs.** `--surface-card` fill, 1px `--line-soft` hairline, 12px radius, `--shadow-lg` when floating over the overlay. No coloured left borders, no double borders, no card headers with tinted fills.
- **Corner radii.** Tiles and keys 6px (soft but still square-reading). Cards 12px. Buttons and badges fully pill (`--radius-pill`). Nothing is a perfect circle except icon buttons.
- **Borders.** Tiles are 2px; everything else 1px. Three line values: `--line-strong` (filled tile edge), `--line` (default), `--line-soft` (dividers inside cards).
- **Shadows.** Warm brown, never neutral black: `rgba(46,33,26,…)`. Three outer levels (sm/md/lg) plus `--shadow-inset` — a 2px inner lip on keyboard caps that gives them physicality without a border. Focus is a 3px 35%-opacity brown ring.
- **Transparency & blur.** Only for the dialog overlay: 55% brown wash plus a 2px backdrop blur. No frosted panels, no translucent headers, no protection gradients — imagery that would need them doesn't exist here.
- **Animation.** Purposeful and short. Pop (`kalimat-pop`, 220ms, `--ease-pop`) when a letter is typed; flip (`kalimat-flip`, 420ms, `--ease-in-out`) on reveal, staggered 120ms per tile right-to-left; shake (`kalimat-shake`, 420ms) on an invalid word; rise-and-fade (`kalimat-rise`) for dialogs, toasts, and screen changes (the incoming screen fades in and rises 8px at 220ms; closing a pushed screen reverses to sink-and-fade). Default easing `--ease-out` cubic-bezier(.2,.8,.3,1). No bounce outside `--ease-pop`, no looping motion, no parallax.
- **Hover states.** Ghost/secondary surfaces fill with `--surface-sunken`; primary buttons darken via `filter: brightness(.93)` rather than a second colour token; keyboard caps step one rung up the ramp (`--key-bg-hover`).
- **Press states.** Scale down: 0.97 for buttons, 0.94 for keys, at `--dur-instant` (80ms). Colour does not change on press.
- **Disabled.** Opacity 0.45 for buttons, 0.5 for keys. Never grey-out by swapping colour.
- **Imagery.** There is none. If imagery is ever added it must be warm-toned and desaturated to sit inside the brown range; cool or high-saturation photography is off-brand.
- **Touch.** `--hit-min: 44px` is a hard floor; keys are 52px tall.

## ICONOGRAPHY
- **No icon set was supplied.** SUBSTITUTION: the system uses **Lucide** (v0.454.0, CDN) — 24px grid, 2px round-cap stroke, no fill — because its weight matches the 2px tile border and it covers the four glyphs the product needs. Flagged for replacement if real assets exist.
- Icons appear in exactly one place: the header (circle-help, bar-chart-3, settings) and dialog close (x), plus share-2 on the share action. Everything else is text.
- Stroke icons only, always `currentColor` at `--text-muted`, always 20px inside a 40px round hit area. Never filled, never two-tone, never coloured.
- **No icon font, no sprite sheet, no PNG icons.** Load Lucide from CDN and call `lucide.createIcons({nameAttr:"data-lucide"})`.
- **Emoji are never used as icons.** Unicode characters are not used as icons either — the one exception is the coloured square block in a shared result, which is drawn as a styled `div`, not a character.
- Icons are never mirrored for RTL; the four in use are direction-neutral.

## Logo
**No logo file was supplied, and none has been drawn.** Wherever a mark belongs, set the brand name **كلمات** in `--font-display` at weight 800 — on `--accent`, on `--surface-card`, or on `--surface-inverse` (see the Brand → Wordmark card). There is no `assets/` directory because there are no supplied assets to hold.

## Substitutions to confirm
1. **Fonts** — Noto Kufi Arabic + IBM Plex Sans Arabic (Google Fonts) stand in for unsupplied brand fonts.
2. **Icons** — Lucide stands in for an unsupplied icon set.
3. **Logo** — type-set wordmark stands in for an unsupplied mark.

## Intentional additions
- `IconButton` — an icon wrapper was needed to render the substituted Lucide glyphs at a consistent 40px hit area.
- `Input`, `CodeInput`, `Avatar`, `ListRow` — added for the sign-in and account screens, which had no supplied source. `CodeInput` is deliberately built on `Tile` so authentication carries the board's visual language; `Avatar` is a monogram because the product has no photo uploads.

## Index
- `styles.css` — the single entry point consumers link (`@import` list only)
- `tokens/` — `fonts.css`, `colors.css`, `typography.css`, `spacing.css`, `radii.css`, `elevation.css`, `motion.css`
- `guidelines/` — 18 specimen cards: Colors (brown ramp, taupe, game states, surfaces, text & lines, dark surface), Type (display, UI, scale, numerals, RTL rules), Spacing (scale, game metrics, radii, shadows, motion), Brand (wordmark, share grid)
- `components/game/` — Tile, GuessGrid, KeyCap, Keyboard
- `components/core/` — Button, IconButton, Dialog, Toast, Badge, Switch, Avatar, ListRow
- `components/forms/` — Input, CodeInput
- `components/data/` — StatCard, DistributionBar
- `ui_kits/kalimat_app/` — full flow, sign-in through gameplay (`index.html`, `signin.html`, `game.html`, `profile.html`, `App.jsx`, `SignIn.jsx`, `Game.jsx`, `Profile.jsx`, `README.md`)
- `thumbnail.html` — homepage tile
- `SKILL.md` — Agent Skills entry point
- No slide templates: no deck was supplied.
