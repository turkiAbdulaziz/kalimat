const { Button, IconButton, Badge, Toast, Tile, GuessGrid, Keyboard, StatCard, DistributionBar, Dialog, Avatar } = window.KalimatDesignSystem_9392cf;

const TARGET = ["م","د","ر","س","ة"];
const WORD_LENGTH = 5, MAX_GUESSES = 6;
const AR_DIGITS = ["٠","١","٢","٣","٤","٥","٦"];

function evaluateGuess(guess) {
  const res = guess.map(() => "absent");
  const pool = {};
  TARGET.forEach((l, i) => { if (guess[i] === l) res[i] = "correct"; else pool[l] = (pool[l] || 0) + 1; });
  guess.forEach((l, i) => { if (res[i] !== "correct" && pool[l]) { res[i] = "present"; pool[l]--; } });
  return res;
}

function GameHeader({ user, onHelp, onStats, onProfile }) {
  return (
    <header dir="rtl" style={{ height: "var(--header-height)", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 var(--space-3)", borderBottom: "1px solid var(--line-soft)", background: "var(--surface-card)" }}>
      <IconButton icon="circle-help" label="كيف تلعب" onClick={onHelp} />
      <div style={{ fontFamily: "var(--font-display)", fontSize: "var(--text-xl)", fontWeight: "var(--weight-black)", color: "var(--text-wordmark)" }}>كلمات</div>
      <div style={{ display: "flex", alignItems: "center", gap: "var(--space-2)" }}>
        <IconButton icon="bar-chart-3" label="الإحصائيات" onClick={onStats} />
        <button type="button" aria-label="حسابي" onClick={onProfile} style={{ border: "none", background: "transparent", padding: 0, cursor: "pointer" }}>
          <Avatar name={user.name} size={34} />
        </button>
      </div>
    </header>
  );
}

function HelpDialog({ open, onClose, name }) {
  const example = [{ letter: "م", state: "correct" }, { letter: "ك", state: "absent" }, { letter: "ت", state: "present" }, { letter: "ب", state: "absent" }, { letter: "ة", state: "absent" }];
  return (
    <Dialog open={open} title={name ? "أهلاً " + name : "كيف تلعب"} onClose={onClose} footer={<Button block onClick={onClose}>ابدأ</Button>}>
      <p style={{ marginTop: 0 }}>خمّن كلمة اليوم في ست محاولات. كل محاولة يجب أن تكون كلمة عربية من خمسة حروف.</p>
      <div style={{ display: "flex", gap: "var(--tile-gap)", justifyContent: "center", margin: "var(--space-4) 0" }}>
        {example.map((c, i) => <Tile key={i} letter={c.letter} state={c.state} size={44} />)}
      </div>
      <ul style={{ paddingInlineStart: 18, margin: 0, display: "grid", gap: 6 }}>
        <li>الحرف بالبني الغامق في مكانه الصحيح.</li>
        <li>الحرف بالبني الفاتح موجود في الكلمة لكن في مكان آخر.</li>
        <li>الحرف الرمادي غير موجود في الكلمة.</li>
      </ul>
    </Dialog>
  );
}

function StatsDialog({ open, onClose, won, guessCount, stats, onProfile }) {
  const dist = [[1,1],[2,4],[3,9],[4,14],[5,6],[6,2]];
  return (
    <Dialog open={open} title={won ? "أحسنت!" : "الإحصائيات"} onClose={onClose}
      footer={<div style={{ display: "grid", gap: "var(--space-2)" }}>
        <Button block>مشاركة النتيجة</Button>
        <Button variant="ghost" block onClick={onProfile}>عرض حسابي</Button>
      </div>}>
      {won && <div style={{ textAlign: "center", marginBottom: "var(--space-4)" }}><Badge tone="accent">{"كلمات ٢٤٧ — " + AR_DIGITS[guessCount] + "/٦"}</Badge></div>}
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "var(--space-6)" }}>
        <StatCard value={stats.played} label="لُعبت" />
        <StatCard value={stats.winRate} label="نسبة الفوز" emphasis />
        <StatCard value={stats.streak} label="السلسلة" />
        <StatCard value={stats.best} label="الأفضل" />
      </div>
      <div style={{ fontSize: "var(--text-2xs)", color: "var(--text-subtle)", marginBottom: "var(--space-2)" }}>توزيع المحاولات</div>
      <div style={{ display: "grid", gap: 6 }}>
        {dist.map(([g, c]) => <DistributionBar key={g} guess={g} count={c} max={14} highlight={won && g === guessCount} />)}
      </div>
    </Dialog>
  );
}

function GameScreen({ user, stats, settings, onProfile, firstRun, board, setBoard }) {
  const { rows, current, letterStates, won } = board;
  const setRows = fn => setBoard(b => ({ ...b, rows: typeof fn === "function" ? fn(b.rows) : fn }));
  const setCurrent = fn => setBoard(b => ({ ...b, current: typeof fn === "function" ? fn(b.current) : fn }));
  const setLetterStates = fn => setBoard(b => ({ ...b, letterStates: typeof fn === "function" ? fn(b.letterStates) : fn }));
  const setWon = v => setBoard(b => ({ ...b, won: v }));
  const [toast, setToast] = React.useState(null);
  const [shakeRow, setShakeRow] = React.useState(-1);
  const [revealRow, setRevealRow] = React.useState(-1);
  const [dialog, setDialog] = React.useState(firstRun ? "help" : null);

  React.useEffect(() => { if (window.lucide) window.lucide.createIcons({ nameAttr: "data-lucide" }); });
  const flash = m => { setToast(m); setTimeout(() => setToast(null), 1300); };

  const onKey = l => { if (!won && current.length < WORD_LENGTH) setCurrent(c => [...c, l]); };
  const onDelete = () => setCurrent(c => c.slice(0, -1));
  const onEnter = () => {
    if (won) return;
    if (current.length < WORD_LENGTH) { setShakeRow(rows.length); flash("الكلمة قصيرة"); setTimeout(() => setShakeRow(-1), 450); return; }
    const states = evaluateGuess(current);
    const row = current.map((letter, i) => ({ letter, state: states[i] }));
    const idx = rows.length;
    setRows(r => [...r, row]);
    setRevealRow(idx);
    setLetterStates(ls => {
      const next = { ...ls }, rank = { absent: 0, present: 1, correct: 2 };
      row.forEach(c => { if (!next[c.letter] || rank[c.state] > rank[next[c.letter]]) next[c.letter] = c.state; });
      return next;
    });
    setCurrent([]);
    const solved = states.every(s => s === "correct");
    setTimeout(() => setRevealRow(-1), 900);
    if (solved) { setWon(true); flash("أحسنت!"); setTimeout(() => setDialog("stats"), 1400); }
    else if (idx + 1 >= MAX_GUESSES) setTimeout(() => setDialog("stats"), 1000);
  };

  const displayRows = [...rows];
  if (current.length && rows.length < MAX_GUESSES) displayRows[rows.length] = current.map(l => ({ letter: l, state: "filled" }));

  return (
    <div style={{ minHeight: "100vh", background: "var(--surface-page)", display: "flex", justifyContent: "center" }}>
      <div style={{ width: "var(--app-max-width)", display: "flex", flexDirection: "column", minHeight: "100vh", background: "var(--surface-page)" }}>
        <GameHeader user={user} onHelp={() => setDialog("help")} onStats={() => setDialog("stats")} onProfile={onProfile} />
        <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "var(--space-4) var(--gutter)", gap: "var(--space-4)" }}>
          <div style={{ height: 34, display: "flex", alignItems: "center" }}>
            {toast ? <Toast message={toast} tone={won ? "success" : "neutral"} /> : <Badge>كلمة اليوم ٢٤٧</Badge>}
          </div>
          <GuessGrid rows={displayRows} wordLength={WORD_LENGTH} maxGuesses={MAX_GUESSES} shakeRow={shakeRow} revealRow={settings.motion ? revealRow : -1} />
        </div>
        <div style={{ padding: "var(--space-2) var(--space-2) var(--space-4)" }}>
          <Keyboard letterStates={settings.hints ? letterStates : {}} onKey={onKey} onEnter={onEnter} onDelete={onDelete} disabled={won} />
        </div>
      </div>
      <HelpDialog open={dialog === "help"} onClose={() => setDialog(null)} name={firstRun ? user.name : null} />
      <StatsDialog open={dialog === "stats"} onClose={() => setDialog(null)} won={won} guessCount={rows.length} stats={stats}
        onProfile={() => { setDialog(null); onProfile(); }} />
    </div>
  );
}

Object.assign(window, { GameScreen, GameHeader, HelpDialog, StatsDialog, evaluateGuess });
