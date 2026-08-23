# UI kit — كلمات daily puzzle (mobile web)

The only product surface in this system. `index.html` is a playable recreation: the target word is **مدرسة**.

Flow: help dialog on first load → type with the on-screen Arabic keyboard → إدخال evaluates the row (flip reveal, 120 ms stagger) → keyboard caps take the best-known state → win or six guesses opens the stats dialog. Settings toggles dark surface, keyboard hints, and tile motion.

Files
- `App.jsx` — state machine, Header, HelpDialog, StatsDialog, SettingsDialog
- `index.html` — mount point, loads `_ds_bundle.js`, lucide, and App.jsx

Everything visual comes from the system's components (Tile, GuessGrid, Keyboard, Dialog, Button, IconButton, Badge, Toast, Switch, StatCard, DistributionBar) and tokens; the kit adds no colors of its own.

There is no desktop or marketing surface in this design system — none was supplied.
