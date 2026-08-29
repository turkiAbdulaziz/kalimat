# كلمات (Kalimat) — Status & Next Steps

_Last updated: 2026-08-27. Companion to [HANDOFF.md](HANDOFF.md) (architecture, gotchas, how to run)._

## ✅ Done

### M0 — Scaffold & assets
- [x] Flutter project (android / ios / windows / web scaffolds), appId `com.kalimat.app`, minSdk 24, git repo
- [x] Fonts bundled: Noto Kufi Arabic 400/500/700/800 + IBM Plex Sans Arabic 400/500/600/700 (OFL, licenses shipped)
- [x] Word pipeline: 18,352-word guess dictionary (Hugo0 + FrequencyWords, MIT), provisional 500-answer list, Supabase seed SQL — all from one script (`tool/build_wordlists.dart`)
- [x] App icon: كلمات wordmark on brown-600, stamped for Android (incl. adaptive) + iOS

### M1 — Offline playable core  *(verified on Pixel 6 emulator)*
- [x] Pure-Dart engine: normalized lenient matching, duplicate-safe two-pass evaluation, upgrade-only keyboard hints per equivalence class, puzzle calendar (epoch 2026-09-01), share-text builder
- [x] Full RTL game UI per the design system: 6×5 grid, the design's exact 33-key keyboard + إدخال/حذف, header, day badge «كلمة اليوم», toasts
- [x] Dictionary validation («الكلمة غير موجودة» / «الكلمة قصيرة»), win/loss flow, answer reveal on loss
- [x] Local persistence: board restore after kill/relaunch ✓, stats (played / win% / streak / best / distribution), settings
- [x] 40 engine unit tests incl. duplicate-letter matrix and cross-class matches (ه↔ة, ا↔أ, ء≠أ, ؤ/ئ targets)

### M2 — Polish & motion  *(verified on emulator, incl. dark mode screenshot)*
- [x] Animations: pop 220ms on type, staggered RTL flip reveal 420ms+120ms, shake on invalid, rise for dialogs/toasts — all gated by the «حركة المربعات» setting; system reduce-animations respected as default
- [x] Help / Stats / Settings dialogs (blur overlay, warm shadows, pill buttons, custom switches)
- [x] Dark mode («الوضع الليلي», brown-900 surfaces — proposed mapping looked right on device)
- [x] Small-screen tile shrinking; hardware-keyboard input for desktop dev
- [x] 15 widget tests: keyboard layout/RTL/callbacks, tile state colors + flip face-swap, full-app smoke (boot → type → win → stats dialog)

### M3 — Supabase backend  *(code complete — dormant until credentials)*
- [x] Migrations: schema (client-unreadable `daily_words`, `profiles` + signup trigger, `game_results` with one-result-per-day constraint), RLS policies, RPCs (`get_daily_word` with Riyadh day authority, anti-abuse `submit_result`, daily + global leaderboards)
- [x] Client: anonymous-first session, server word fetch with cache + bundled fallback, pending-results upload queue (idempotent), sync on launch/resume, day-rollover handling that never interrupts a game in progress

### M4 — Sign-in & leaderboard  *(code complete — dormant until console setup)*
- [x] Google linking (google_sign_in v7 flow) and Apple linking (nonce flow; Services-ID web flow on Android) onto the anonymous user — uid and history preserved
- [x] "Account already used elsewhere" → explicit confirm dialog before switching
- [x] «المتصدرون» tab in the stats dialog (اليوم / الإجمالي) + «حفظ التقدم» section in settings with display-name editing

### M5 — Designed user flow  *(from the Claude Design handoff in `design/design_handoff_kalimat_user_flow/`; verified on Pixel 6 emulator, unconfigured build)*
- [x] First-run flow: sign-in screen (wordmark, pitch, flip-in sample row, Google/Apple/«المتابعة كزائر», legal line) → display-name screen → game; gated by `isSupabaseConfigured` + an `onboarded` flag (existing installs migrate silently, dev builds skip straight to the game)
- [x] Profile screen «حسابي» (header avatar is the only route): identity + streak badge, 4 stat cards, distribution bars, preferences (dark/hints/motion switches moved here — settings dialog and gear deleted), «مشاركة النتيجة الأخيرة», sign-out (linked users; clears board + identity, keeps local stats), «حفظ التقدم» linking section for anonymous users, tap-name editing
- [x] Design adaptation decisions: email-OTP/code screen dropped in favor of existing Google/Apple auth; leaderboard tab kept in the stats dialog (+ new «عرض حسابي» footer button); first-run help greets «أهلاً {name}»
- [x] Official dark theme mapping (15 fields corrected from the old proposal) + new tokens `textWordmark`/`textOnSoft`/`textDanger`; theme-aware shadows; wordmark dark-mode bug fixed
- [x] Daily reminder «التنبيه اليومي»: flutter_local_notifications + timezone (desugaring enabled, boot receiver), Kalimat-style enable/time dialog (١٢-hour steppers + ص/م), Android 13+ permission flow — end-to-end delivery verified on emulator
- [x] New shared widgets: KalimatAvatar, KalimatInput, KalimatListRow, Wordmark, button `large` variant; `design/` replaced with the new export (handoff README + SignIn/Game/Profile prototypes)
- [x] kalimat-rise screen transitions: RootFlow step switch + profile route share one 8px fade-rise (`core/rise_route.dart`, `Motion.base`/`easeOut`); profile close sinks, sign-out removes the route instantly; all gated by «حركة المربعات»

### iOS toolchain — builds and runs on Mac  *(verified on iPhone 17 simulator, iOS 26.5)*
- [x] Local dev environment stood up: Flutter 3.47.1 / Dart 3.13.1, Xcode 26.6, CocoaPods 1.17.0,
      Android cmdline-tools. First iOS build of the project — until now iOS was scaffold-only.
- [x] **iOS minimum raised 13.0 → 15.0** (`project.pbxproj`, all three build configs). This was not a
      choice: Flutter 3.47 enforces iOS 15.0 as its floor and rewrites the target on first iOS build,
      so 13.0 was already unbuildable. Consequence for launch: iPhone 6s / 7 / SE (1st gen) and any
      device that cannot pass iOS 15 are out of scope.
- [x] **Plugins integrate via Swift Package Manager, not CocoaPods.** Flutter 3.47 added an
      `XCLocalSwiftPackageReference` pointing at `Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`
      (gitignored, regenerated each build) plus a `Runner.xcscheme` pre-action that runs
      `xcode_backend.sh prepare`. No `Podfile` exists or is needed — don't add one back.
- [x] `Package.resolved` (committed, in both workspaces) is now the iOS dependency lock, the
      counterpart to `pubspec.lock`. It pins the transitive Google sign-in native stack:
      GoogleSignIn-iOS 9.2.0, AppAuth 2.1.0, GTMAppAuth 5.0.0, GoogleUtilities 8.1.2,
      gtm-session-fetcher 3.5.0, app-check 11.3.1, promises 2.4.1, interop-ios 101.0.0.
- [x] Boot verified on device: RTL header, 6×5 board, 33-key keyboard and the first-launch help
      dialog «أهلاً زائر» all render correctly; dark theme confirmed. Xcode build 82s, SPM resolve 81s.

### M6 — Duels «التحدّيات»  *(code complete — needs migrations 0004/0005 + the duel seed run)*
- [x] **Friend graph**: every profile carries a permanent ٦-digit `friend_code` (minted by the
      signup trigger, backfilled for existing rows). «إضافة صديق» → request → قبول/رفض, remove
      with a confirm. `profiles` is no longer world-readable — codes can't be harvested, and every
      cross-user name now comes from a security-definer RPC.
- [x] **Duels on a separate word pool**: `challenge_words` (2,000 words, disjoint from
      `answers.txt`, emitted by the same pipeline) — a duel can never spoil a future daily, and
      you can rematch as often as you like without touching «كلمة اليوم».
- [x] **Winner rule**: a win beats a loss → fewer guesses → the faster solve (unknown clock last).
      Decided server-side in `submit_challenge_result()`, mirrored client-side by `decideOutcome()`
      for rendering. Async 48h window; unplayed duels expire lazily.
- [x] **Views**: a swords icon in the header (with an accent dot for «دورك»), «التحدّيات» screen
      (duels grouped دورك / بانتظار الخصم / انتهت + friends tab with «رمزي» in board tiles), the
      duel board (same surface, the badge slot names the opponent), the result card with
      «إعادة التحدي» and a duel share line, and a «التحدّيات» section on «حسابي».
- [x] **Live progress**: Realtime `postgres_changes` on `challenge_participants` — «ليلى في المحاولة ٤»
      appears in the badge slot while your friend plays.
- [x] **Refactors that made it fit**: the game loop moved into `WordGameNotifier` (daily + duel
      sessions share it), the board became `GameSurface`, and `ScreenHeader`/`SectionCard` are now
      shared chrome. The solve clock added along the way finally populates `game_results.duration_ms`
      for the daily game too.

**Suite: 128 tests green · `flutter analyze` clean.** (engine + LocalStore
persistence + GameController use cases + duel winner-rule matrix + duel session +
rise-transition and «التحدّيات» widget tests + flow)

---

## ⏳ Waiting on you

1. ~~**Supabase project**~~ **DONE 2026-08-26** — project live, migrations + seed ran,
   Anonymous sign-ins + Manual linking on, creds in `env/dev.json`, verified end-to-end
   on the emulator (anon session, `get_daily_word()`, leaderboard tab, RLS lockdown).
2. **Answer curation** *(launch blocker, not a dev blocker — ~1–2 h)*
   Review `tool/out/answers_candidates.txt` (frequency-ranked, clitic-flagged) and build a
   curated `assets/words/answers.txt` (aim ≥365 words, correct spellings, order = puzzle
   order). Then re-run `dart run tool/build_wordlists.dart` to regenerate the server seed.
3. **Run the duel migrations** *(unblocks M6 — 5 minutes in the dashboard)*
   In the Supabase SQL editor, in order: `supabase/migrations/0004_challenges.sql`,
   `supabase/migrations/0005_challenge_functions.sql`, then
   `supabase/seed/challenge_words_seed.sql`. Nothing else changes; the app runs exactly as
   before until they are in (the duel screens simply show their empty states).
4. **Console setup for sign-in** *(unblocks M4 verification — needs your accounts)*
   Google Cloud: OAuth consent screen + **web** client ID + Android client ID (package
   `com.kalimat.app`, debug/release SHA-1s — I can generate the SHA-1s).
   Apple: paid developer account → App ID with Sign in with Apple + Services ID + `.p8` key.
   Details/checklist: companion plan §11.

## 🔜 Possible next steps (my side, once unblocked)

- **M3 verification, remaining bits**: same word on two devices, airplane-mode first
  launch playable, queue flush visible in the table editor after a finished game
  (basic connectivity, RLS lockdown, and the leaderboard path are already verified).
- **M4/M5 verification (configured)**: fresh install → sign-in screen → Google → name
  screen → game with «أهلاً {name}»; guest path; sign-out → sign-in with board cleared,
  stats kept; returning account skips the name screen; leaderboard rows live-only,
  duplicate submit no-op.
- **M6 verification (two devices)**: read A's code off «حسابي» → add on B → accept → duel →
  both boards open at once to watch the live pill → result card → rematch. Plus the edge walk:
  kill mid-duel (board + clock restore), airplane mode, an expired duel.
- **M5 release prep** (no blockers, can start anytime): release keystore + signing config,
  versioning, MSA store listing copy, Play Console internal-testing track; iOS device/TestFlight
  build — simulator builds already run locally, so what is left is a paid Apple account for
  signing plus the Sign in with Apple entitlement + Google URL scheme.

## 💡 Ideas / backlog (not planned, jot-down list)

- Real-device share test: verify the 🟫🟨⬜ share string's RTL ordering survives WhatsApp/X
  (worst case: reverse square order per line).
- Supabase free tier pauses after ~1 week idle — decide: accept until launch, or add a
  weekly keep-alive.
- Streak-preserving timezone note: daily word flips at Riyadh midnight (≈1–2 h earlier
  in the Maghreb) — confirm that's acceptable before launch.
- Onboarding polish: animate the help-dialog example row on first open.
- Launcher label is still Latin "kalimat" (AndroidManifest `android:label`) — the
  Android 13+ permission dialog shows it; consider «كلمات» before release.
- Reminder fires via inexact scheduling (no exact-alarm permission) — may land a few
  minutes late under Doze; accepted for now.
- Statistics restore from server after account switch (currently local stats stay authoritative).
- **Stranger queue + rank**: `challenges.source` and `profiles.rating` are already reserved, and
  the duel board + Realtime channel are in place; what's missing is a matchmaking RPC over a
  waiting pool and an Elo update hooked onto the outcome.
- **Push for «دورك»**: the header dot only refreshes on app open/resume. A real notification
  needs FCM/APNs, which the project has never set up (only `flutter_local_notifications`).
- Widget-test coverage for the loss path (answer reveal badge) and the leaderboard tab.
