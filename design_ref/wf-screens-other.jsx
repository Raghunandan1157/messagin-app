// wf-screens-other.jsx — Voice call + Profile

const CallScreen = () => (
  <Phone>
    <div className="wf-call">
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
        <span className="wf-mono wf-muted" style={{ fontSize: 9, letterSpacing: 2 }}>LOOP · ENCRYPTED</span>
        <Avatar initials="MR" size="xl" online />
        <div className="caller-name">Maya Rivera</div>
        <div className="caller-status">01:24 · CONNECTED</div>
      </div>

      <div style={{ display: "flex", gap: 8 }}>
        <div className="wf-icon" style={{ width: 32, height: 32, fontSize: 11 }}>🔇</div>
        <div className="wf-icon" style={{ width: 32, height: 32, fontSize: 11 }}>📹</div>
        <div className="wf-icon" style={{ width: 32, height: 32, fontSize: 11 }}>🔊</div>
        <div className="wf-icon" style={{ width: 32, height: 32, fontSize: 11 }}>＋</div>
      </div>

      <div className="call-actions">
        <div className="call-btn">mute</div>
        <div className="call-btn end">end</div>
        <div className="call-btn">hold</div>
      </div>
    </div>
  </Phone>
);

const ProfileScreen = () => (
  <Phone>
    <TopBar
      title="You"
      left={<span className="wf-hand wf-muted" style={{ fontSize: 16 }}>‹</span>}
      right={<Icon glyph="✎" />}
    />
    <div className="wf-profile-header">
      <Avatar initials="AC" size="xl" />
      <div className="wf-hand" style={{ fontSize: 20, fontWeight: 700, marginTop: 8 }}>Alex Chen</div>
      <div className="wf-mono wf-muted" style={{ fontSize: 9, marginTop: 2 }}>+1 555 0143 · @alexc</div>
      <div style={{ fontSize: 11, color: "var(--ink-2)", marginTop: 6, textAlign: "center", fontStyle: "italic" }}>
        "building little things, mostly outside"
      </div>
    </div>
    <div className="wf-profile-rows" style={{ flex: 1, overflow: "hidden" }}>
      <div className="wf-profile-row"><Icon glyph="🔔" /><span className="label">Notifications</span><span className="val">all</span></div>
      <div className="wf-profile-row"><Icon glyph="🔒" /><span className="label">Privacy</span><span className="val">friends</span></div>
      <div className="wf-profile-row"><Icon glyph="🌗" /><span className="label">Appearance</span><span className="val">auto</span></div>
      <div className="wf-profile-row"><Icon glyph="💾" /><span className="label">Storage & Data</span><span className="val">412 mb</span></div>
      <div className="wf-profile-row"><Icon glyph="🗝" /><span className="label">Encryption keys</span><span className="val">verified ✓</span></div>
      <div className="wf-profile-row"><Icon glyph="⌫" /><span className="label" style={{ color: "var(--accent)" }}>Log out</span></div>
    </div>
    <DefaultNav active={3} />
  </Phone>
);

Object.assign(window, { CallScreen, ProfileScreen });
