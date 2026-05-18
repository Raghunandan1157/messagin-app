// loop-screens.jsx — Loop hi-fi chat app screens (light + dark)

// ---- shared primitives ----
const LpPhone = ({ dark, children, statusTime = "9:41" }) => (
  <div className={"lp-phone" + (dark ? " lp-dark" : "")}>
    <div className="lp-status">
      <span>{statusTime}</span>
      <span className="right">
        <span>5G</span>
        <span className="batt"></span>
      </span>
    </div>
    {children}
  </div>
);

const LpAvatar = ({ initials, tint = 1, online, circle, size, src }) => {
  const cls = ["lp-avatar", "tint-" + tint];
  if (online) cls.push("online");
  if (circle) cls.push("circle");
  if (size) cls.push(size);
  return <div className={cls.join(" ")}>{initials}</div>;
};

const LpRow = ({ initials, tint, name, time, preview, unread, online, muted, typing, sent, sentRead, pinned, mediaIcon }) => (
  <div className="lp-row">
    <LpAvatar initials={initials} tint={tint} online={online} />
    <div className="body">
      <div className="nameline">
        <div className="name">{name}</div>
        <div className={"time" + (unread ? " unread" : "")}>{time}</div>
      </div>
      <div className="previewline">
        <div className={"preview" + (typing ? " typing" : "")}>
          {typing ? (
            <span>typing…</span>
          ) : (
            <>
              {sent && <span className="ticks">{sentRead ? Ic.checks : Ic.check}</span>}
              {mediaIcon && <span style={{ display: "inline-flex" }}>{mediaIcon}</span>}
              <span style={{ overflow: "hidden", textOverflow: "ellipsis" }}>{preview}</span>
            </>
          )}
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 6, flexShrink: 0 }}>
          {pinned && <span style={{ color: "var(--lp-ink-3)", display: "inline-flex" }}>{Ic.pin}</span>}
          {muted && <span className="lp-mute">{Ic.mute}</span>}
          {unread ? <span className="lp-pill">{unread}</span> : null}
        </div>
      </div>
    </div>
  </div>
);

const LpBottomNav = ({ active = 0 }) => (
  <div className="lp-bottomnav">
    {[
      { ic: Ic.chat, label: "Chats" },
      { ic: Ic.spaces, label: "Spaces" },
      { ic: Ic.calls, label: "Calls" },
      { ic: Ic.me, label: "You" },
    ].map((it, i) => (
      <div key={i} className={"lp-navitem" + (i === active ? " active" : "")}>
        {it.ic}
        <span>{it.label}</span>
      </div>
    ))}
  </div>
);

// ---------------- Chat list ----------------
const LpChatList = ({ dark }) => (
  <LpPhone dark={dark}>
    <div className="lp-appbar">
      <h1>
        <span className="lp-logo logo">
          <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M5 7c0-2 4-3 7-3s7 1 7 3-4 3-7 3-7 1-7 3 4 3 7 3 7 1 7 3-4 3-7 3-7-1-7-3"/>
          </svg>
        </span>
        Loop
      </h1>
      <div className="actions">
        <button className="lp-iconbtn">{Ic.camera}</button>
        <button className="lp-iconbtn">{Ic.search}</button>
        <button className="lp-iconbtn">{Ic.more}</button>
      </div>
    </div>

    <div className="lp-chips">
      <div className="lp-chip active">All</div>
      <div className="lp-chip count" data-count="4">Unread</div>
      <div className="lp-chip">Favorites</div>
      <div className="lp-chip">Spaces</div>
      <div className="lp-chip">@Mentions</div>
    </div>

    <div className="lp-list">
      <LpRow initials="MR" tint={1} name="Maya Rivera" time="10:42" preview="ok see you at 6 then 🍝" unread="3" online pinned />
      <LpRow initials="TR" tint={2} name="Thursday Run · 6" time="09:15" preview="Jamal: route is uploaded" unread="1" />
      <LpRow initials="DD" tint={3} name="Dad" time="08:02" typing online />
      <LpRow initials="OF" tint={4} name="Office · Floor 3" time="Yesterday" preview="Priya: lunch order anyone?" muted />
      <LpRow initials="LP" tint={5} name="Leon Park" time="Yesterday" preview="thanks for the link 👍" sent sentRead />
      <LpRow initials="ZH" tint={1} name="Zane Hu" time="Mon" preview="Voice message · 0:42" mediaIcon={Ic.mic} />
      <LpRow initials="BB" tint={2} name="Book Club" time="Sun" preview="Eve: chapter 12 done!" />
      <LpRow initials="SK" tint={3} name="Sara Kapoor" time="Sat" preview="📷 Photo" sent />
      <LpRow initials="NN" tint={4} name="Neighborhood News" time="Fri" preview="Building meeting Tuesday" muted />
    </div>

    <div className="lp-fab">{Ic.edit}</div>
    <LpBottomNav active={0} />
  </LpPhone>
);

// ---------------- 1:1 Chat ----------------
const LpChat = ({ dark }) => (
  <LpPhone dark={dark}>
    <div className="lp-chat-top">
      <span className="back">{Ic.back}</span>
      <LpAvatar initials="MR" tint={1} online />
      <div className="id">
        <span className="who">Maya Rivera</span>
        <span className="status online">online</span>
      </div>
      <div className="actions">
        <button className="lp-iconbtn ghost">{Ic.video}</button>
        <button className="lp-iconbtn ghost">{Ic.phone}</button>
        <button className="lp-iconbtn ghost">{Ic.more}</button>
      </div>
    </div>

    <div className="lp-msgs">
      <div className="lp-daysep">Today</div>
      <div className="lp-encrypted">
        {Ic.lock}<span>Messages are end-to-end encrypted. Only you and Maya can read them.</span>
      </div>

      <div className="lp-bubble them">
        hey are we still on for dinner?
        <div className="meta">10:38</div>
      </div>
      <div className="lp-bubble me">
        yes! 6pm at the corner place?
        <div className="meta">10:40 {Ic.checks}</div>
      </div>
      <div className="lp-bubble them">
        <div className="quoted">
          <div className="qname">You</div>
          yes! 6pm at the corner place?
        </div>
        perfect. I'll be a few mins late
        <div className="meta">10:41</div>
      </div>
      <div className="lp-bubble them">
        ok see you at 6 then 👍
        <div className="meta">10:42</div>
      </div>
      <div className="lp-reactions me-side">❤️ 1</div>
      <div className="lp-bubble me" style={{ padding: 4, paddingBottom: 4 }}>
        <div className="lp-imgmsg"></div>
        <div className="meta" style={{ padding: "0 6px 2px" }}>10:43 {Ic.checks}</div>
      </div>
      <div className="lp-bubble me">
        <div className="lp-voice">
          <span className="play">{Ic.play}</span>
          <div className="wave">
            {[6,10,14,18,12,16,20,14,8,12,16,20,18,12,8,14,10,16,12,8,6,10,14,18,12,16,20,14,8,12,16,20,18,12,8,14].map((h, i) => (
              <i key={i} className={i < 14 ? "played" : ""} style={{ height: h }} />
            ))}
          </div>
          <span style={{ fontSize: 11, color: "var(--lp-brand)", fontVariantNumeric: "tabular-nums" }}>0:24</span>
        </div>
        <div className="meta">10:44 {Ic.checks}</div>
      </div>
    </div>

    <div className="lp-composer">
      <div className="input">
        {Ic.emoji}
        <span className="ph">Message…</span>
        {Ic.attach}
        {Ic.camera}
      </div>
      <span className="send">{Ic.mic}</span>
    </div>
  </LpPhone>
);

// ---------------- Group Chat ----------------
const LpGroup = ({ dark }) => (
  <LpPhone dark={dark}>
    <div className="lp-chat-top">
      <span className="back">{Ic.back}</span>
      <LpAvatar initials="TR" tint={2} />
      <div className="id">
        <span className="who">Thursday Run</span>
        <span className="status">6 members · 3 online</span>
      </div>
      <div className="actions">
        <button className="lp-iconbtn ghost">{Ic.video}</button>
        <button className="lp-iconbtn ghost">{Ic.more}</button>
      </div>
    </div>

    <div className="lp-msgs">
      <div className="lp-daysep">Today</div>

      <div className="lp-bubble them">
        <div className="sender c1">Jamal</div>
        route uploaded, 8k loop 🏃
        <div className="meta">9:14</div>
      </div>
      <div className="lp-reactions">🔥 3 · 👍 2</div>

      <div className="lp-bubble them">
        <div className="sender c5">Priya</div>
        starting from the bridge?
        <div className="meta">9:15</div>
      </div>

      <div className="lp-bubble them">
        <div className="sender c2">Eve</div>
        I can carpool — 2 spots open
        <div className="meta">9:18</div>
      </div>

      <div className="lp-bubble me">
        taking one, ty 🙏
        <div className="meta">9:20 {Ic.checks}</div>
      </div>

      <div className="lp-bubble them">
        <div className="sender c3">Leon</div>
        same. see y'all at 7 ✌️
        <div className="meta">9:22</div>
      </div>

      <div className="lp-bubble them">
        <div className="sender c4">Sara</div>
        bringing snacks for after
        <div className="meta">9:31</div>
      </div>
      <div className="lp-reactions">🙌 4</div>
    </div>

    <div className="lp-composer">
      <div className="input">
        {Ic.emoji}
        <span className="ph">Message #thursday-run…</span>
        {Ic.attach}
        {Ic.camera}
      </div>
      <span className="send">{Ic.mic}</span>
    </div>
  </LpPhone>
);

// ---------------- Voice Call ----------------
const LpCall = ({ dark }) => (
  <LpPhone dark={dark}>
    <div className="lp-call">
      <div className="topinfo">
        <div className="label">{Ic.lock}<span>End-to-end encrypted</span></div>
      </div>

      <div className="who-block">
        <LpAvatar initials="MR" tint={1} size="xl" circle />
        <div className="who">Maya Rivera</div>
        <div className="timer">01:24</div>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 18, alignItems: "center" }}>
        <div className="controls">
          <div className="ctl">{Ic.mic}</div>
          <div className="ctl active">{Ic.speaker}</div>
          <div className="ctl">{Ic.videocam}</div>
          <div className="ctl">{Ic.addperson}</div>
        </div>
        <div className="controls">
          <div className="ctl end" style={{ transform: "rotate(135deg)" }}>{Ic.phone}</div>
        </div>
      </div>
    </div>
  </LpPhone>
);

// ---------------- Profile ----------------
const LpProfile = ({ dark }) => (
  <LpPhone dark={dark}>
    <div className="lp-appbar" style={{ paddingBottom: 0 }}>
      <span className="back" style={{ display: "inline-flex" }}>{Ic.back}</span>
      <div className="actions"><button className="lp-iconbtn">{Ic.edit}</button></div>
    </div>

    <div className="lp-prof-head">
      <LpAvatar initials="AC" tint={1} size="xl" circle />
      <div className="who">Alex Chen</div>
      <div className="meta">+1 555 0143 · @alexc</div>
      <div className="bio">"building little things, mostly outside"</div>
    </div>

    <div className="lp-prof-actions">
      <div className="a">{Ic.chat}<span>Message</span></div>
      <div className="a">{Ic.phone}<span>Call</span></div>
      <div className="a">{Ic.videocam}<span>Video</span></div>
      <div className="a">{Ic.search}<span>Search</span></div>
    </div>

    <div style={{ flex: 1, overflow: "hidden" }}>
      <div className="lp-prof-section">
        <div className="lp-prof-row">
          <span className="ico">{Ic.bell}</span>
          <span className="label">Notifications</span>
          <span className="val">All</span>
          <span className="chev">{Ic.chevron}</span>
        </div>
        <div className="lp-prof-row">
          <span className="ico">{Ic.star}</span>
          <span className="label">Starred messages</span>
          <span className="val">12</span>
          <span className="chev">{Ic.chevron}</span>
        </div>
        <div className="lp-prof-row">
          <span className="ico">{Ic.shield}</span>
          <span className="label">Privacy & Encryption</span>
          <span className="val">verified ✓</span>
          <span className="chev">{Ic.chevron}</span>
        </div>
      </div>

      <div className="lp-prof-section">
        <div className="lp-prof-row">
          <span className="ico" style={{ background: "rgba(232,161,58,0.18)", color: "#c47e1c" }}>📷</span>
          <span className="label">Media, Links & Docs</span>
          <span className="val">218</span>
          <span className="chev">{Ic.chevron}</span>
        </div>
        <div className="lp-prof-row">
          <span className="ico" style={{ background: "rgba(208,74,58,0.15)", color: "#d04a3a" }}>{Ic.mute}</span>
          <span className="label" style={{ color: "#d04a3a" }}>Block contact</span>
        </div>
      </div>
    </div>
  </LpPhone>
);

Object.assign(window, { LpChatList, LpChat, LpGroup, LpCall, LpProfile });
