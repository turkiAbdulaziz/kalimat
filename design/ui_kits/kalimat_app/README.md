# UI kit — كلمات (mobile web)

The product's whole flow, from cold start to a finished puzzle. `index.html` starts at sign-in; `signin.html`, `game.html` and `profile.html` are the same app seeded at a given step so each screen gets its own card.

## Flow
1. **Sign in** (`SignIn.jsx` → `SignInScreen`) — wordmark, one-line pitch, an animated sample row, email field. `أرسل رمز الدخول` enables only on a valid address; `المتابعة كزائر` skips straight to the board as زائر.
2. **Code** (`CodeScreen`) — four-digit one-time code entered into `CodeInput`, which is built from `Tile`, so the first thing a new player touches already looks like the board. Any four digits pass; `٠٠٠٠` demonstrates the error state. Auto-submits when full.
3. **Display name** (`NameScreen`) — the name used on the account screen and in shared results. `تخطّي` falls back to زائر.
4. **Game** (`Game.jsx` → `GameScreen`) — target word **مدرسة**. First arrival opens the help dialog titled `أهلاً {name}`. Typing pops, إدخال flips the row (120 ms stagger), keyboard caps take the best-known state, a short word shakes. Win or six guesses opens the stats dialog, which offers `عرض حسابي`.
5. **Account** (`Profile.jsx` → `ProfileScreen`) — monogram avatar, name, email, streak badge, four stats, guess distribution, preference switches (dark surface / keyboard hints / tile motion), daily-reminder and share rows, and `تسجيل الخروج` which returns to step 1.

The avatar in the game header is the way into the account screen; the arrow in the account header returns to the board.

## Files
- `index.html` / `signin.html` / `game.html` / `profile.html` — mount points, each seeding `App` at a different step
- `App.jsx` — flow router and the single source of user + settings state
- `SignIn.jsx` — AuthShell, Wordmark, SignInScreen, CodeScreen, NameScreen
- `Game.jsx` — GameScreen, GameHeader, HelpDialog, StatsDialog, guess evaluation
- `Profile.jsx` — ProfileScreen

All visuals come from system components (Tile, GuessGrid, Keyboard, Input, CodeInput, Avatar, ListRow, Dialog, Button, IconButton, Badge, Toast, Switch, StatCard, DistributionBar) and tokens; the kit adds no colours of its own.

Not designed, because nothing was supplied to base them on: password or social sign-in, account deletion, leaderboards, desktop layout.

## Theme
`App.jsx` sets `data-theme="dark"` on a single root wrapper; every screen reads semantic tokens only, so no screen has a dark branch. Board progress lives in `App` (`board`), so visiting the account screen and returning resumes the same puzzle.
