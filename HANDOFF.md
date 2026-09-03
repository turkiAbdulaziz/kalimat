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

**App identity (both platforms)**: `com.kalimat.app` (Android namespace/MainActivity
remain `com.kalimat.kalimat` — fine, applicationId ≠ package). Android minSdk 24;
core-library desugaring is ON in `android/app/build.gradle.kts` (required by
flutter_local_notifications — don't remove).

```powershell
flutter test                 # 103 tests (engine + data + state + widget + flow), all green — MUST run unconfigured
flutter analyze              # clean
flutter run --dart-define-from-file=env/dev.json    # online build (Supabase creds live in env/dev.json)
# Windows/Android:
flutter build apk --debug --dart-define-from-file=env/dev.json
adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s emulator-5554 shell am start -n com.kalimat.app/com.kalimat.kalimat.MainActivity
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
| `flow/` | `flow_controller.dart` (`FlowStep` signin/name/game + `flowProvider`; gating: unconfigured or `onboarded` → straight to game, existing installs migrate silently; also `displayNameProvider`, sign-out clears board+identity but **keeps stats**), `root_flow.dart` (`home:` widget — kalimat-rise switch between steps: incoming screen fades in + rises 8px over `Motion.base`, outgoing fades in place; instant when «حركة المربعات» is off). |
| `onboarding/` | `auth_shell.dart` (centred column, pinned bottom block), `sign_in_screen.dart` (Google/Apple/guest; inline taupe error line — new screens have no ToastSlot), `name_screen.dart`. |
| `profile/` | `profile_screen.dart` («حسابي», pushed with the shared rise route (`core/rise_route.dart` — sink+fade on close, instant removal on sign-out); board state survives because it lives in providers), `edit_name_dialog.dart` (tap the name), `save_progress_section.dart` (anonymous-only linking, moved from the old settings dialog, keeps the confirm-switch dialog), `reminder_dialog.dart` (١٢-hour steppers + ص/م). |
| `challenge/` | Duels «التحدّيات». `models.dart` (pure Dart: `ChallengeSide/Summary/Detail`, `Friend`, and `decideOutcome` — the winner rule, kept in lockstep with the SQL), `challenge_controller.dart` (`activeChallengeProvider` + `challengeGameProvider` + `opponentSideProvider`; one duel at a time, so no family), `challenges_screen.dart` (segmented shell) → `challenges_tab.dart` / `friends_tab.dart`, `challenge_screen.dart` (the duel board), `challenge_result_dialog.dart`, plus the add-friend / pick-friend / remove-friend dialogs. |
| `notifications/` | `notification_service.dart` (flutter_local_notifications v22 + timezone; **inexact** daily schedule — no exact-alarm permission; `supported` guard keeps it off web/desktop/tests), `reminder_controller.dart` (permission → schedule/cancel → persist). Manifest has the two receivers + POST_NOTIFICATIONS/BOOT_COMPLETED. |
| `backend/` | Supabase layer, **entirely dormant until configured** — see below. `sync_service.dart` runs on launch + app-resume: ensure anon session → fetch day word (server Riyadh calendar is authority) → bundled fallback on offline rollover → flush result queue. `challenge_repository.dart` / `friends_repository.dart` wrap the duel + friend RPCs and own the Realtime channel for opponent progress. |

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

## Claude Code extras (travel with the repo)

- `.claude/agents/ui-inspo.md` — research-only agent: web-searches UI/motion
  inspiration for a topic, filters it through the design doctrine, writes a report to
  `design/inspo/<topic>.md`. Never edits app code. Invoke via "use the ui-inspo agent
  to research <topic>".
- `.claude/commands/security-review.md` + `.github/workflows/security.yml` — the
  Anthropic security reviewer, set up then parked. The workflow only fires on PRs and
  needs a `CLAUDE_API_KEY` repo secret; both are dormant and safe to ignore or delete.
