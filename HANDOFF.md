# كلمات (Kalimat) — Developer Handoff

Arabic Wordle-style daily word game. Flutter (Android + iOS ship targets), Supabase backend.
This file orients anyone (or any future session) picking the project up cold.
For *what's done and what's next*, see [STATUS.md](STATUS.md).

**Repo**: https://github.com/turkiAbdulaziz/kalimat (private). Development happens on
two machines — a Windows 11 box and a MacBook (iOS) — and **git is the only sync
channel between them**: commit + push on one side, pull on the other. Never rely on
OneDrive to carry the repo to the Mac.

---

## The product in one paragraph

Guess the 5-letter Arabic word of the day in 6 tries. RTL everywhere, MSA copy,
Arabic-Indic digits (٠-٩) in all UI. Lenient matching: hamza forms أ إ آ count
as ا, ة = ه, ى = ي (target-side also ؤ→و, ئ→ي); the board shows what the player typed;
the stored answer keeps correct spelling. Brown monochrome design (correct = dark brown,
present = light brown, absent = taupe) from the design system in `design/` — that folder
is the visual source of truth (tokens in `design/tokens/*.css`, reference React components,
runnable screen prototypes in `design/ui_kits/kalimat_app/`, and the **user-flow spec** in
`design/design_handoff_kalimat_user_flow/README.md`). Around the game surface sits the
designed flow: first-run sign-in (Google/Apple/guest — the designed email-OTP screens
were deliberately dropped) → display name → game, and a profile screen «حسابي» reached
only via the header avatar (stats, preferences, daily reminder, sign-out). Beside the daily
ritual sits the one competitive surface, «التحدّيات»: add a friend by their ٦-digit code,
then duel them on a word drawn from a pool that is never a daily answer — fewer guesses
wins, the faster solve breaks the tie.

## Environment & toolchain

Both machines run Flutter **3.47.1** stable / Dart 3.13.1 — keep them matched so
`pubspec.lock` and the test suite behave identically.

**Windows 11 box (Android dev)**
- **No Visual Studio C++ toolchain** → the `windows` target does NOT build here.
  Verify on the Android emulator (AVD `Pixel_6`; address it as `adb -s emulator-5554`,
  a stale `emulator-5562 offline` entry sometimes lingers) or Chrome.
- Windows Developer Mode must stay ON (Flutter plugin symlinks).
- Working copy lives inside OneDrive (accepted build churn; `build/`/`.dart_tool/` are
  git-ignored but still sync). The Mac clone must come from GitHub, not OneDrive.

**MacBook (iOS dev)** — first verified 2026-08-26 (iPhone 17 simulator, iOS 26.5)
- Xcode 26.6; CocoaPods 1.17.0 is installed but **unused** — Flutter 3.47 integrates
  iOS plugins via **Swift Package Manager**. There is no `Podfile`; do NOT add one back.
  `Package.resolved` (committed) is the iOS dependency lock, the counterpart to
  `pubspec.lock`; `Flutter/ephemeral/Packages/...` is gitignored and regenerated per build.
- **iOS minimum is 15.0** (Flutter 3.47's floor — it rewrites lower targets on build).
  iPhone 6s / 7 / SE-1st-gen are out of scope for launch.
- Simulator needs no Apple account; a physical iPhone needs a personal team in Xcode
  (`ios/Runner.xcworkspace` → Signing) + Developer Mode on the phone.

**App identity (both platforms)**: `com.kalimat.game` — it was `com.kalimat.app` until
2026-09-05, when the first App Store archive revealed that Apple had already issued that ID to a
different team (bundle IDs are global across all developer accounts). Android namespace/MainActivity
remain `com.kalimat.kalimat` — fine, applicationId ≠ package. Android minSdk 24;
core-library desugaring is ON in `android/app/build.gradle.kts` (required by
flutter_local_notifications — don't remove).

```powershell
flutter test                 # 149 tests (engine + data + state + widget + flow), all green — MUST run unconfigured
flutter analyze              # clean
flutter run --dart-define-from-file=env/dev.json    # online build (Supabase creds live in env/dev.json)
# Windows/Android:
flutter build apk --debug --dart-define-from-file=env/dev.json
adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s emulator-5554 shell am start -n com.kalimat.game/com.kalimat.kalimat.MainActivity
# Mac/iOS:
#   open -a Simulator && flutter run --dart-define-from-file=env/dev.json
```

## Code map (`lib/`)

| Path | What lives there |
|---|---|
| `core/strings.dart` | Every piece of MSA copy. Single locale, no i18n framework. |
| `core/theme/` | `kalimat_colors.dart` (brown ramp + `KalimatColors` ThemeExtension, light + **official** dark mapping from the handoff's colors.css, incl. `textWordmark`/`textOnSoft`/`textDanger` and theme-aware shadows — `c.shadowSm/Md/Lg`, instance fields, not statics), `kalimat_theme.dart` (TextThemes — **letterSpacing is always 0** for Arabic), `metrics.dart` (tile 58 / key 52 / max width 500…), `motion.dart` (durations + cubics). |
| `core/utils/arabic_digits.dart` | ٠-٩ conversion + ٪. All UI numbers go through this. |
| `core/motion/` | The M7 primitives, all one-shot and event-driven: `staggered_rise.dart` (interval-staggered kalimat-rise for list/section entrances), `count_up_text.dart` (Arabic-Indic count-up), `celebration_pop.dart` (pop on mount-with-cause or on value change — streak badge, duel pill, result card). House rule: **motion is event-driven and runs once** — no loops, no idle pulses, no shimmer (see `design/inspo/app-wide-motion.md`). |
| `core/theme/motion_scope.dart` | The «حركة المربعات» gate for shared leaf widgets: `MotionScope` InheritedWidget installed once in `app.dart` (`MaterialApp.builder`, above the Navigator so dialogs inherit it), read via `context.motionEnabled` / `context.motionDuration(token)`, **defaults to true when absent** (leaf tests need no wrapper). The cut: gate translation/scale/stagger/blur; ≤140ms color/opacity crossfades and the 80ms press scale are exempt as state legibility. Board reveal/shake/wave stay gated in the state layer; `GameSurface(motion:)`/`riseRoute(motion:)` prop-drills were kept. |
| `core/rise_route.dart` | The house screen transition (kalimat-rise: fade + 8px rise, `Motion.base`/`easeOut`; pop = sink+fade). Used by `flow/root_flow.dart`'s step switcher, both profile push sites, and the «التحدّيات» / duel-board pushes. Gated by the motion setting — off ⇒ `Duration.zero`. |
| `game/engine/` | **Pure Dart, zero Flutter imports, fully unit-tested.** `letters.dart` (33-key rows + `normalizeLetter/Word`), `evaluate.dart` (duplicate-safe two-pass on normalized forms), `keyboard_state.dart` (upgrade-only hints keyed by canonical class — this is why أ/إ/ا color together), `puzzle_calendar.dart` (**epoch 2026-09-01 = puzzle ١**), `share_grid.dart` (RLM-prefixed 🟫🟨⬜ rows). |
| `game/data/` | `dictionary.dart` (18.3k normalized guess set), `bundled_word_source.dart` (offline answers, same ordering as the server seed), `local_store.dart` (SharedPreferences JSON: cached word, board, **stats — local is authoritative**, settings, pending-results queue, `onboarded` flag, cached `display_name`, reminder settings, and per-duel boards keyed by challenge id — pruned to the last 10). |
| `game/state/` | Riverpod Notifiers. `word_game.dart` holds the **shared** loop — typing, validation, reveal choreography (flip 900 ms = 420 + 4×120 stagger), win/loss sequencing incl. the **win wave** (250 ms hold → pop ripples across the winning row at 70 ms/tile via `waveRow` — duels inherit it; stats dialog at 1600 ms, or 1400 ms motion-off with no wave), the solve clock — as `WordGameNotifier`, with session hooks (`sessionWord`, `persistBoard`, `onGuessSubmitted`, `onFinished`). `game_controller.dart` is the daily session on top of it (board save, local stats, result queue, `applyServerWord` — never interrupts a game in progress) and re-exports `word_game.dart`, so `GameState`/`kWordLength`/`dictionaryProvider` still come from it. The duel session is `challenge/challenge_controller.dart`. `haptics.dart` (`hapticsProvider` → semantic `tap/success/error`, behind the «الاهتزاز» setting, fired from the notifier at visual peaks — still fires when motion is off; tests override with a recording fake). |
| `game/widgets/`, `game/dialogs/`, `game_screen.dart` | The UI. Widgets are dumb/props-only (shared set incl. `KalimatAvatar`, `KalimatInput`, `KalimatListRow`, `Wordmark`). Dialogs via `showKalimatDialog` (brown overlay + 2 px blur + rise); there is **no settings dialog** — preferences live on the profile screen, and the header's trailing avatar (not a gear) opens it. Pushed screens share `ScreenHeader` + `SectionCard`/`SectionNote`; the board itself is `GameSurface` (badge slot + grid + keyboard), mounted by both the daily screen and the duel screen. The game screen never scrolls; tiles shrink first on small screens. |
| `flow/` | `flow_controller.dart` (`FlowStep` signin/name/game + `flowProvider`; gating: unconfigured or `onboarded` → straight to game, existing installs migrate silently; also `displayNameProvider`, sign-out clears board+identity but **keeps stats**; `deleteAccount()` calls the 0007 RPC and then wipes the device — stats, duel boards and the result queue included — before returning to sign-in), `root_flow.dart` (`home:` widget — kalimat-rise switch between steps: incoming screen fades in + rises 8px over `Motion.base`, outgoing fades in place; instant when «حركة المربعات» is off). |
| `onboarding/` | `auth_shell.dart` (centred column, pinned bottom block), `sign_in_screen.dart` (Google/Apple/guest; inline taupe error line — new screens have no ToastSlot; the Google button renders only while `kGoogleSignInAvailable` — i.e. `GOOGLE_WEB_CLIENT_ID` is set — and Apple takes the primary slot otherwise, so a reviewer never meets a dead button), `name_screen.dart`. |
| `profile/` | `profile_screen.dart` («حسابي», pushed with the shared rise route (`core/rise_route.dart` — sink+fade on close, instant removal on sign-out); board state survives because it lives in providers), `edit_name_dialog.dart` (tap the name), `save_progress_section.dart` (anonymous-only linking, moved from the old settings dialog, keeps the confirm-switch dialog; same Google gate), `delete_account_dialog.dart` («حذف الحساب» — the confirm behind the danger row that sits under sign-out for linked users; App Review 5.1.1(v) requires in-app deletion wherever accounts can be created), `reminder_dialog.dart` (١٢-hour steppers + ص/م). |
| `challenge/` | Duels «التحدّيات». `models.dart` (pure Dart: `ChallengeSide/Summary/Detail`, `Friend`, and `decideOutcome` — the winner rule, kept in lockstep with the SQL), `challenge_controller.dart` (`activeChallengeProvider` + `challengeGameProvider` + `opponentSideProvider`; one duel at a time, so no family), `challenges_screen.dart` (segmented shell) → `challenges_tab.dart` / `friends_tab.dart`, `challenge_screen.dart` (the duel board), `challenge_result_dialog.dart`, plus the add-friend / pick-friend / remove-friend dialogs. |
| `notifications/` | `notification_service.dart` (flutter_local_notifications v22 + timezone; **inexact** daily schedule — no exact-alarm permission; `supported` guard keeps it off web/desktop/tests), `reminder_controller.dart` (permission → schedule/cancel → persist). Manifest has the two receivers + POST_NOTIFICATIONS/BOOT_COMPLETED. |
| `backend/` | Supabase layer, **entirely dormant until configured** — see below. `sync_service.dart` runs on launch + app-resume: ensure anon session → fetch day word (server Riyadh calendar is authority) → bundled fallback on offline rollover → flush result queue. `challenge_repository.dart` / `friends_repository.dart` wrap the duel + friend RPCs and own the Realtime channel for opponent progress. `auth_repository.dart` also carries `deleteAccount()` (RPC, then a **local-scope** sign-out — the server session died with the user). |

Layering rule: `backend/` imports `game/` and `challenge/models.dart`, never the reverse.
UI touches backend only through the providers in `backend_providers.dart`/`sync_service.dart`
(game_screen, the stats dialog's leaderboard tab, and the flow/onboarding/profile/challenge
layer). `challenge/` builds on `game/` — it reuses the engine, the board surface, and the
shared game loop rather than forking any of them.

## Word-list pipeline

`dart run tool/build_wordlists.dart` (raw inputs in git-ignored `tool/raw/`, download URLs
in the file header). Emits `assets/words/dictionary.txt`, `tool/out/answers_candidates.txt`
(11,251 frequency-ranked candidates with clitic flags AL/W/F/B/L/SUF), a **provisional**
`assets/words/answers.txt` (only when missing — it will not clobber a curated list),
`supabase/seed/daily_words_seed.sql` (same ordering ⇒ offline and online agree), and
`supabase/seed/challenge_words_seed.sql` (2,000 duel words, **disjoint from answers.txt**
so a duel can never spoil a future daily — regenerate both together).
The MustafaLinux list was evaluated and **rejected** (morphologically generated junk —
would accept nearly anything as "a word"). Sources kept: Hugo0/wordle + hermitdave
FrequencyWords, both MIT.

## Supabase (LIVE since 2026-08-26)

- The project exists and is fully set up: migrations 0001–0003 + the seed ran in the
  dashboard, **Anonymous sign-ins** and **Manual linking** are enabled. Verified live:
  anonymous sign-in works, `get_daily_word()` executes (empty pre-epoch = correct,
  bundled fallback covers it until 2026-09-01), and a direct `daily_words` read returns
  zero rows (RLS lockdown holds).
- Config: project URL + anon (publishable) key live in `env/dev.json` (committed —
  publishable by design), passed via `--dart-define-from-file=env/dev.json` on run/build.
  Do NOT hardcode them as defaults in `lib/backend/supabase_config.dart` — the test
  suite requires `flutter test` (no defines) to stay unconfigured/offline; hardcoding
  broke 9 tests once already. Without the flag the app runs fully offline.
  Everything online-related renders/activates only when `isSupabaseConfigured`.
- Still missing for social sign-in: Google Cloud web+Android client IDs and the Apple
  Services ID (see Auth below) — the Google/Apple buttons error until then; guest and
  the leaderboard work with just `env/dev.json`.
- Design: `daily_words` has RLS on with zero policies (client-unreadable); the only read
  path is `get_daily_word()` (security definer, Riyadh "today", never future words).
  `submit_result()` stamps uid server-side, allows ≤7-day backfill (`live=false`, excluded
  from the daily leaderboard), idempotent via `unique(user_id, word_date)`.
- Auth (M4): anonymous-first; `AuthRepository.linkGoogle/linkApple` use
  `linkIdentityWithIdToken` (google_sign_in **v7** `initialize/authenticate` API — ignore
  v6 tutorials). "Identity already linked elsewhere" holds the credential and returns
  `alreadyLinkedElsewhere`; the profile's «حفظ التقدم» confirms before `confirmSwitch()`,
  but the **first-run sign-in screen auto-switches** (no device progress to protect).
  Google needs the **web** client ID as `serverClientId` and in Supabase's Authorized
  Client IDs (`--dart-define=GOOGLE_WEB_CLIENT_ID=…`); Apple on Android needs a Services
  ID (`--dart-define=APPLE_SERVICE_ID=…`) with the Supabase callback URL.
- First-run flow (M5): sign-in/name screens appear only when configured AND the local
  `onboarded` flag is unset; guest path never touches the network. Sign-out →
  `auth.signOut()`, board + cached name + flag cleared, back to sign-in; stats stay.
  Display name is cached locally (`display_name`) so the profile renders offline;
  server `profiles` is best-effort synced on link/edit.

## Duels «التحدّيات» (M6)

- Friend-first: every profile carries a permanent **٦-digit `friend_code`** (minted by the
  signup trigger, backfilled in 0004). «إضافة صديق» → request → قبول, then duels are created
  against a friend id. There is no join link and no deep-link config.
- Migrations **0004_challenges.sql** (schema, RLS, Realtime publication) + **0005_challenge_functions.sql**
  (RPCs), then `supabase/seed/challenge_words_seed.sql`. Same discipline as 0003: tables are
  RPC-only, `auth.uid()` is stamped server-side, results are write-once.
- **`profiles` is no longer world-readable** — 0004 drops the `"profiles read"` policy in favour
  of read-own, so friend codes can't be harvested. Every cross-user name now comes from a
  security-definer RPC (leaderboards included).
- The winner rule lives twice, on purpose: `submit_challenge_result()` decides it server-side,
  `decideOutcome()` in `challenge/models.dart` renders/predicts it. **Change one, change both**
  (win beats loss → fewer guesses → faster solve; an unknown clock sorts last).
- Live progress rides `postgres_changes` on `challenge_participants` (in the `supabase_realtime`
  publication, with a participants-only select policy — Realtime honours RLS). The pill lands in
  the existing badge slot; there is no new chrome.
- The solve clock starts on the **first letter typed**, is persisted with the first submitted
  guess, and survives a kill. As a side effect the daily game now fills `game_results.duration_ms`,
  which had always been null.
- Anti-cheat is deliberately shallow: the engine is client-side, so the word is readable by a
  determined player (already true of the daily game). The RPCs only close the cheap holes.

### Account deletion (0007, written 2026-09-05 — run it before TestFlight)

`supabase/migrations/0007_delete_account.sql` adds `delete_account()`: security definer, deletes
`auth.users where id = auth.uid()`. Every user-keyed table cascades (profiles + friend code,
game_results, friendships, challenges as creator/opponent, challenge_participants);
`challenges.winner_id` is `set null`, so a finished duel the opponent still lists survives without
its winner mark. Callable by `authenticated` only. Until it has been run in the SQL editor,
«حذف الحساب» in the app ends in «تعذّر حذف الحساب» and changes nothing.

## Gotchas that already cost time (don't rediscover)

1. **Widget tests + real asset I/O deadlock**: `rootBundle` loads inside `testWidgets`
   hang under fake-async. Load heavy assets in `setUpAll` / wrap I/O in `tester.runAsync`
   (see `test/widget/rtl_smoke_test.dart`).
2. **adb from Git Bash**: `/sdcard/...` gets path-mangled — use `MSYS_NO_PATHCONV=1` and a
   Windows-style destination for `adb pull`. PowerShell `>` corrupts binary screencap output.
3. Flip face-swap happens at the **eased** halfway point (`Motion.easeInOut`), matching the
   reveal timing constants in `game/state/word_game.dart` — change one, change both.
4. Key inset lip: Flutter has no inset BoxShadow — it's a bottom-aligned 2 px strip in
   `key_cap.dart`.
5. Icon regeneration: `flutter test tool/generate_icon.dart` then
   `dart run flutter_launcher_icons` (config in pubspec).
6. Today (Aug 2026) is **pre-epoch**, so every day is puzzle ١ / answer `عندما`
   (answers[0]) until 2026-09-01 — handy for deterministic manual testing.
7. `Supabase.instance` **throws** when unconfigured — never call
   `SupabaseService.client` outside an `isSupabaseConfigured` guard.
   `AuthRepository.currentUser`/`signOut()` are already guarded (dev builds reach them
   via the profile's edit-name path).
8. flutter_local_notifications **v22** uses all-named parameters
   (`initialize(settings:…)`, `zonedSchedule(id:…, scheduledDate:…)`,
   `cancel(id:…)`) and flutter_timezone v5 returns a `TimezoneInfo` (use
   `.identifier`) — most tutorials show the older positional APIs.
9. A duel board is a *session*, not a family: `activeChallengeProvider` holds the open duel and
   `ChallengeGameController` reads it in `build()`. Opening another duel calls
   `.open(detail)`, which invalidates `challengeGameProvider` — never read that provider
   while the active challenge is null.
10. PL/pgSQL shadowing: a `RETURNS TABLE` column name shadows a real table column of the
   same name inside the body. `create_challenge` therefore returns `challenge_id` /
   `challenge_word`, not `id` / `word` — the Dart repository reads those exact keys.
11. Pinned-bottom onboarding layout: `IntrinsicHeight` + `Spacer` inside a scroll view
   miscomputes and overflows; `auth_shell.dart` uses
   `ConstrainedBox(minHeight) > Column(mainAxisAlignment: spaceBetween)` instead.
12. An RLS policy that subqueries a zero-policy table (like `challenges`) silently
   evaluates to false for everyone — the subquery is itself under RLS when run as the
   querying role. This broke Realtime delivery for the duel pill (0004, fixed in 0006).
   Membership checks used inside policies must go through a **security-definer helper**
   (`is_challenge_participant`, `are_friends`), never a raw subquery on an RPC-only table.
13. `Tile`'s reveal/wave staggers are `Future.delayed` timers, which `pumpAndSettle`
   does NOT flush — a widget test that mounts a flipping sample row (sign-in,
   challenges empty state, help dialog) and ends early fails with "Timer still
   pending". Fix in the harness, not the widget: motion-off prefs
   (`'settings': '{"…","motion":false}'`) plus `MotionScope(enabled: false)` via
   `MaterialApp.builder` when the harness doesn't boot the full app.
14. The tile pop's overshoot half dips *below* scale 1 (`easePop` crosses 1, making
   `sin(πt)` negative) — assert pop scales at ~60ms after the trigger, near the peak,
   never at ~110ms (the crossover reads exactly 1.0). Also budget two pumps: one for
   the zero-delay timer, one for the first ticker tick.
15. The fixed puzzle-١ test fixture broke the whole suite the day the epoch passed —
   date-sensitive fixtures must be pinned to *today* (`dateOnly(DateTime.now())` +
   `puzzleNumberFor`), or SyncService's offline rollover swaps the word mid-test.
16. **Bundle IDs are global.** `com.kalimat.app` archived fine but failed at signing with
   "cannot be registered to your development team because it is not available" — another
   Apple team already owns it. Renamed to `com.kalimat.game` (both platforms). Nothing local
   can tell you an ID is taken; only the first `flutter build ipa` does.
17. `codesign -d` on `build/ios/archive/Runner.xcarchive/…/Runner.app` shows *Apple
   Development* + `get-task-allow`, which looks wrong but isn't — the archive is
   development-signed and the export step re-signs. Verify distribution signing on the
   **IPA payload** (`unzip kalimat.ipa` → `Payload/Runner.app`) or in
   `build/ios/ipa/DistributionSummary.plist`.

## Plans & docs

Plan files live in `~/.claude/plans/` **on the Windows box only** — they do not travel
with the repo. Everything needed to continue is in this file + STATUS.md + `design/`.

- Approved plan (M0–M4): `~/.claude/plans/i-want-to-create-velvety-falcon.md`
- Full architecture detail (SQL rationale, console checklists §11, risks §12):
  `~/.claude/plans/i-want-to-create-velvety-falcon-agent-a12e92ece1086fc6e.md`
- Approved plan (M5 user flow): `~/.claude/plans/read-the-handoff-file-abundant-crab.md`
- Approved plan (rise transitions + ui-inspo agent):
  `~/.claude/plans/now-the-thing-is-hazy-castle.md`
- Approved plan (M6 duels «التحدّيات»):
  `~/.claude/plans/read-the-handoff-file-vectorized-simon.md` — written on the Mac, so it
  is the one plan file the Windows box does not have
- Design reference: `design/readme.md`, `design/guidelines/*.card.html`, and the
  user-flow spec `design/design_handoff_kalimat_user_flow/README.md` (exact per-screen
  values; its email-OTP screens are intentionally not implemented)

## Figma design file (built 2026-09-03, lives outside the repo)

Every screen, dialog and state of the shipped app was recreated as native Figma
components in the user's file **kalimatDesign** —
https://www.figma.com/design/efNNJSRK9FX3O0gFjHwxza/kalimatDesign — so a redesign can be
explored there without touching `lib/`. **Nothing from it is committed here**; the
source of truth for the file was `lib/` + `design/tokens/*.css`, not the other way round.

- **Pages** (Starter plan caps a file at 3): *Components* — a Read-me card, a
  Foundations section (every colour token light/dark with hex + CSS name, the type ramp),
  variable collections `Primitives` / `Color · Light` / `Color · Dark` / `Spacing` /
  `Radius` (WEB code syntax = the CSS custom property), 23 text styles, 9 effect styles,
  17 Lucide icon components and 19 component sets (Tile, KeyCap, Button, Pill, Toast,
  Avatar, StatCard, SegmentToggle, Switch, ListRow, Input, IconButton, ScreenHeader,
  AppHeader, Keyboard, Board, SectionCard and Dialog — the last two use slots).
  *Screens* — 38 frames at 390×844 in sections Onboarding · Game · Dialogs · Profile ·
  Challenges · Duel · Dark, all composed from instances with real state overrides
  (board rows, key hints, switches, pills) and the exact MSA copy from `strings.dart`.
- **Fonts are substituted.** Figma's cloud fonts have no Noto Kufi Arabic / IBM Plex
  Sans Arabic, so `display/*` styles use **Cairo** and `ui/*` styles use **Noto Sans
  Arabic**. Every text layer carries a text style, so restoring the real typefaces is one
  family change per style — install `assets/fonts/*.ttf` on the Mac and open the file in
  the Figma desktop app first (the cloud font list won't see local fonts).
- **Dark mode is two collections, not modes** — Starter allows one mode per collection.
  `Color · Light` and `Color · Dark` share variable names; the *Dark* section holds
  clones whose paints were rebound name-for-name (635 paints, 15 shadow styles). On a Pro
  plan the two can be merged into one collection with Light/Dark modes.
- **Known faithful wart**: keyboard row 3 is cramped at 390 px because `إدخال`/`حذف`
  are fixed 62 px (`game/widgets/keyboard.dart`), leaving ~17 px per letter key — a
  redesign candidate, not a Figma bug.
- **Tooling**: the official Figma MCP plugin (`claude plugin install
  figma@claude-plugins-official`, then `claude mcp login "plugin:figma:figma"` from a
  normal Terminal window — the in-session `/mcp` flow can't complete OAuth). The account
  is a **Starter / View seat ⇒ ~20 MCP tool calls per month**; the build used ~17, so
  further MCP edits may be rate-limited until the month rolls over or the seat is
  upgraded. Batch `use_figma` scripts heavily (one screen per call, idempotent by node
  name, inline `node.screenshot()` instead of `get_screenshot`). The build scripts were
  session-scratch and are not kept; the Read-me card in the file documents the
  structure well enough to extend by hand or by script.

## Claude Design canvas (built 2026-09-04, lives outside the repo)

The Figma file above hit three walls for a redesign pass (≈20 MCP calls a month, substituted
fonts, no dark mode on Starter). So every screen was rebuilt a second time as a **Claude Design
canvas** — Claude Code's `/design` skill, published as a private Artifact — and that is now the
place to explore a redesign. The Figma file stays as the component/variable reference.

**«Kalimat Screens»** (🟫): https://claude.ai/code/artifact/bd5efe88-9526-47a7-9af6-e2560c8361ac

- **What is on it**: 110 static 390×844 frames on 12 pages — *Onboarding · Game · Dialogs ·
  Profile · Challenges · Duel*, then the same six again as *Dark · …*. Every screen, dialog and
  state of the shipped app, 55 per theme: splash, sign-in idle/busy/error, name screen empty/typing,
  the board empty/mid-play/both toasts/won/lost/hints-off/offline, help + the first-run greeting,
  stats in-progress/won/lost, the leaderboard in today/all-time/loading/empty/error, profile
  guest/linked/offline/link-failed, edit-name, switch-account, reminder on/off, the duels tab
  empty/loading/populated/create-failed, the friends tab populated/empty/loading/error/code-copied,
  add-friend (typing/not-found/already-friends), pick-friend, remove-friend, the duel board
  (not started/live progress/score to beat/loading/failed) and all four result cards. It opens on
  Onboarding; the other pages are in the canvas toolbar's pages menu. Scrolling screens (the
  profiles, the populated duel list) use taller frames so the whole page is visible.
- **Source of truth was `lib/` + `design/tokens/*.css`, not Figma**: colours (light AND the
  official dark mapping), the type ramp, spacing, radii, shadows, keyboard rows and every string in
  `strings.dart` were lifted verbatim. Fonts are the real Noto Kufi Arabic / IBM Plex Sans Arabic
  via Google Fonts — nothing is substituted. Icons are the same Lucide set, drawn as stroke SVG.
- **Sample data**: player ليلى, puzzle ٤, answer مدرسة, opponent نورة, friends سارة / عمر / خالد,
  a pending request from هند, friend code ٤٨٢٩١٧, stats ٤٢ played · ٨٩٪ · streak ٧ · best ١٢.
- **Known approximations**: the two stock Material snackbars («تم نسخ الرمز», «تعذّر إنشاء
  التحدي») — their colours come from `ColorScheme.fromSeed`, not the token set. Everything else is
  token-exact and was reviewed frame-by-frame against `lib/` (format, tokens, copy incl. diacritics,
  Arabic-Indic digits, RTL placement, keyboard rows). Layout was verified by reading the markup, not
  by rendering: headless Brave/Chrome does not run on this Mac (sandbox + CVDisplayLink), so if a
  frame looks off on screen, name it and it gets fixed.
- **Nothing from it is committed.** The frames came from a throwaway Node generator (`gen.mjs` —
  shared component functions emitting one `.dc.html` per frame plus `canvas.json`) in a session
  scratch dir that is gone with the job. The canvas itself is the durable copy: to change it later,
  read the artifact from Claude Code, `seed-canvas.mjs --extract` the saved page into a fresh
  directory, edit the extracted frames, re-seed, and republish to the **same URL** with
  `contract: "0.1.31"` and no `capabilities` (the `/design` skill spells out each step). Edits made
  by hand in the canvas editor persist only after **Save**; every Save is a new version that all
  open views reload to, so it is a one-editor-at-a-time document.
- **Intended loop**: duplicate a frame on the canvas, change it by hand or by asking, and once a
  direction wins port it straight into `lib/` (tokens in `core/theme/` first, then widgets) — never
  back through Figma.

## App Store release (iOS) — set up 2026-09-05

The paid Apple Developer membership arrived on 2026-09-05 and the project was made
submittable the same day. What is in the repo, and what the store side still needs:

**Signing & project** (`ios/`)
- Team **W62CSC2R8A** ("Turki Alotaibi") — the Apple ID `turkialotibi.0@icloud.com` in Xcode.
  `DEVELOPMENT_TEAM` is set on all three Runner configurations and in the project's
  `TargetAttributes`; signing is **automatic**. The first archive renewed the expired
  development certificate, registered the App ID and minted the distribution profile without a
  single prompt — no manual work in the portal was needed.
- `Runner.entitlements` carries **Sign in with Apple** (`com.apple.developer.applesignin`),
  wired via `CODE_SIGN_ENTITLEMENTS`; the capability is also declared in `SystemCapabilities`.
- `Info.plist`: `CFBundleDisplayName` = **كلمات**, `CFBundleDevelopmentRegion` = `ar`,
  `CFBundleLocalizations` = [ar], **portrait only**, `ITSAppUsesNonExemptEncryption = NO`
  (HTTPS only — skips the export-compliance prompt on every upload).
- **iPhone only** (`TARGETED_DEVICE_FAMILY = 1`): no iPad screenshots, no iPad layout review;
  iPads run it in compatibility mode.
- `PrivacyInfo.xcprivacy` (in the Resources phase) declares the four collected data types
  (user ID, name, email, gameplay content — all linked, none tracking) and the UserDefaults
  required-reason API (CA92.1, via shared_preferences). Keep it in step with the App Privacy
  answers in `store/listing.md`.
- `ios/ExportOptions.plist`: `app-store-connect`, automatic, symbols uploaded.
- Flutter's validator warns that `LaunchImage` is the 1×1 template placeholder. Deliberate:
  the launch storyboard is a flat brown-600 ground (M7e) and the image is invisible. Cosmetic.

**Build & upload**
```
flutter build ipa --release --dart-define-from-file=env/dev.json \
  --export-options-plist=ios/ExportOptions.plist
# → build/ios/ipa/kalimat.ipa (≈24 MB); archive ≈107 s + export ≈67 s on the MacBook
```
Upload with the **Transporter** app (drag the .ipa) or Xcode → Organizer → Distribute. The
Supabase defines must be on the build line — without `env/dev.json` the store build would be
the offline dev build. Google is still unconfigured: `kGoogleSignInAvailable` hides the
button, so the shipped sign-in screen is Apple + guest. When Google credentials exist, the iOS
side also needs `GIDClientID` and a reversed-client-ID URL scheme in `Info.plist` (google_sign_in_ios
requirement) in addition to `--dart-define=GOOGLE_WEB_CLIENT_ID=…`.

**Screenshots** — `store/screenshots/*.png`, 1320×2868 (6.9-inch, the one size Apple requires)
- A dedicated simulator **«Kalimat Screens»** (iPhone 17 Pro Max, iOS 26.5).
- `integration_test/screenshots_test.dart` seeds an in-memory LocalStore per frame (player ليلى,
  answer مدرسة, the canvas's sample stats) and pumps the real app unconfigured; each
  `binding.takeScreenshot()` is captured on the device and written by
  `test_driver/integration_test.dart` after the run. The frames are the full Flutter view —
  the status-bar strip shows the app's own background, no clock/battery (Apple doesn't require
  one). Not part of `flutter test` (integration tests need a device). ~30 s once the debug
  build is cached.
```
udid=$(xcrun simctl list devices | grep 'Kalimat Screens' | grep -oE '[0-9A-F-]{36}')
xcrun simctl boot $udid
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots_test.dart -d $udid
```
- **Gotcha (cost one run):** the extended driver's `onScreenshot` callback is *post-hoc* — it
  receives all captures after the last test — so shelling out to `simctl io screenshot` from it
  for status-bar shots yields six copies of the final screen. Live host-side capture would need
  a flutter_driver-style app entry (`enableFlutterDriverExtension`) driven step by step.

**Store copy & legal** — `store/`
- `listing.md`: name/subtitle/description/keywords/what's-new in MSA, category, App Privacy
  answers, age-rating answers, reviewer notes, and the pre-submit checklist.
- `privacy.html` + `support.html`: self-contained RTL pages, light + dark, ready to host
  anywhere static (GitHub Pages needs a **public** repo on a free plan — this one is private).
  Both carry a `[SUPPORT_EMAIL]` placeholder to fill before hosting. App Review 5.1.1(i) also
  wants the policy reachable **inside** the app: once the URL exists, make the sign-in legal
  line and the profile footer open it (`url_launcher`, ~15 min) — not done yet because there
  is no URL to point at.

**Still on the store side (needs the account owner)**: create the app record in App Store
Connect under `com.kalimat.game`, paste `listing.md`, host the two pages and paste their URLs,
upload the IPA, run `0007_delete_account.sql`, and turn on the Apple provider in Supabase with
`com.kalimat.game` in its Client IDs. STATUS.md keeps the live checklist.

## Claude Code extras (travel with the repo)

- `.claude/agents/ui-inspo.md` — research-only agent: web-searches UI/motion
  inspiration for a topic, filters it through the design doctrine, writes a report to
  `design/inspo/<topic>.md`. Never edits app code. Invoke via "use the ui-inspo agent
  to research <topic>".
- `.claude/commands/security-review.md` + `.github/workflows/security.yml` — the
  Anthropic security reviewer, set up then parked. The workflow only fires on PRs and
  needs a `CLAUDE_API_KEY` repo secret; both are dormant and safe to ignore or delete.
