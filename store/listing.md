# App Store listing — كلمات

Everything App Store Connect asks for, ready to paste. Character limits are Apple's.
`[SUPPORT_EMAIL]` / `[PRIVACY_URL]` / `[SUPPORT_URL]` are the only blanks — fill them once
`privacy.html` and `support.html` are hosted (see HANDOFF → "App Store release").

## App record

| Field | Value |
|---|---|
| Name (30) | `كلمات` — if taken, `كلمات — الكلمة اليومية` |
| Subtitle (30) | `خمّن كلمة اليوم في ست محاولات` |
| Bundle ID | `com.kalimat.game` |
| SKU | `kalimat-ios` |
| Primary language | Arabic |
| Primary category | Games › Word |
| Secondary category | Games › Puzzle |
| Price | Free |
| Availability | All territories (or Arabic-speaking first — your call) |
| Version | 1.0.0 (build 1) — matches `pubspec.yaml` `1.0.0+1` |
| Copyright | `© ٢٠٢٦ [YOUR_NAME]` |
| Support URL | `[SUPPORT_URL]` → `store/support.html` |
| Privacy Policy URL | `[PRIVACY_URL]` → `store/privacy.html` |
| Marketing URL | (optional — leave blank) |

## Promotional text (170)

```
كلمة عربية جديدة كل يوم. خمّنها في ست محاولات، تابع سلسلتك، وتحدَّ أصدقاءك على كلمة لا يعرفها أحد سواكما.
```

## Description (4000)

```
«كلمات» لعبة الكلمة اليومية بالعربية.

كل يوم كلمة واحدة من أربعة أحرف، ولك ست محاولات لتخمينها. بعد كل محاولة تتلوّن الحروف لتدلّك: بنيّ داكن للحرف في مكانه، بنيّ فاتح للحرف الموجود في مكان آخر، ورمادي للحرف غير الموجود. الكلمة نفسها لجميع اللاعبين، فشارك شبكتك الملوّنة دون أن تكشف الحل.

صُمّمت اللعبة للعربية من البداية:
• واجهة عربية كاملة من اليمين إلى اليسار، بأرقام عربية.
• لوحة مفاتيح عربية مصمّمة للّعبة، بثلاثة وثلاثين حرفًا.
• مطابقة متساهلة: أ وإ وآ تُحسب كـ ا، وة كـ ه، وى كـ ي — فلا تخسر محاولة على همزة.
• قاموس يزيد على ثمانية عشر ألف كلمة شائعة.

تابع تقدّمك:
• إحصاءاتك: عدد الألعاب، نسبة الفوز، سلسلتك الحالية وأفضل سلسلة، وتوزيع المحاولات.
• لوحة المتصدرين لليوم وللإجمالي.
• تنبيه يومي اختياري في الوقت الذي تختاره.

تحدَّ أصدقاءك:
• أضف صديقًا برمزه المكوّن من ستة أرقام.
• تحدٍّ ثنائي على كلمة من قائمة مستقلة لا تُفسد كلمة اليوم أبدًا.
• الأقل محاولات يفوز، والأسرع يحسم التعادل — وترى تقدّم صديقك أثناء لعبه.

بلا إعلانات، بلا تتبّع، ويعمل دون اتصال. سجّل الدخول عبر Apple أو Google لحفظ تقدّمك عبر أجهزتك، أو العب زائرًا.

كلمة اليوم بانتظارك.
```

## Keywords (100, comma-separated, no spaces after commas)

```
كلمات,وردل,لعبة كلمات,كلمة اليوم,عربي,ألغاز,تحدي,أصدقاء,مفردات,wordle,arabic
```

## What's New (first release)

```
الإصدار الأول من «كلمات»: كلمة يومية، إحصاءات وسلسلة، متصدرون، وتحدّيات ثنائية مع الأصدقاء.
```

## Screenshots

6.9-inch (iPhone 17 Pro Max, 1320 × 2868) captured from the simulator into `store/screenshots/`.
Upload in this order — the first two carry the listing:

1. `01-board.png` — mid-game board with hints
2. `02-won.png` — solved board with the stats card
3. `03-help.png` — how-to-play dialog (explains the colours)
4. `04-profile.png` — «حسابي» with stats and streak
5. `05-signin.png` — sign-in screen
6. `06-dark.png` — dark mode board
7. `07-duel.png` — friend duel, motion disabled
8. `08-duel-dark.png` — friend duel in dark mode, motion disabled

Apple scales 6.9-inch shots to the other iPhone sizes automatically; iPad is not needed
(the project is iPhone-only: `TARGETED_DEVICE_FAMILY = 1`).

## App Privacy (nutrition label)

Answer **Yes, we collect data**, then declare exactly these — all *Linked to the user*,
none *Used for tracking*, purpose **App Functionality** only:

| Category | Type | When |
|---|---|---|
| Contact Info | Email Address | only when the player links Apple/Google |
| Contact Info | Name | the display name the player types |
| Identifiers | User ID | Supabase auth uid (also for guests once online) |
| User Content | Gameplay Content | results, guesses grid, duel outcomes |

Nothing under Location, Contacts, Purchases, Browsing/Search history, Diagnostics, Usage Data.
The bundled `ios/Runner/PrivacyInfo.xcprivacy` declares the same four types and the
UserDefaults required-reason API (CA92.1, via shared_preferences).

## Age rating questionnaire

Everything **None** — no violence, sexual content, profanity, gambling, drugs, horror, medical
content, contests. **User-generated content**: Yes — display names are visible to other players
(leaderboards, duels); there is no free-text chat, and names can be changed by the player.
Unrestricted web access: No. Expected result: **4+**.

## App Review information

- **Sign-in required?** No. Tap «المتابعة كزائر» to play everything except cross-device sync.
  Sign in with Apple works in review; Google is hidden until its client ID is configured.
- **Demo account**: not needed (guest path).
- **Notes to the reviewer** (paste):

```
Kalimat is a daily Arabic word game (Wordle-style). The whole UI is Arabic/RTL by design.
• Guest play: tap «المتابعة كزائر» on the first screen — no account needed.
• Sign in with Apple is offered on the first screen and under «حسابي → حفظ التقدم».
• Account deletion (Guideline 5.1.1 v): «حسابي» (tap the avatar top-left) → «حذف الحساب» — visible once signed in with Apple; it deletes the server account and all its data immediately.
• The daily word rolls over at midnight Riyadh time (UTC+3); a duel against a friend needs a second account, so the duels tab will simply be empty during review.
• Local notifications are optional and off by default («التنبيه اليومي» under preferences).
```

- **Export compliance**: `ITSAppUsesNonExemptEncryption = NO` is already in Info.plist (HTTPS only),
  so the compliance prompt is skipped on each upload.
- **Content rights**: fonts Noto Kufi Arabic / IBM Plex Sans Arabic (OFL, licences bundled);
  curated answer lists and accepted guesses from hermitdave FrequencyWords (MIT) plus reviewed additions. No third-party trademarks.
- **Advertising identifier**: No.

## Before you press Submit — in-app checks

- [ ] Privacy policy is hosted and `[PRIVACY_URL]` pasted in App Store Connect **and** linked from
      inside the app (the legal line on the sign-in screen / profile footer) — Guideline 5.1.1(i).
- [ ] Migration `0007_delete_account.sql` has been run in the Supabase SQL editor — otherwise
      «حذف الحساب» fails with «تعذّر حذف الحساب».
- [ ] Supabase → Authentication → Providers → Apple is ON with `com.kalimat.game` in Client IDs.
- [ ] A TestFlight install on a real iPhone: Sign in with Apple → name → game → «حسابي» → delete.
