// wf-screens-group.jsx — Group chat variations

// A — Color-coded sender names, classic group bubbles
const GroupA = () => (
  <Phone>
    <div className="wf-topbar" style={{ paddingTop: 6, paddingBottom: 6 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
        <span className="wf-hand wf-muted" style={{ fontSize: 16 }}>‹</span>
        <Avatar initials="TR" size="sm" />
        <div style={{ display: "flex", flexDirection: "column" }}>
          <span className="wf-hand" style={{ fontSize: 14, fontWeight: 700, lineHeight: 1.1 }}>Thursday Run</span>
          <span className="wf-mono wf-muted" style={{ fontSize: 8.5 }}>6 members · 3 online</span>
        </div>
      </div>
      <div className="actions"><Icon glyph="📞" /><Icon glyph="⋯" /></div>
    </div>
    <div className="wf-msgs">
      <DaySep>Today</DaySep>
      <div className="wf-sender c1">Jamal</div>
      <Bubble side="them" filled text="route is uploaded, 8k loop" time="9:14" />
      <div className="wf-sender c2">Priya</div>
      <Bubble side="them" filled text="nice. starting from the bridge?" time="9:15" />
      <div className="wf-sender c3">Eve</div>
      <Bubble side="them" filled text="I can carpool — 2 spots" time="9:18" />
      <Bubble side="me" text="taking one, ty 🙏" time="9:20" status="✓✓" />
      <div className="wf-sender c4">Leon</div>
      <Bubble side="them" filled text="same. see y'all at 7" time="9:22" />
    </div>
    <Composer />
  </Phone>
);

// B — Inline reactions, threaded replies surfaced
const GroupB = () => (
  <Phone>
    <div className="wf-topbar" style={{ paddingTop: 6, paddingBottom: 6 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
        <span className="wf-hand wf-muted" style={{ fontSize: 16 }}>‹</span>
        <Avatar initials="TR" size="sm" />
        <div style={{ display: "flex", flexDirection: "column" }}>
          <span className="wf-hand" style={{ fontSize: 14, fontWeight: 700, lineHeight: 1.1 }}>Thursday Run</span>
          <span className="wf-mono wf-muted" style={{ fontSize: 8.5 }}>6 members</span>
        </div>
      </div>
      <div className="actions"><Icon glyph="🔍" /><Icon glyph="⋯" /></div>
    </div>
    <div className="wf-msgs">
      <DaySep>Today</DaySep>

      <div style={{ display: "flex", gap: 6, alignSelf: "flex-start", maxWidth: "85%" }}>
        <Avatar initials="J" size="sm" />
        <div>
          <div className="wf-sender c1" style={{ padding: 0 }}>Jamal</div>
          <Bubble side="them" filled text="route uploaded, 8k loop 🏃" time="9:14" />
          <div className="wf-reactions">🔥 3 · 👍 2</div>
        </div>
      </div>

      <div style={{ display: "flex", gap: 6, alignSelf: "flex-start", maxWidth: "85%" }}>
        <Avatar initials="P" size="sm" />
        <div>
          <div className="wf-sender c2" style={{ padding: 0 }}>Priya</div>
          <Bubble side="them" filled text="starting from the bridge?" time="9:15" />
          {/* thread chip */}
          <div style={{ display: "inline-flex", gap: 4, alignItems: "center", marginTop: 4, fontSize: 10, color: "var(--accent)", fontFamily: "var(--hand)" }}>
            <span className="wf-icon" style={{ width: 16, height: 16, fontSize: 10 }}>↪</span>
            <span>4 replies · last 2m</span>
          </div>
        </div>
      </div>

      <Bubble side="me" text="taking the carpool, ty 🙏" time="9:20" status="✓✓" />
      <div className="wf-reactions right">🙌 2</div>
    </div>
    <Composer />
  </Phone>
);

// C — Compact stacked, IRC-feel: dense, one line per message where possible
const GroupC = () => (
  <Phone>
    <div className="wf-topbar" style={{ paddingTop: 6, paddingBottom: 6 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
        <span className="wf-hand wf-muted" style={{ fontSize: 16 }}>‹</span>
        <span className="wf-hand" style={{ fontSize: 16, fontWeight: 700 }}>#thursday-run</span>
      </div>
      <div className="actions"><Icon glyph="👥" /><Icon glyph="⋯" /></div>
    </div>
    <div style={{ flex: 1, overflow: "hidden", padding: "8px 12px", fontSize: 12, display: "flex", flexDirection: "column", gap: 4 }}>
      <div className="wf-mono wf-muted" style={{ fontSize: 9, textAlign: "center", margin: "4px 0" }}>— today —</div>
      <div><span className="wf-mono wf-muted" style={{ fontSize: 9, marginRight: 6 }}>09:14</span><b style={{ color: "#c44a30" }}>jamal</b> route uploaded, 8k loop</div>
      <div><span className="wf-mono wf-muted" style={{ fontSize: 9, marginRight: 6 }}>09:15</span><b style={{ color: "#2f6f8f" }}>priya</b> starting from the bridge?</div>
      <div><span className="wf-mono wf-muted" style={{ fontSize: 9, marginRight: 6 }}>09:18</span><b style={{ color: "#5a7a2c" }}>eve</b> I can carpool — 2 spots</div>
      <div><span className="wf-mono wf-muted" style={{ fontSize: 9, marginRight: 6 }}>09:20</span><b style={{ color: "var(--accent)" }}>you</b> taking one, ty 🙏</div>
      <div><span className="wf-mono wf-muted" style={{ fontSize: 9, marginRight: 6 }}>09:22</span><b style={{ color: "#8a4caf" }}>leon</b> same. see y'all at 7</div>
      <div><span className="wf-mono wf-muted" style={{ fontSize: 9, marginRight: 6 }}>09:24</span><b style={{ color: "#2f6f8f" }}>priya</b> 🔥</div>
      <div><span className="wf-mono wf-muted" style={{ fontSize: 9, marginRight: 6 }}>09:31</span><b style={{ color: "#c44a30" }}>jamal</b> weather looks clear</div>
    </div>
    <Composer placeholder="message #thursday-run…" />
  </Phone>
);

Object.assign(window, { GroupA, GroupB, GroupC });
