# Sound — scoped, not built (M7f, 2026-09-03)

Decision doc only. M7 shipped motion + haptics; sound is the third feedback
channel, deliberately deferred. This records the decisions so building it
later is a half-day, not a design project.

## Candidate moments (few, quiet, tied to existing peaks)

| Moment | Sound | Pairs with |
|---|---|---|
| Key press | soft tick, ~20ms | 80ms press scale + selectionClick |
| Tile flip reveal | muted card-flip tick per tile | the 120ms stagger (5 ticks) |
| Win | one warm low chord/thump | the wave's first pop + lightImpact |
| Invalid word | short dull buzz | shake + mediumImpact |
| Duel: opponent finished | single soft ping | the pill's pop |

Anti-scope: no background music, no streak fanfare (rarity lives in motion),
no per-letter pitch scales, nothing looping. The palette is "wood and paper",
matching the brown monochrome — no arcade bleeps.

## Setting

New «الصوت» switch in GameSettings (JSON key `sound`), **default OFF** — a
word game is played in bed and in meetings; sound is opt-in. Sits under
«الاهتزاز» on «حسابي». Plumb through `HapticsService`'s sibling: a
`SoundService` in `lib/game/state/` with semantic methods mirroring
`tap/success/error` + `flip`, so call sites stay identical.

## Package

`audioplayers` over `just_audio`: we need fire-and-forget low-latency short
clips (its `AudioPool` exists for exactly this), not streaming/playlists.
Keep clips as small bundled WAV/OGG under `assets/sounds/`.

## Assets & licensing

Source CC0 only (freesound.org filtered to CC0, or kenney.nl audio packs —
kenney's are CC0 and game-tuned). Ship the license note beside the assets
like the fonts' OFL. Normalize loudness (they should sit *under* speech
volume), trim to <100ms except the win chord (<400ms).

## Test posture

`SoundService` gets the same recording-fake treatment as `hapticsProvider`;
`flutter test` must never touch the audio plugin (guard with a `supported`
flag like NotificationService).
