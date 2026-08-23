# كلمات (Kalimat) — Developer Handoff

Arabic Wordle-style daily word game. Flutter (Android + iOS ship targets), Supabase backend.
This file orients anyone (or any future session) picking the project up cold.
For *what's done and what's next*, see [STATUS.md](STATUS.md).

---

## The product in one paragraph

One game surface: guess the 5-letter Arabic word of the day in 6 tries. RTL everywhere,
MSA copy, Arabic-Indic digits (٠-٩) in all UI. Lenient matching: hamza forms أ إ آ count
as ا, ة = ه, ى = ي (target-side also ؤ→و, ئ→ي); the board shows what the player typed;
the stored answer keeps correct spelling. Brown monochrome design (correct = dark brown,
present = light brown, absent = taupe) from the design system in `design/` — that folder
is the visual source of truth (tokens in `design/tokens/*.css`, reference React components,
a playable recreation in `design/ui_kits/kalimat_app/App.jsx`).

## Environment & toolchain

- Windows 11 dev box, Flutter **3.47.1** stable / Dart 3.13.1, Android SDK present.
- **No Visual Studio C++ toolchain** → the `windows` target does NOT build here.
  Verify on the Android emulator (AVD `Pixel_6`; address it as `adb -s emulator-5554`,
  a stale `emulator-5562 offline` entry sometimes lingers) or Chrome.
- Windows Developer Mode must stay ON (Flutter plugin symlinks).
- App id: `com.kalimat.app` (namespace/MainActivity remain `com.kalimat.kalimat` — fine,
  applicationId ≠ package). minSdk 24.
- Repo lives inside OneDrive (user accepted build churn; `build/`/`.dart_tool/` are
  git-ignored but still sync).

```powershell
flutter test                 # 55 tests (engine + widget), all green
flutter analyze              # clean
flutter build apk --debug
adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s emulator-5554 shell am start -n com.kalimat.app/com.kalimat.kalimat.MainActivity
```

## Code map (`lib/`)

| Path | What lives there |
|---|---|
| `core/strings.dart` | Every piece of MSA copy. Single locale, no i18n framework. |
| `core/theme/` | `kalimat_colors.dart` (brown ramp + `KalimatColors` ThemeExtension, light + proposed dark), `kalimat_theme.dart` (TextThemes — **letterSpacing is always 0** for Arabic), `metrics.dart` (tile 58 / key 52 / max width 500…), `motion.dart` (durations + cubics). |
| `core/utils/arabic_digits.dart` | ٠-٩ conversion + ٪. All UI numbers go through this. |
| `game/engine/` | **Pure Dart, zero Flutter imports, fully unit-tested.** `letters.dart` (33-key rows + `normalizeLetter/Word`), `evaluate.dart` (duplicate-safe two-pass on normalized forms), `keyboard_state.dart` (upgrade-only hints keyed by canonical class — this is why أ/إ/ا color together), `puzzle_calendar.dart` (**epoch 2026-09-01 = puzzle ١**), `share_grid.dart` (RLM-prefixed 🟫🟨⬜ rows). |
| `game/data/` | `dictionary.dart` (18.3k normalized guess set), `bundled_word_source.dart` (offline answers, same ordering as the server seed), `local_store.dart` (SharedPreferences JSON: cached word, board, **stats — local is authoritative**, settings, pending-results queue). |
| `game/state/` | Riverpod Notifiers. `game_controller.dart` is the game loop: typing, validation, reveal choreography (flip 900 ms = 420 + 4×120 stagger), win/loss sequencing, persistence, `applyServerWord` (never interrupts a game in progress). |
| `game/widgets/`, `game/dialogs/`, `game_screen.dart` | The UI. Widgets are dumb/props-only. Dialogs via `showKalimatDialog` (brown overlay + 2 px blur + rise). The screen never scrolls; tiles shrink first on small screens. |
| `backend/` | Supabase layer, **entirely dormant until configured** — see below. `sync_service.dart` runs on launch + app-resume: ensure anon session → fetch day word (server Riyadh calendar is authority) → bundled fallback on offline rollover → flush result queue. |

Layering rule: `backend/` imports `game/`, never the reverse (`game_screen.dart` is the
only UI file touching backend providers).

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

- Config: paste project URL + anon key into `lib/backend/supabase_config.dart`
  or pass `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`.
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
  `alreadyLinkedElsewhere`; UI confirms before `confirmSwitch()`. Google needs the **web**
  client ID as `serverClientId` and in Supabase's Authorized Client IDs
  (`--dart-define=GOOGLE_WEB_CLIENT_ID=…`); Apple on Android needs a Services ID
  (`--dart-define=APPLE_SERVICE_ID=…`) with the Supabase callback URL.

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

## Plans & docs

- Approved plan: `~/.claude/plans/i-want-to-create-velvety-falcon.md`
- Full architecture detail (SQL rationale, console checklists §11, risks §12):
  `~/.claude/plans/i-want-to-create-velvety-falcon-agent-a12e92ece1086fc6e.md`
- Design reference: `design/readme.md` and `design/guidelines/*.card.html`
