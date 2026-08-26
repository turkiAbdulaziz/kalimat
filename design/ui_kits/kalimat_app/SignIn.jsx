const { Button, Input, CodeInput, Badge, Toast } = window.KalimatDesignSystem_9392cf;

function Wordmark({ size = "var(--text-4xl)" }) {
  return <div dir="rtl" style={{ fontFamily: "var(--font-display)", fontWeight: "var(--weight-black)", fontSize: size, color: "var(--text-wordmark)", lineHeight: 1 }}>كلمات</div>;
}

function AuthShell({ children }) {
  const shellStyle = { minHeight: "100vh", background: "var(--surface-page)", display: "flex", justifyContent: "center" };
  const colStyle = { width: "var(--app-max-width)", padding: "var(--space-10) var(--gutter) var(--space-8)", display: "flex", flexDirection: "column", gap: "var(--space-8)" };
  return <div style={shellStyle}><div style={colStyle}>{children}</div></div>;
}

function SampleRow() {
  const { Tile } = window.KalimatDesignSystem_9392cf;
  const cells = [["ك", "correct"], ["ل", "correct"], ["م", "present"], ["ا", "absent"], ["ت", "correct"]];
  return (
    <div style={{ display: "flex", gap: "var(--tile-gap)", justifyContent: "center" }}>
      {cells.map(([l, s], i) => <Tile key={i} letter={l} state={s} size={44} animate revealDelay={i * 120} />)}
    </div>
  );
}

/* Step 1 — welcome + email */
function SignInScreen({ onSendCode, onGuest }) {
  const [email, setEmail] = React.useState("");
  const valid = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
  const [touched, setTouched] = React.useState(false);
  return (
    <AuthShell>
      <div style={{ display: "grid", gap: "var(--space-4)", justifyItems: "center", textAlign: "center", marginTop: "var(--space-8)" }}>
        <Wordmark />
        <div style={{ fontFamily: "var(--font-ui)", fontSize: "var(--text-md)", color: "var(--text-muted)", lineHeight: "var(--leading-body)", maxWidth: 300 }}>
          خمّن كلمة اليوم في ست محاولات. كلمة جديدة كل يوم.
        </div>
        <SampleRow />
      </div>
      <div style={{ display: "grid", gap: "var(--space-4)" }}>
        <Input label="البريد الإلكتروني" type="email" placeholder="name@example.com" value={email}
          onChange={v => { setEmail(v); setTouched(true); }}
          invalid={touched && email.length > 3 && !valid}
          hint={touched && email.length > 3 && !valid ? "بريد غير صحيح" : "سنرسل لك رمز دخول من أربعة أرقام."} />
        <Button size="lg" block disabled={!valid} onClick={() => onSendCode(email)}>أرسل رمز الدخول</Button>
        <Button variant="ghost" block onClick={onGuest}>المتابعة كزائر</Button>
      </div>
      <div style={{ marginTop: "auto", textAlign: "center", fontFamily: "var(--font-ui)", fontSize: "var(--text-2xs)", color: "var(--text-subtle)", lineHeight: "var(--leading-body)" }}>
        بالمتابعة أنت توافق على الشروط وسياسة الخصوصية.
      </div>
    </AuthShell>
  );
}

/* Step 2 — code */
function CodeScreen({ email, onVerify, onBack }) {
  const [code, setCode] = React.useState("");
  const [error, setError] = React.useState(false);
  const submit = () => { if (code.length < 4) return; if (code === "٠٠٠٠" || code === "0000") { setError(true); return; } onVerify(); };
  React.useEffect(() => { if (code.length === 4) { const t = setTimeout(submit, 350); return () => clearTimeout(t); } setError(false); }, [code]);
  return (
    <AuthShell>
      <div style={{ display: "grid", gap: "var(--space-4)", justifyItems: "center", textAlign: "center", marginTop: "var(--space-10)" }}>
        <Wordmark size="var(--text-2xl)" />
        <div style={{ fontFamily: "var(--font-display)", fontSize: "var(--text-xl)", fontWeight: "var(--weight-bold)", color: "var(--text-body)" }}>أدخل رمز الدخول</div>
        <div style={{ fontFamily: "var(--font-ui)", fontSize: "var(--text-sm)", color: "var(--text-muted)" }}>أرسلنا رمزاً إلى</div>
        <Badge tone="accent">{email}</Badge>
      </div>
      <div style={{ display: "grid", gap: "var(--space-5)", justifyItems: "center" }}>
        <CodeInput length={4} value={code} onChange={setCode} />
        {error && <Toast message="رمز غير صحيح" />}
        <div style={{ fontFamily: "var(--font-ui)", fontSize: "var(--text-2xs)", color: "var(--text-subtle)" }}>أي أربعة أرقام تعمل في هذا العرض التوضيحي.</div>
      </div>
      <div style={{ display: "grid", gap: "var(--space-2)", marginTop: "auto" }}>
        <Button size="lg" block disabled={code.length < 4} onClick={submit}>تأكيد</Button>
        <Button variant="ghost" block onClick={onBack}>تغيير البريد</Button>
      </div>
    </AuthShell>
  );
}

/* Step 3 — display name */
function NameScreen({ onDone }) {
  const [name, setName] = React.useState("");
  return (
    <AuthShell>
      <div style={{ display: "grid", gap: "var(--space-3)", justifyItems: "center", textAlign: "center", marginTop: "var(--space-10)" }}>
        <Wordmark size="var(--text-2xl)" />
        <div style={{ fontFamily: "var(--font-display)", fontSize: "var(--text-xl)", fontWeight: "var(--weight-bold)" }}>ما اسمك؟</div>
        <div style={{ fontFamily: "var(--font-ui)", fontSize: "var(--text-sm)", color: "var(--text-muted)", maxWidth: 280, lineHeight: "var(--leading-body)" }}>
          يظهر هذا الاسم في صفحتك وعند مشاركة نتيجتك.
        </div>
      </div>
      <Input label="الاسم الظاهر" value={name} onChange={setName} placeholder="ليلى" maxLength={20} />
      <div style={{ display: "grid", gap: "var(--space-2)", marginTop: "auto" }}>
        <Button size="lg" block disabled={name.trim().length < 2} onClick={() => onDone(name.trim())}>ابدأ اللعب</Button>
        <Button variant="ghost" block onClick={() => onDone("زائر")}>تخطّي</Button>
      </div>
    </AuthShell>
  );
}

Object.assign(window, { SignInScreen, CodeScreen, NameScreen, AuthShell, Wordmark });
