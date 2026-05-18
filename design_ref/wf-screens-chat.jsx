// wf-screens-chat.jsx — 1:1 conversation variations

// A — Classic bubbles, alternating sides, status ticks
const ChatA = () => (
  <Phone>
    <ChatTopBar name="Maya Rivera" status="online · last seen now" />
    <div className="wf-msgs">
      <DaySep>Today</DaySep>
      <Bubble side="them" text="hey are we still on for dinner?" time="10:38" />
      <Bubble side="me" text="yes! 6pm at the corner place?" time="10:40" status="✓✓" />
      <Bubble side="them" text="perfect. I'll be a few mins late" time="10:41" />
      <Bubble side="them" text="ok see you at 6 then 👍" time="10:42" />
      <Bubble side="me" text="🍝" time="10:42" status="✓" />
    </div>
    <Composer />
  </Phone>
);

// B — Minimal text-rail: no bubbles, just aligned text with timestamps in gutter
const ChatB = () => (
  <Phone>
    <ChatTopBar name="Maya Rivera" status="online" />
    <div style={{ flex: 1, overflow: "hidden", padding: "10px 0", display: "flex", flexDirection: "column", gap: 12 }}>
      <div className="wf-daysep" style={{ alignSelf: "center" }}>today</div>

      <div style={{ display: "flex", gap: 8, padding: "0 14px" }}>
        <span className="wf-mono wf-small wf-muted" style={{ width: 32, flexShrink: 0 }}>10:38</span>
        <div style={{ flex: 1, fontSize: 12, color: "var(--ink-2)" }}>hey are we still on for dinner?</div>
      </div>
      <div style={{ display: "flex", gap: 8, padding: "0 14px", justifyContent: "flex-end" }}>
        <div style={{ flex: 1, fontSize: 12, textAlign: "right", color: "var(--ink)" }}>yes! 6pm at the corner place?</div>
        <span className="wf-mono wf-small wf-muted" style={{ width: 32, flexShrink: 0, textAlign: "right" }}>10:40</span>
      </div>
      <div style={{ display: "flex", gap: 8, padding: "0 14px" }}>
        <span className="wf-mono wf-small wf-muted" style={{ width: 32, flexShrink: 0 }}>10:41</span>
        <div style={{ flex: 1, fontSize: 12, color: "var(--ink-2)" }}>perfect. I'll be a few mins late</div>
      </div>
      <div style={{ display: "flex", gap: 8, padding: "0 14px" }}>
        <span className="wf-mono wf-small wf-muted" style={{ width: 32, flexShrink: 0 }}></span>
        <div style={{ flex: 1, fontSize: 12, color: "var(--ink-2)" }}>ok see you at 6 then 👍</div>
      </div>
      <div style={{ display: "flex", gap: 8, padding: "0 14px", justifyContent: "flex-end" }}>
        <div style={{ flex: 1, fontSize: 18, textAlign: "right" }}>🍝</div>
        <span className="wf-mono wf-small wf-muted" style={{ width: 32, flexShrink: 0, textAlign: "right" }}>10:42</span>
      </div>
    </div>
    <Composer />
  </Phone>
);

// C — Time-blocked: messages grouped into time chunks with subtle dividers
const ChatC = () => (
  <Phone>
    <ChatTopBar name="Maya Rivera" status="online" />
    <div className="wf-msgs" style={{ gap: 4 }}>
      <DaySep>10:38 — 10:42</DaySep>
      <Bubble side="them" filled text="hey are we still on for dinner?" />
      <Bubble side="me" text="yes! 6pm at the corner place?" />
      <Bubble side="them" filled text="perfect. I'll be a few mins late" />
      <Bubble side="them" filled text="ok see you at 6 then 👍" />
      <Bubble side="me" text="🍝" time="10:42" status="✓" />

      <DaySep>11:15</DaySep>
      <Bubble side="me" voice="0:24" time="11:15" status="✓✓" />
      <Bubble side="them" filled text="haha got it" />
    </div>
    <Composer variant="voice" />
  </Phone>
);

// D — Expressive: reactions, replies, media, richer interactions
const ChatD = () => (
  <Phone>
    <ChatTopBar name="Maya Rivera" status="online" accent />
    <div className="wf-msgs">
      <DaySep>Today</DaySep>
      <Bubble side="them" filled text="hey are we still on for dinner?" time="10:38" />
      <div className="wf-bubble me" style={{ paddingBottom: 4 }}>
        yes! 6pm at the corner place?
        <div className="meta">10:40 ✓✓</div>
      </div>
      <div className="wf-reactions right">❤️ 1</div>

      {/* reply quote */}
      <div className="wf-bubble them filled" style={{ borderLeft: "3px solid var(--accent)" }}>
        <div style={{ fontFamily: "var(--mono)", fontSize: 8.5, opacity: 0.6, marginBottom: 2 }}>↩ replying to "yes! 6pm…"</div>
        bring an appetite 😋
        <div className="meta">10:41</div>
      </div>

      <Bubble side="me" text="🍝🥖🍷" time="10:42" status="✓✓" />
      <div className="wf-reactions right">🔥 2 · 😂 1</div>

      {/* image preview */}
      <div className="wf-bubble them filled" style={{ padding: 4 }}>
        <Box w="180px" h={90} label="photo · menu.jpg" />
        <div className="meta" style={{ paddingRight: 4 }}>10:43</div>
      </div>
    </div>
    <Composer />
  </Phone>
);

Object.assign(window, { ChatA, ChatB, ChatC, ChatD });
