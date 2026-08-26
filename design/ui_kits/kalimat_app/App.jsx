const EMPTY_BOARD = { rows: [], current: [], letterStates: {}, won: false };

function App({ start = "signin" }) {
  const [step, setStep] = React.useState(start);
  const [email, setEmail] = React.useState("laila@example.com");
  const [user, setUser] = React.useState({ name: "ليلى", email: "laila@example.com", joined: "مارس ٢٠٢٥" });
  const [settings, setSettings] = React.useState({ dark: false, hints: true, motion: true });
  const [board, setBoard] = React.useState(EMPTY_BOARD);
  const stats = { played: "٨٦", winRate: "٦٤٪", streak: "١٢", best: "٢١" };

  const signOut = () => { setBoard(EMPTY_BOARD); setStep("signin"); };

  let screen;
  if (step === "signin") screen = <window.SignInScreen
    onSendCode={e => { setEmail(e); setStep("code"); }}
    onGuest={() => { setUser({ name: "زائر", email: "بدون بريد", joined: "اليوم" }); setStep("game-first"); }} />;
  else if (step === "code") screen = <window.CodeScreen email={email} onVerify={() => setStep("name")} onBack={() => setStep("signin")} />;
  else if (step === "name") screen = <window.NameScreen onDone={name => { setUser(u => ({ ...u, name, email })); setStep("game-first"); }} />;
  else if (step === "profile") screen = <window.ProfileScreen user={user} stats={stats} settings={settings} setSettings={setSettings}
    onBack={() => setStep("game")} onSignOut={signOut} />;
  else screen = <window.GameScreen user={user} stats={stats} settings={settings} board={board} setBoard={setBoard}
    firstRun={step === "game-first"} onProfile={() => setStep("profile")} />;

  /* One theme boundary for the whole app: every surface below reads the
     remapped tokens, so no screen needs a dark branch of its own. */
  return <div data-theme={settings.dark ? "dark" : undefined}
    style={{ minHeight: "100vh", background: "var(--surface-page)", color: "var(--text-body)", fontFamily: "var(--font-ui)", colorScheme: settings.dark ? "dark" : "light" }}>{screen}</div>;
}

Object.assign(window, { App, EMPTY_BOARD });
