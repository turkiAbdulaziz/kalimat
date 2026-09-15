# كلمات (Kalimat) — Status & Next Steps

_Last updated: 2026-09-15. Companion to [HANDOFF.md](HANDOFF.md) (architecture, gotchas, how to run)._

## ✅ Done

### M0 — Scaffold & assets
- [x] Flutter project (android / ios / windows / web scaffolds), appId `com.kalimat.game` (was `com.kalimat.app` until 2026-09-05 — taken on Apple's side), minSdk 24, git repo
- [x] Fonts bundled: Noto Kufi Arabic 400/500/700/800 + IBM Plex Sans Arabic 400/500/600/700 (OFL, licenses shipped)
- [x] Word pipeline: 7,918-word guess dictionary (FrequencyWords + reviewed additions), curated 365-answer daily list and separate 200-answer duel list, Supabase seed SQL — all from one script (`tool/build_wordlists.dart`)
- [x] App icon: كلمات wordmark on brown-600, stamped for Android (incl. adaptive) + iOS

### M1 — Offline playable core  *(verified on Pixel 6 emulator)*
- [x] Pure-Dart engine: normalized lenient matching, duplicate-safe two-pass evaluation, upgrade-only keyboard hints per equivalence class, puzzle calendar (epoch 2026-09-01), share-text builder
- [x] Full RTL game UI per the design system: 6×4 grid, the design's exact 33-key keyboard + إدخال/حذف, header, day badge «كلمة اليوم», toasts
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
- [x] First-run flow: sign-in screen (wordmark, pitch, flip-in sample row, official Apple control, «المتابعة كزائر» with subtle “Continue as guest · No account required” clarification, legal line) → display-name screen → game; gated by `isSupabaseConfigured` + an `onboarded` flag (existing installs migrate silently, dev builds skip straight to the game)
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
- [x] Boot verified on device: RTL header, 6×4 board, 33-key keyboard and the first-launch help
      dialog «أهلاً زائر» all render correctly; dark theme confirmed. Xcode build 82s, SPM resolve 81s.

### M6 — Duels «التحدّيات»  *(code complete — needs migrations 0004/0005 + the duel seed run)*
- [x] **Friend graph**: every profile carries a permanent ٦-digit `friend_code` (minted by the
      signup trigger, backfilled for existing rows). «إضافة صديق» → request → قبول/رفض, remove
      with a confirm. `profiles` is no longer world-readable — codes can't be harvested, and every
      cross-user name now comes from a security-definer RPC.
- [x] **Duels on a separate word pool**: `challenge_words` (200 curated words, disjoint from
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

### M7 — «حياة»: app-wide motion, haptics & celebration  *(complete, 2026-09-03)*
House rule (from `design/inspo/app-wide-motion.md`): **motion is event-driven and runs
once** — every surface speaks the four existing keyframes; no loops, no idle pulses,
no new curves. Plan: `~/.claude/plans/streamed-tickling-papert.md` (Mac).
- [x] **M7a foundations**: `MotionScope` gates the shared widgets (dialogs, toasts,
      switch travel, bars; micro-feedback ≤140ms exempt by principle); StaggeredRise /
      CountUpText / CelebrationPop primitives; HapticsService behind a new «الاهتزاز»
      setting; DistributionBar width finally grows 420ms per spec; toastVisible token
      wired; code-tile pop gate leak fixed; themed KalimatSpinner.
- [x] **M7b game peaks**: the win wave (reveal → 250ms hold → pop ripples across the
      winning row 70ms/tile, one lightImpact at its start, dialog at 1600ms; duels
      inherit it via the shared loop); loss stays neutral with the answer as filled
      tiles in the stats dialog; key-press/shake haptics; keyboard disable fades.
- [x] **M7c stats & streak**: Arabic-Indic count-ups, bars fill top-to-bottom landing
      on today's row, streak pops only when it grew, landmark streaks (٧/٣٠/١٠٠) get
      one fill beat on the win pill, profile sections stagger in, tab cross-fades,
      press feedback on name/avatar.
- [x] **M7d duels**: row entrances, the live pill pops on value change («لعبت للتو»
      as information), «دورك» dot scales in, winner line pops on the result card,
      rematch rises sequenced, friend rows fade out on accept/decline/remove.
- [x] **M7e chrome**: skeleton rows (no shimmer), leaderboard entrances, empty-state
      breath (shared SampleTileRow), sign-in busy spinner + error fade, help-dialog
      example flips in, day-rollover board cross-fade, reminder digits roll, and a
      brown-600 branded splash on both platforms (white flash gone).
- [x] **M7f sound**: scoped only — decisions in `design/sound-scope.md`, default-off
      «الصوت» setting, audioplayers, CC0 assets. Not built.

### Figma — every screen recreated for a redesign pass  *(2026-09-03, outside the repo)*
- [x] The shipped app rebuilt as a native Figma system in the user's **kalimatDesign** file
      (link + constraints in HANDOFF → "Figma design file"): 5 variable collections mirroring
      `design/tokens`, 23 text styles, 9 effect styles, 17 icons, 19 component sets, and 38
      screen frames (onboarding, game states, dialogs, profile, challenges, duel, dark).
- [x] Decisions recorded: Cairo / Noto Sans Arabic stand in for the bundled fonts (swap at
      the text-style level); light + dark are two collections because the Starter plan has
      no modes; ~17 of the plan's ~20 monthly MCP calls were spent, so more Figma-via-Claude
      work waits for the next month or a seat upgrade.
- Redesign exploration has moved to the Claude Design canvas (next section); the Figma file
      stays as the component/variable reference.

### Claude Design canvas — every screen, light + dark  *(2026-09-04, outside the repo)*
- [x] The whole app rebuilt again as a Claude Design canvas, **«Kalimat Screens»** (link, page
      list, sample data and the update procedure in HANDOFF → "Claude Design canvas"): 110 frames
      on 12 pages (six light, six dark) covering every screen, dialog and state, with the real
      Noto Kufi / IBM Plex Sans Arabic fonts and the official dark mapping — the answer to the
      Figma file's call budget, font substitution and missing dark mode.
- [x] Reviewed frame-by-frame against `lib/`: format, tokens (both themes), copy incl. diacritics,
      Arabic-Indic digits, RTL placement and keyboard rows all exact. The one approximation is the
      two stock Material snackbars, whose colours come from `ColorScheme.fromSeed`.
- [ ] Redesign exploration itself — duplicate a frame on the canvas, tweak, pick a direction, then
      port the winner into `lib/` directly.

### M8 — App Store release prep (iOS)  *(2026-09-05/06 — the paid Apple membership arrived; details in HANDOFF → "App Store release")*
- [x] **Signed App Store IPA builds**: team `W62CSC2R8A`, automatic signing, Sign in with Apple
      entitlement, iPhone-only, portrait-only, display name «كلمات», Arabic bundle region,
      `ITSAppUsesNonExemptEncryption = NO`, privacy manifest, `ios/ExportOptions.plist`.
      `flutter build ipa` → `build/ios/ipa/kalimat.ipa`, verified distribution-signed with the
      applesignin entitlement in the payload.
- [x] **Bundle ID renamed `com.kalimat.app` → `com.kalimat.game`** on both platforms: Apple had
      already issued the old one to another team (found by the first archive's signing step).
- [x] **In-app account deletion** (App Review 5.1.1(v)): `0007_delete_account.sql` RPC,
      `AuthRepository.deleteAccount()`, `FlowController.deleteAccount()` (wipes the device too —
      stats, duel boards, result queue), «حذف الحساب» danger row under sign-out with a confirm
      dialog and a failure snackbar. 4 new tests.
- [x] **Google button gated** on `GOOGLE_WEB_CLIENT_ID` (`kGoogleSignInAvailable`) on the sign-in
      screen and «حفظ التقدم»; Apple becomes the primary CTA while Google is absent — no dead
      button for the reviewer.
- [x] **App Review sign-in clarity**: the first-run Apple action now uses the official-style
      `SignInWithAppleButton` with its Apple logo, approved “Continue with Apple” title, 52px
      black/white treatment and LTR logo placement. The Arabic guest action remains primary and
      adds the muted English line “Continue as guest · No account required”. All 3 focused
      sign-in widget tests and the full 8-frame iOS integration run passed; `05-signin.png` was
      regenerated and visually reviewed.
- [x] **Store assets in `store/`**: `listing.md` (MSA copy, keywords, App Privacy + age-rating
      answers, reviewer notes, pre-submit checklist), `privacy.html`, `support.html` (RTL,
      light+dark, `[SUPPORT_EMAIL]` placeholder), eight visually reviewed 6.9-inch screenshots
      in `store/screenshots/` from the «Kalimat Screens» simulator via
      `integration_test/screenshots_test.dart`, including daily and duel light/dark boards.
- [x] **App Store Connect record** created by the account owner 2026-09-05: «كلمات»,
      `com.kalimat.game`, app ID 6809039437.
- [ ] Privacy-policy link **inside** the app (legal line + profile footer) — waits for the hosted URL.
- [ ] **First build upload — not done yet.** The Organizer attempt on 2026-09-05 failed because
      the archive's `Info.plist` had been clobbered by a verification command (HANDOFF gotcha 18,
      my mistake). A clean archive + IPA rebuilt on 2026-09-06 verified the signing/export path,
      but those artifacts predate the four-letter rollout and App Review sign-in changes. Build
      fresh artifacts from the current tree; see HANDOFF → "Build & upload" and "Waiting on you" №5.

### Cross-theme result colors  *(fixed 2026-09-15)*
- [x] Correct, present and absent fills now keep the same semantic identity in light and dark mode;
      correct stays dark brown, present light brown and absent taupe on both board tiles and keys.
- [x] Per-state foreground tokens raise every evaluated Arabic letter above 3:1 contrast; regression
      tests cover both brightnesses, board/key equality, semantic ordering and contrast.
- [x] All eight iOS screenshot fixtures regenerated and visually reviewed. The existing signed IPA
      predates this fix and must be rebuilt before upload.

**Suite: 173 tests green · `flutter analyze` clean.** (engine + LocalStore
persistence + GameController use cases + duel winner-rule matrix + duel session +
rise-transition, motion-gate/primitives, win-wave, «التحدّيات», delete-account dialog widget
tests + flow incl. account deletion)

---

## ⏳ Waiting on you

1. ~~**Supabase project**~~ **DONE 2026-08-26** — project live, migrations + seed ran,
   Anonymous sign-ins + Manual linking on, creds in `env/dev.json`, verified end-to-end
   on the emulator (anon session, `get_daily_word()`, leaderboard tab, RLS lockdown).
2. ~~**Four-letter answer curation + production rollout**~~ **DONE 2026-09-13** — 365 daily + 200 disjoint duel answers, 7,918 accepted guesses, shared pure-Dart rules and deterministic SQL generation. The account owner confirmed migrations 0007/0008 and the regenerated seeds were applied to production. See `tool/curated/README.md` and `supabase/FOUR_LETTER_ROLLOUT.md`.
3. ~~**Run the duel migrations**~~ **DONE 2026-09-03** — 0004/0005 + the duel seed are in,
   and the whole RPC surface was verified live over REST (28 checks: friend codes →
   request/accept → duel → live progress column → winner rule → draw → write-once →
   RLS lockdown, all green).
   Live verification caught a bug in 0004 (participants select policy subqueried the
   zero-policy `challenges` table, so it never passed and Realtime never delivered —
   HANDOFF gotcha 12); **0006 fixed it and ran 2026-09-03**. Re-verified after: the
   `postgres_changes` event arrives on the opponent's socket with the guess count, the
   unfinished grid stays null in the payload, and the full 28-check suite is green with
   participants able to read exactly their own duels' rows and nothing else.
4. **Console setup for sign-in** *(unblocks M4 verification — needs your accounts)*
   Google Cloud: OAuth consent screen + **web** client ID + Android client ID (package
   `com.kalimat.game`, debug/release SHA-1s — I can generate the SHA-1s) + an iOS client ID
   (`GIDClientID` + URL scheme in Info.plist). Until then the Google button stays hidden.
   Apple: ~~paid developer account → App ID with Sign in with Apple~~ **done 2026-09-05** (the
   archive registered the App ID with the capability). Still needed: the Services ID + `.p8`
   key only if you want Apple sign-in on **Android**; iOS needs neither.
5. **Ship to the App Store** *(everything code-side is done — ~1 h of console work)*
   1. **Supabase**: migrations 0007/0008 and the four-letter seeds are deployed. Authentication
      → Providers → **Apple** ON with `com.kalimat.game` in *Client IDs* (the
      secret key can stay empty for the native iOS flow).
   2. **Host** `store/privacy.html` and `store/support.html` (fill `[SUPPORT_EMAIL]` first).
      Cheapest: a small **public** GitHub repo with Pages on — the kalimat repo is private and
      free-plan Pages needs public. Then tell me the URL so the in-app legal line can link to it.
   3. **App Store Connect record** — ~~create it~~ **done 2026-09-05** («كلمات», `com.kalimat.game`,
      app ID 6809039437). Still to fill on the 1.0 page: everything from `store/listing.md`,
      `store/screenshots/*.png`, App Privacy and the age-rating questionnaire as written there,
      and the two URLs from step 2.
   4. **Build and upload the current app**: the September 6 archive/IPA is obsolete. With the
      four-letter server switch deployed, run the signed build command in HANDOFF →
      "Build & upload", then use Organizer or Transporter (or the hands-off upload export).
      Pick the build on the version page once processing finishes (~10 min). Later uploads need
      `1.0.0+2`, `+3`… in pubspec. The current signed IPA predates the 2026-09-15 color fix;
      rebuild it before upload.
   5. **TestFlight yourself first** on a real iPhone: sign in with Apple → name → play → «حسابي»
      → «حذف الحساب». Then *Submit for Review*.

## 🔜 Possible next steps (my side, once unblocked)

- **M3 verification, remaining bits**: same word on two devices, airplane-mode first
  launch playable, queue flush visible in the table editor after a finished game
  (basic connectivity, RLS lockdown, and the leaderboard path are already verified).
- **M4/M5 verification (configured)**: fresh install → sign-in screen → Google → name
  screen → game with «أهلاً {name}»; guest path; sign-out → sign-in with board cleared,
  stats kept; returning account skips the name screen; leaderboard rows live-only,
  duplicate submit no-op.
- **M6 verification (two devices)**: backend flow fully verified 2026-09-03 — two
  simulated players over REST (28 checks) plus a raw-websocket check that the Realtime
  pill event actually arrives (post-0006). Still worth the on-device pass:
  read A's code off «حسابي» → add on B → accept → duel → both boards open at once to
  watch the live pill → result card → rematch. Plus the edge walk: kill mid-duel
  (board + clock restore), airplane mode, an expired duel.
- **Android release prep** (no blockers): release keystore + signing config, Play Console
  internal-testing track, Play listing (reuse `store/listing.md`), and the Latin launcher label.
  The iOS half is done (M8).
- **In-app privacy link**: as soon as the policy URL exists, `url_launcher` + tappable legal
  line on sign-in and profile footer (App Review 5.1.1(i)).
- **Redesign port**: once a direction is picked on the Claude Design canvas, port it into `lib/`
  — tokens first (`core/theme/kalimat_colors.dart`, `kalimat_theme.dart`, `metrics.dart`), then
  the widgets. The canvas frames are token-exact, so a changed frame maps 1:1 onto those files.

## 💡 Ideas / backlog (not planned, jot-down list)

- Real-device share test: verify the 🟫🟨⬜ share string's RTL ordering survives WhatsApp/X
  (worst case: reverse square order per line).
- Supabase free tier pauses after ~1 week idle — decide: accept until launch, or add a
  weekly keep-alive.
- Streak-preserving timezone note: daily word flips at Riyadh midnight (≈1–2 h earlier
  in the Maghreb) — confirm that's acceptable before launch.
- ~~Onboarding polish: animate the help-dialog example row on first open.~~ Done in M7e.
- M7 on-device eyeball pass: win wave + haptics on a real phone (simulator has no
  vibration motor), motion-off sweep, dark-mode sweep, splash on cold start.
- Launcher label is still Latin "kalimat" (AndroidManifest `android:label`) — the
  Android 13+ permission dialog shows it; consider «كلمات» before release. (iOS already
  shows «كلمات» — `CFBundleDisplayName`.)
- iOS `LaunchImage` is the 1×1 template placeholder over the brown-600 launch ground —
  fine, but a wordmark there would make the splash match Android's.
- Reminder fires via inexact scheduling (no exact-alarm permission) — may land a few
  minutes late under Doze; accepted for now.
- Statistics restore from server after account switch (currently local stats stay authoritative).
- **Stranger queue + rank**: `challenges.source` and `profiles.rating` are already reserved, and
  the duel board + Realtime channel are in place; what's missing is a matchmaking RPC over a
  waiting pool and an Elo update hooked onto the outcome.
- **Push for «دورك»**: the header dot only refreshes on app open/resume. A real notification
  needs FCM/APNs, which the project has never set up (only `flutter_local_notifications`).
- Widget-test coverage for the loss path (answer reveal badge) and the leaderboard tab.

## Four-letter implementation verification — 2026-09-13

- [x] Daily games and duels: four letters, six attempts; centered boards, full keyboard and unchanged friend codes.
- [x] Local gameplay version 2 reset, preserving authentication/onboarding/name/settings/reminders; failure and once-only restore tests.
- [x] Stale cached/server daily answers fall back; incompatible duels show retry and never mount an invalid board.
- [x] Curated 365/200 pools, normalized uniqueness/membership/length checks, 7,918 guesses, reproducible generation and all 365 matching SQL/bundled dates.
- [x] Migration 0008 + transactional backup/deployment script; populated PostgreSQL 17.11 test passed reset, rollback, replay refusal, preserved users/friends/RLS/policies/RPCs and four-cell result constraints.
- [x] All 170 Flutter tests passed, including daily/duel light/dark, motion on/off and small screens.
- [x] `flutter analyze` passed with no issues.
- [x] iOS integration suite passed all eight 1320×2868 captures; final daily, help, sign-in, profile and duel light/dark PNGs visually reviewed without clipping or stale five-letter content.
- [x] Remote deployment: account owner confirmed migrations 0007/0008 and the regenerated daily/duel seeds were applied on 2026-09-13.
