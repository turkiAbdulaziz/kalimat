const { Avatar, Badge, Button, ListRow, StatCard, DistributionBar, Switch, IconButton } = window.KalimatDesignSystem_9392cf;

function ProfileScreen({ user, stats, settings, setSettings, onBack, onSignOut }) {
  /* Surfaces come from tokens only; the data-theme wrapper in App.jsx flips them. */
  React.useEffect(() => { if (window.lucide) window.lucide.createIcons({ nameAttr: "data-lucide" }); });
  const set = k => v => setSettings(s => ({ ...s, [k]: v }));
  const dist = [[1, 1], [2, 4], [3, 9], [4, 14], [5, 6], [6, 2]];
  const sectionTitle = { fontFamily: "var(--font-ui)", fontSize: "var(--text-2xs)", fontWeight: "var(--weight-semibold)", color: "var(--text-subtle)", margin: "0 0 var(--space-2)" };
  const cardStyle = { background: "var(--surface-card)", border: "1px solid var(--line-soft)", borderRadius: "var(--radius-card)", padding: "var(--space-4)", boxShadow: "var(--shadow-sm)" };
  return (
    <div dir="rtl" style={{ minHeight: "100vh", background: "var(--surface-page)", display: "flex", justifyContent: "center" }}>
      <div style={{ width: "var(--app-max-width)", display: "flex", flexDirection: "column", minHeight: "100vh" }}>
        <header style={{ height: "var(--header-height)", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 var(--space-3)", borderBottom: "1px solid var(--line-soft)", background: "var(--surface-card)" }}>
          <IconButton icon="arrow-right" label="رجوع" onClick={onBack} />
          <div style={{ fontFamily: "var(--font-display)", fontSize: "var(--text-md)", fontWeight: "var(--weight-bold)" }}>حسابي</div>
          <div style={{ width: 40 }}></div>
        </header>
        <div style={{ padding: "var(--space-6) var(--gutter)", display: "grid", gap: "var(--space-6)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "var(--space-4)" }}>
            <Avatar name={user.name} size={64} />
            <div style={{ display: "grid", gap: 6 }}>
              <div style={{ fontFamily: "var(--font-display)", fontSize: "var(--text-xl)", fontWeight: "var(--weight-bold)" }}>{user.name}</div>
              <div style={{ fontFamily: "var(--font-ui)", fontSize: "var(--text-xs)", color: "var(--text-subtle)" }}>{user.email}</div>
              <div><Badge tone="accent">{"سلسلة " + stats.streak}</Badge></div>
            </div>
          </div>

          <div>
            <p style={sectionTitle}>الإحصائيات</p>
            <div style={{ ...cardStyle, display: "flex", justifyContent: "space-between" }}>
              <StatCard value={stats.played} label="لُعبت" />
              <StatCard value={stats.winRate} label="نسبة الفوز" emphasis />
              <StatCard value={stats.streak} label="السلسلة" />
              <StatCard value={stats.best} label="الأفضل" />
            </div>
          </div>

          <div>
            <p style={sectionTitle}>توزيع المحاولات</p>
            <div style={{ ...cardStyle, display: "grid", gap: 6 }}>
              {dist.map(([g, c]) => <DistributionBar key={g} guess={g} count={c} max={14} highlight={g === 4} />)}
            </div>
          </div>

          <div>
            <p style={sectionTitle}>التفضيلات</p>
            <div style={cardStyle}>
              <Switch label="الوضع الليلي" hint="خلفية بنية غامقة" checked={settings.dark} onChange={set("dark")} />
              <Switch label="تلميحات الحروف" hint="إظهار الحروف المستبعدة على لوحة المفاتيح" checked={settings.hints} onChange={set("hints")} />
              <Switch label="حركة المربعات" checked={settings.motion} onChange={set("motion")} />
              <ListRow icon="bell" label="التنبيه اليومي" value="٩:٠٠ ص" onClick={() => {}} />
              <ListRow icon="share-2" label="مشاركة النتيجة الأخيرة" onClick={() => {}} />
              <ListRow icon="log-out" label="تسجيل الخروج" danger onClick={onSignOut} />
            </div>
          </div>

          <div style={{ textAlign: "center", fontFamily: "var(--font-ui)", fontSize: "var(--text-2xs)", color: "var(--text-subtle)" }}>
            {"عضو منذ " + user.joined + " · نسخة ١٫٤"}
          </div>
          <Button variant="secondary" block onClick={onBack}>العودة إلى اللعبة</Button>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { ProfileScreen });
