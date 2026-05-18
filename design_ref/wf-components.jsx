// wf-components.jsx — shared wireframe primitives

const Phone = ({ children, statusTime = "9:41" }) => (
  <div className="wf-phone">
    <div className="wf-status">
      <span>{statusTime}</span>
      <span className="battery">5G</span>
    </div>
    {children}
  </div>
);

const Avatar = ({ initials, size, online, accent }) => {
  const cls = ["wf-avatar"];
  if (size) cls.push(size);
  if (online) cls.push("online");
  return (
    <div className={cls.join(" ")} style={accent ? { background: "var(--accent)", color: "#fff", borderColor: "var(--accent)" } : null}>
      {initials}
    </div>
  );
};

const Icon = ({ glyph, variant, circle }) => {
  const cls = ["wf-icon"];
  if (variant) cls.push(variant);
  if (circle) cls.push("circle");
  return <span className={cls.join(" ")}>{glyph}</span>;
};

const TopBar = ({ title, left, right, underline }) => (
  <div className="wf-topbar">
    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
      {left}
      <h1>{underline ? <span className="wf-underline">{title}</span> : title}</h1>
    </div>
    <div className="actions">{right}</div>
  </div>
);

const ChatTopBar = ({ name, status, accent }) => (
  <div className="wf-topbar" style={{ paddingTop: 6, paddingBottom: 6 }}>
    <div style={{ display: "flex", alignItems: "center", gap: 8, minWidth: 0 }}>
      <span className="wf-hand wf-muted" style={{ fontSize: 16 }}>‹</span>
      <Avatar initials="M" size="sm" online accent={accent} />
      <div style={{ display: "flex", flexDirection: "column", minWidth: 0 }}>
        <span className="wf-hand" style={{ fontSize: 14, fontWeight: 700, lineHeight: 1.1 }}>{name}</span>
        <span className="wf-mono wf-muted" style={{ fontSize: 8.5 }}>{status}</span>
      </div>
    </div>
    <div className="actions">
      <Icon glyph="📞" />
      <Icon glyph="⋯" />
    </div>
  </div>
);

const Composer = ({ placeholder = "Message…", variant }) => (
  <div className="wf-composer">
    <Icon glyph="+" />
    <div className="input">{placeholder}</div>
    {variant === "voice" ? <Icon glyph="🎙" variant="accent" /> : <Icon glyph="↑" variant="accent" />}
  </div>
);

const BottomNav = ({ items, active = 0 }) => (
  <div className="wf-bottomnav">
    {items.map((it, i) => (
      <div key={i} className={"item" + (i === active ? " active" : "")}>
        <Icon glyph={it.glyph} />
        <span>{it.label}</span>
      </div>
    ))}
  </div>
);

const DefaultNav = ({ active = 0 }) => (
  <BottomNav
    active={active}
    items={[
      { glyph: "💬", label: "Chats" },
      { glyph: "○", label: "Status" },
      { glyph: "☎", label: "Calls" },
      { glyph: "≡", label: "Me" },
    ]}
  />
);

const Note = ({ x, y, children, arrow = "↘" }) => (
  <div className="wf-note" style={{ left: x, top: y }}>
    <span className="arrow">{arrow}</span> {children}
  </div>
);

// Static rows / lines — kept terse, copy is plausible-mundane
const ChatRow = ({ initials, name, time, preview, unread, online, muted, typing }) => (
  <div className="wf-row">
    <Avatar initials={initials} online={online} />
    <div className="body">
      <div className="name">
        <span>{name}</span>
        <span className="time">{time}</span>
      </div>
      <div className="preview">
        <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
          {typing ? <em style={{ color: "var(--accent)" }}>typing…</em> : preview}
        </span>
        {unread ? <span className="wf-pill">{unread}</span> : muted ? <span className="wf-muted">🔕</span> : null}
      </div>
    </div>
  </div>
);

const Bubble = ({ side, text, time, status, filled, voice }) => (
  <div className={"wf-bubble " + side + (filled ? " filled" : "")}>
    {voice ? (
      <div className="wf-voice">
        <Icon glyph="▶" circle />
        <div className="wave"></div>
        <span className="dur">{voice}</span>
      </div>
    ) : (
      <div>{text}</div>
    )}
    {time && <div className="meta">{time} {status && <span>{status}</span>}</div>}
  </div>
);

const DaySep = ({ children }) => <div className="wf-daysep">{children}</div>;

const Box = ({ w, h, label, dashed, style }) => (
  <div
    className={"wf-box" + (dashed ? " dashed" : "")}
    style={{ width: w, height: h, ...style }}
  >
    {label}
  </div>
);

Object.assign(window, {
  Phone, Avatar, Icon, TopBar, ChatTopBar, Composer, BottomNav, DefaultNav,
  Note, ChatRow, Bubble, DaySep, Box,
});
