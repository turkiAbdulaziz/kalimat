# كلمات (Kalimat) — Developer Handoff

Arabic Wordle-style daily word game. Flutter (Android + iOS ship targets), Supabase backend.
This file orients anyone (or any future session) picking the project up cold.
For *what's done and what's next*, see [STATUS.md](STATUS.md).

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
only via the header avatar (stats, preferences, daily reminder, sign-out).

## Environment & toolchain

- Windows 11 dev box, Flutter **3.47.1** stable / Dart 3.13.1, Android SDK present.
- **No Visual Studio C++ toolchain** → the `windows` target does NOT build here.
  Verify on the Android emulator (AVD `Pixel_6`; address it as `adb -s emulator-5554`,
  a stale `emulator-5562 offline` entry sometimes lingers) or Chrome.
- Windows Developer Mode must stay ON (Flutter plugin symlinks).
- App id: `com.kalimat.app` (namespace/MainActivity remain `com.kalimat.kalimat` — fine,
  applicationId ≠ package). minSdk 24. Core-library desugaring is ON in
  `android/app/build.gradle.kts` (required by flutter_local_notifications — don't remove).
- Repo lives inside OneDrive (user accepted build churn; `build/`/`.dart_tool/` are
  git-ignored but still sync).

```powershell
flutter test                 # 103 tests (engine + data + state + widget + flow), all green — MUST run unconfigured
flutter analyze              # clean
flutter run --dart-define-from-file=env/dev.json    # online build (Supabase creds live in env/dev.json)
flutter build apk --debug --dart-define-from-file=env/dev.json
adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s emulator-5554 shell am start -n com.kalimat.app/com.kalimat.kalimat.MainActivity
```

## Code map (`lib/`)

| Path | What lives there |
|---|---|
| `core/strings.dart` | Every piece of MSA copy. Single locale, no i18n framework. |
| `core/theme/` | `kalimat_colors.dart` (brown ramp + `KalimatColors` ThemeExtension, light + **official** dark mapping from the handoff's colors.css, incl. `textWordmark`/`textOnSoft`/`textDanger` and theme-aware shadows — `c.shadowSm/Md/Lg`, instance fields, not statics), `kalimat_theme.dart` (TextThemes — **letterSpacing is always 0** for Arabic), `metrics.dart` (tile 58 / key 52 / max width 500…), `motion.dart` (durations + cubics). |
| `core/utils/arabic_digits.dart` | ٠-٩ conversion + ٪. All UI numbers go through this. |
| `game/engine/` | **Pure Dart, zero Flutter imports, fully unit-tested.** `letters.dart` (33-key rows + `normalizeLetter/Word`), `evaluate.dart` (duplicate-safe two-pass on normalized forms), `keyboard_state.dart` (upgrade-only hints keyed by canonical class — this is why أ/إ/ا color together), `puzzle_calendar.dart` (**epoch 2026-09-01 = puzzle ١**), `share_grid.dart` (RLM-prefixed 🟫🟨⬜ rows). |
| `game/data/` | `dictionary.dart` (18.3k normalized guess set), `bundled_word_source.dart` (offline answers, same ordering as the server seed), `local_store.dart` (SharedPreferences JSON: cached word, board, **stats — local is authoritative**, settings, pending-results queue, `onboarded` flag, cached `display_name`, reminder settings). |
| `game/state/` | Riverpod Notifiers. `game_controller.dart` is the game loop: typing, validation, reveal choreography (flip 900 ms = 420 + 4×120 stagger), win/loss sequencing, persistence, `applyServerWord` (never interrupts a game in progress). |
| `game/widgets/`, `game/dialogs/`, `game_screen.dart` | The UI. Widgets are dumb/props-only (shared set incl. `KalimatAvatar`, `KalimatInput`, `KalimatListRow`, `Wordmark`). Dialogs via `showKalimatDialog` (brown overlay + 2 px blur + rise); there is **no settings dialog** — preferences live on the profile screen, and the header's trailing avatar (not a gear) opens it. The game screen never scrolls; tiles shrink first on small screens. |
| `flow/` | `flow_controller.dart` (`FlowStep` signin/name/game + `flowProvider`; gating: unconfigured or `onboarded` → straight to game, existing installs migrate silently; also `displayNameProvider`, sign-out clears board+identity but **keeps stats**), `root_flow.dart` (`home:` widget — kalimat-rise switch between steps: incoming screen fades in + rises 8px over `Motion.base`, outgoing fades in place; instant when «حركة المربعات» is off). |
| `onboarding/` | `auth_shell.dart` (centred column, pinned bottom block), `sign_in_screen.dart` (Google/Apple/guest; inline taupe error line — new screens have no ToastSlot), `name_screen.dart`. |
| `profile/` | `profile_screen.dart` («حسابي», pushed with the shared rise route (`core/rise_route.dart` — sink+fade on close, instant removal on sign-out); board state survives because it lives in providers), `edit_name_dialog.dart` (tap the name), `save_progress_section.dart` (anonymous-only linking, moved from the old settings dialog, keeps the confirm-switch dialog), `reminder_dialog.dart` (١٢-hour steppers + ص/م). |
| `notifications/` | `notification_service.dart` (flutter_local_notifications v22 + timezone; **inexact** daily schedule — no exact-alarm permission; `supported` guard keeps it off web/desktop/tests), `reminder_controller.dart` (permission → schedule/cancel → persist). Manifest has the two receivers + POST_NOTIFICATIONS/BOOT_COMPLETED. |
| `backend/` | Supabase layer, **entirely dormant until configured** — see below. `sync_service.dart` runs on launch + app-resume: ensure anon session → fetch day word (server Riyadh calendar is authority) → bundled fallback on offline rollover → flush result queue. |

Layering rule: `backend/` imports `game/`, never the reverse. UI touches backend only
through the providers in `backend_providers.dart`/`sync_service.dart` (game_screen, the
stats dialog's leaderboard tab, and the flow/onboarding/profile layer).

## Word-list pipeline

`dart run tool/build_wordlists.dart` (raw inputs in git-ignored `tool/raw/`, download URLs
in the file header). Emits `assets/words/dictionary.txt`, `tool/out/answers_candidates.txt`
(11,251 frequency-ranked candidates with clitic flags AL/W/F/B/L/SUF), a **provisional**
`assets/words/answers.txt` (only when missing — it will not clobber a curated list), and
`supabase/seed/daily_words_seed.sql` (same ordering ⇒ offline and online agree).
The MustafaLinux list was evaluated and **rejected** (morphologically generated junk —
would accept nearly anything as "a word"). Sources kept: Hugo0/wordle + hermitdave
FrequencyWords, both MIT.

## Supabase (code ready, project not yet created)

- Config: project URL + anon (publishable) key live in `env/dev.json`, passed via
  `--dart-define-from-file=env/dev.json` on run/build. Do NOT hardcode them as
  defaults in `lib/backend/supabase_config.dart` — the test suite requires
  `flutter test` (no defines) to stay unconfigured/offline.
  Everything online-related renders/activates only when `isSupabaseConfigured`.
- Set up: run `supabase/migrations/0001..0003.sql` then `supabase/seed/daily_words_seed.sql`
  in the dashboard SQL editor; toggle **Anonymous sign-ins** + **Manual linking** in Auth.
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

## Gotchas that already cost time (don't rediscover)

1. **Widget tests + real asset I/O deadlock**: `rootBundle` loads inside `testWidgets`
   hang under fake-async. Load heavy assets in `setUpAll` / wrap I/O in `tester.runAsync`
   (see `test/widget/rtl_smoke_test.dart`).
2. **adb from Git Bash**: `/sdcard/...` gets path-mangled — use `MSYS_NO_PATHCONV=1` and a
   Windows-style destination for `adb pull`. PowerShell `>` corrupts binary screencap output.
3. Flip face-swap happens at the **eased** halfway point (`Motion.easeInOut`), matching the
   reveal timing constants in `game_controller.dart` — change one, change both.
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
9. Pinned-bottom onboarding layout: `IntrinsicHeight` + `Spacer` inside a scroll view
   miscomputes and overflows; `auth_shell.dart` uses
   `ConstrainedBox(minHeight) > Column(mainAxisAlignment: spaceBetween)` instead.

## Plans & docs

- Approved plan (M0–M4): `~/.claude/plans/i-want-to-create-velvety-falcon.md`
- Full architecture detail (SQL rationale, console checklists §11, risks §12):
  `~/.claude/plans/i-want-to-create-velvety-falcon-agent-a12e92ece1086fc6e.md`
- Approved plan (M5 user flow): `~/.claude/plans/read-the-handoff-file-abundant-crab.md`
- Design reference: `design/readme.md`, `design/guidelines/*.card.html`, and the
  user-flow spec `design/design_handoff_kalimat_user_flow/README.md` (exact per-screen
  values; its email-OTP screens are intentionally not implemented)
