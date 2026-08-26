# كلمات (Kalimat) — Status & Next Steps

_Last updated: 2026-08-25. Companion to [HANDOFF.md](HANDOFF.md) (architecture, gotchas, how to run)._

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

**Suite: 69 tests green · `flutter analyze` clean.**

---

## ⏳ Waiting on you

1. **Supabase project** *(unblocks M3 verification — ~10 min)*
   Create a free project at supabase.com → send the Project URL + anon/publishable key.
   Then together: run the 3 migrations + word seed in the SQL editor, enable Anonymous
   sign-ins + Manual linking, and verify online play end-to-end on the emulator.
2. **Answer curation** *(launch blocker, not a dev blocker — ~1–2 h)*
   Review `tool/out/answers_candidates.txt` (frequency-ranked, clitic-flagged) and build a
   curated `assets/words/answers.txt` (aim ≥365 words, correct spellings, order = puzzle
   order). Then re-run `dart run tool/build_wordlists.dart` to regenerate the server seed.
3. **Console setup for sign-in** *(unblocks M4 verification — needs your accounts)*
   Google Cloud: OAuth consent screen + **web** client ID + Android client ID (package
   `com.kalimat.app`, debug/release SHA-1s — I can generate the SHA-1s).
   Apple: paid developer account → App ID with Sign in with Apple + Services ID + `.p8` key.
   Details/checklist: companion plan §11.

## 🔜 Possible next steps (my side, once unblocked)

- **M3 verification**: wire credentials, run migrations/seed, prove: same word on two
  devices, airplane-mode first launch playable, queue flush visible in table editor,
  `daily_words` unreadable via REST.
- **M4/M5 verification (configured)**: fresh install → sign-in screen → Google → name
  screen → game with «أهلاً {name}»; guest path; sign-out → sign-in with board cleared,
  stats kept; returning account skips the name screen; leaderboard rows live-only,
  duplicate submit no-op.
- **M5 release prep** (no blockers, can start anytime): release keystore + signing config,
  versioning, MSA store listing copy, Play Console internal-testing track; iOS build via
  Mac/CI (e.g. Codemagic) with Sign in with Apple entitlement + Google URL scheme.

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
- Widget-test coverage for the loss path (answer reveal badge) and the leaderboard tab.
