// wf-screens-list.jsx — Chat list / inbox variations

// A — Classic vertical list with avatars, search, tabs, FAB
const ListA = () => (
  <Phone>
    <TopBar
      title="Chats"
      underline
      right={<><Icon glyph="🔍" /><Icon glyph="✎" variant="accent" /></>}
    />
    <div className="wf-search dashed">🔍 Search messages, people</div>
    <div className="wf-tabs">
      <div className="tab active">All</div>
      <div className="tab">Unread</div>
      <div className="tab">Groups</div>
      <div className="tab">@</div>
    </div>
    <div className="wf-list">
      <ChatRow initials="MR" name="Maya Rivera" time="10:42" preview="ok see you at 6 then 👍" unread="3" online />
      <ChatRow initials="JT" name="Jamal · Thursday Run" time="09:15" preview="route is uploaded" unread="1" />
      <ChatRow initials="DD" name="Dad" time="Yesterday" preview="" typing online />
      <ChatRow initials="OF" name="Office Floor 3" time="Yesterday" preview="Priya: lunch order?" muted />
      <ChatRow initials="LP" name="Leon Park" time="Tue" preview="thanks for the link" />
      <ChatRow initials="ZH" name="Zane Hu" time="Mon" preview="🎙 0:42 voice message" />
      <ChatRow initials="BB" name="Book Club" time="Sun" preview="Eve: chapter 12 done" />
    </div>
    <DefaultNav active={0} />
  </Phone>
);

// B — Card-stack: each chat is a soft card with media/last preview
const ListB = () => (
  <Phone>
    <TopBar title="Loop" underline right={<><Icon glyph="🔍" /><Icon glyph="+" variant="accent" /></>} />
    <div style={{ padding: "6px 12px", display: "flex", flexDirection: "column", gap: 8, overflow: "hidden", flex: 1 }}>
      {/* Pinned: featured card with media preview */}
      <div style={{ border: "1.5px solid var(--ink)", borderRadius: 14, padding: 10, display: "flex", gap: 10, background: "var(--paper-2)" }}>
        <Avatar initials="MR" online />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: "flex", justifyContent: "space-between", fontFamily: "var(--hand)", fontWeight: 700, fontSize: 15 }}>
            <span>Maya Rivera</span>
            <span className="wf-mono wf-small wf-muted">10:42</span>
          </div>
          <div style={{ fontSize: 11, color: "var(--ink-2)", marginTop: 2 }}>ok see you at 6 then 👍</div>
          <Box w="100%" h={48} label="image · IMG_2294.jpg" style={{ marginTop: 6 }} />
        </div>
      </div>

      <div style={{ border: "1.5px solid var(--ink)", borderRadius: 14, padding: 10, display: "flex", gap: 10 }}>
        <Avatar initials="JT" />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: "flex", justifyContent: "space-between", fontFamily: "var(--hand)", fontWeight: 700, fontSize: 15 }}>
            <span>Thursday Run</span>
            <span className="wf-mono wf-small wf-muted">09:15</span>
          </div>
          <div style={{ fontSize: 11, color: "var(--ink-2)", marginTop: 2, display: "flex", justifyContent: "space-between" }}>
            <span>Jamal: route is uploaded</span>
            <span className="wf-pill">1</span>
          </div>
        </div>
      </div>

      <div style={{ border: "1.4px dashed var(--line-soft)", borderRadius: 14, padding: 8, display: "flex", gap: 10, alignItems: "center" }}>
        <Avatar initials="DD" size="sm" online />
        <div style={{ flex: 1, fontSize: 12 }}>Dad · <em style={{ color: "var(--accent)" }}>typing…</em></div>
        <span className="wf-mono wf-small wf-muted">now</span>
      </div>

      <div style={{ border: "1.4px dashed var(--line-soft)", borderRadius: 14, padding: 8, display: "flex", gap: 10, alignItems: "center" }}>
        <Avatar initials="OF" size="sm" />
        <div style={{ flex: 1, fontSize: 12 }}>Office Floor 3</div>
        <span className="wf-muted wf-small">🔕</span>
      </div>

      <div style={{ border: "1.4px dashed var(--line-soft)", borderRadius: 14, padding: 8, display: "flex", gap: 10, alignItems: "center" }}>
        <Avatar initials="LP" size="sm" />
        <div style={{ flex: 1, fontSize: 12 }}>Leon Park</div>
      </div>
    </div>
    <DefaultNav active={0} />
  </Phone>
);

// C — Time-grouped: clear sections by recency, denser rows
const ListC = () => (
  <Phone>
    <TopBar title="Inbox" right={<><Icon glyph="🔍" /><Icon glyph="✎" variant="accent" /></>} />
    <div className="wf-list" style={{ paddingTop: 0 }}>
      <div style={{ padding: "6px 14px 2px", fontFamily: "var(--hand)", fontSize: 11, color: "var(--ink-3)", letterSpacing: 1 }}>TODAY</div>
      <ChatRow initials="MR" name="Maya Rivera" time="10:42" preview="ok see you at 6 then 👍" unread="3" online />
      <ChatRow initials="JT" name="Thursday Run" time="09:15" preview="Jamal: route is uploaded" unread="1" />
      <ChatRow initials="DD" name="Dad" time="08:02" preview="" typing online />

      <div style={{ padding: "10px 14px 2px", fontFamily: "var(--hand)", fontSize: 11, color: "var(--ink-3)", letterSpacing: 1 }}>YESTERDAY</div>
      <ChatRow initials="OF" name="Office Floor 3" time="17:48" preview="Priya: lunch order?" muted />
      <ChatRow initials="LP" name="Leon Park" time="13:11" preview="thanks for the link" />

      <div style={{ padding: "10px 14px 2px", fontFamily: "var(--hand)", fontSize: 11, color: "var(--ink-3)", letterSpacing: 1 }}>EARLIER</div>
      <ChatRow initials="ZH" name="Zane Hu" time="Mon" preview="🎙 0:42 voice message" />
      <ChatRow initials="BB" name="Book Club" time="Sun" preview="Eve: chapter 12 done" />
    </div>
    <DefaultNav active={0} />
  </Phone>
);

// D — Novel "strand" layout: conversations as a flowing vertical thread
const ListD = () => (
  <Phone>
    <TopBar title="Loop" underline right={<><Icon glyph="🔎" /><Icon glyph="✎" variant="accent" /></>} />
    <div className="wf-search dashed">🔍 Search</div>
    <div style={{ flex: 1, overflow: "hidden", paddingTop: 6 }}>
      <div className="wf-strand">
        <div className="wf-strand-node unread"></div>
        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <Avatar initials="MR" size="sm" online />
          <div style={{ flex: 1 }}>
            <div className="wf-hand" style={{ fontWeight: 700, fontSize: 14 }}>Maya Rivera</div>
            <div style={{ fontSize: 11, color: "var(--ink-2)" }}>"ok see you at 6 then 👍"</div>
          </div>
          <span className="wf-pill">3</span>
        </div>
      </div>

      <div className="wf-strand">
        <div className="wf-strand-node unread"></div>
        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <Avatar initials="JT" size="sm" />
          <div style={{ flex: 1 }}>
            <div className="wf-hand" style={{ fontWeight: 700, fontSize: 14 }}>Thursday Run · 6</div>
            <div style={{ fontSize: 11, color: "var(--ink-2)" }}>route is uploaded</div>
          </div>
          <span className="wf-mono wf-small wf-muted">9:15</span>
        </div>
      </div>

      <div className="wf-strand">
        <div className="wf-strand-node"></div>
        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <Avatar initials="DD" size="sm" online />
          <div style={{ flex: 1 }}>
            <div className="wf-hand" style={{ fontWeight: 700, fontSize: 14 }}>Dad</div>
            <div style={{ fontSize: 11 }}><em style={{ color: "var(--accent)" }}>typing…</em></div>
          </div>
        </div>
      </div>

      <div className="wf-strand">
        <div className="wf-strand-node"></div>
        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <Avatar initials="LP" size="sm" />
          <div style={{ flex: 1 }}>
            <div className="wf-hand" style={{ fontWeight: 700, fontSize: 14 }}>Leon Park</div>
            <div style={{ fontSize: 11, color: "var(--ink-2)" }}>thanks for the link</div>
          </div>
          <span className="wf-mono wf-small wf-muted">Tue</span>
        </div>
      </div>

      <div className="wf-strand">
        <div className="wf-strand-node"></div>
        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <Avatar initials="BB" size="sm" />
          <div style={{ flex: 1 }}>
            <div className="wf-hand" style={{ fontWeight: 700, fontSize: 14 }}>Book Club</div>
            <div style={{ fontSize: 11, color: "var(--ink-2)" }}>Eve: chapter 12 done</div>
          </div>
          <span className="wf-mono wf-small wf-muted">Sun</span>
        </div>
      </div>
    </div>
    <DefaultNav active={0} />
  </Phone>
);

Object.assign(window, { ListA, ListB, ListC, ListD });
