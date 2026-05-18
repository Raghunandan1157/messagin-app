// wf-app.jsx — main canvas composition

const { useState, useEffect } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#e85a2c",
  "paper": "#faf7f1",
  "font": "Patrick Hand",
  "density": "comfortable",
  "showAnnotations": true
}/*EDITMODE-END*/;

const ACCENT_OPTIONS = ["#e85a2c", "#2a6f5a", "#3a5fd9", "#1a1815"];
const PAPER_OPTIONS = ["#faf7f1", "#ffffff", "#f0ece2", "#1a1815"];
const FONT_OPTIONS = ["Patrick Hand", "Caveat", "Architects Daughter", "Kalam"];

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  // Apply tweaks to :root
  useEffect(() => {
    const r = document.documentElement;
    r.style.setProperty("--accent", t.accent);
    r.style.setProperty("--paper", t.paper);
    // when paper is near-black, flip ink for legibility
    const dark = t.paper === "#1a1815";
    r.style.setProperty("--ink", dark ? "#faf7f1" : "#1a1815");
    r.style.setProperty("--ink-2", dark ? "#c8c2b6" : "#4a463f");
    r.style.setProperty("--ink-3", dark ? "#8a857c" : "#8a857c");
    r.style.setProperty("--paper-2", dark ? "#2a2520" : "#f3eee4");
    r.style.setProperty("--line", dark ? "#faf7f1" : "#1a1815");
    r.style.setProperty("--line-faint", dark ? "rgba(250,247,241,0.2)" : "rgba(26,24,21,0.2)");
    r.style.setProperty("--line-soft", dark ? "rgba(250,247,241,0.45)" : "rgba(26,24,21,0.45)");
    r.style.setProperty("--body", `"${t.font}", cursive`);
  }, [t.accent, t.paper, t.font]);

  return (
    <>
      <DesignCanvas>
        <DCIntro />

        <DCSection id="list" title="① Chat list / Inbox" subtitle="How conversations are surfaced & scanned">
          <DCArtboard id="list-a" label="A · Classic list" width={300} height={620}>
            <ListA />
          </DCArtboard>
          <DCArtboard id="list-b" label="B · Card stack + media" width={300} height={620}>
            <ListB />
          </DCArtboard>
          <DCArtboard id="list-c" label="C · Time-grouped" width={300} height={620}>
            <ListC />
          </DCArtboard>
          <DCArtboard id="list-d" label="D · Strand / thread (novel)" width={300} height={620}>
            <ListD />
          </DCArtboard>
        </DCSection>

        <DCSection id="chat" title="② 1:1 conversation" subtitle="How messages read & flow">
          <DCArtboard id="chat-a" label="A · Bubbles, classic" width={300} height={620}>
            <ChatA />
          </DCArtboard>
          <DCArtboard id="chat-b" label="B · Text rail, no bubbles" width={300} height={620}>
            <ChatB />
          </DCArtboard>
          <DCArtboard id="chat-c" label="C · Time-blocked groups" width={300} height={620}>
            <ChatC />
          </DCArtboard>
          <DCArtboard id="chat-d" label="D · Expressive (reactions, replies)" width={300} height={620}>
            <ChatD />
          </DCArtboard>
        </DCSection>

        <DCSection id="group" title="③ Group conversation" subtitle="Many voices, less noise">
          <DCArtboard id="group-a" label="A · Color-coded senders" width={300} height={620}>
            <GroupA />
          </DCArtboard>
          <DCArtboard id="group-b" label="B · Threads + reactions" width={300} height={620}>
            <GroupB />
          </DCArtboard>
          <DCArtboard id="group-c" label="C · Compact / IRC-feel" width={300} height={620}>
            <GroupC />
          </DCArtboard>
        </DCSection>

        <DCSection id="other" title="④ Supporting screens" subtitle="Calling, identity, settings">
          <DCArtboard id="call" label="Voice call" width={300} height={620}>
            <CallScreen />
          </DCArtboard>
          <DCArtboard id="profile" label="Profile / settings" width={300} height={620}>
            <ProfileScreen />
          </DCArtboard>
        </DCSection>

        <DCPostIt top={30} left={40} rotate={-2}>
          {"Wireframes — exploring shape & flow, not final visuals.\nDouble-click any board to focus. Drag to reorder."}
        </DCPostIt>
      </DesignCanvas>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Palette">
          <TweakColor label="Accent" value={t.accent} options={ACCENT_OPTIONS} onChange={(v) => setTweak("accent", v)} />
          <TweakColor label="Paper" value={t.paper} options={PAPER_OPTIONS} onChange={(v) => setTweak("paper", v)} />
        </TweakSection>
        <TweakSection label="Type">
          <TweakSelect label="Hand font" value={t.font} options={FONT_OPTIONS} onChange={(v) => setTweak("font", v)} />
        </TweakSection>
      </TweaksPanel>
    </>
  );
}

const DCIntro = () => (
  <DCSection id="intro" title="Loop · chat app wireframes" subtitle="Low-fi exploration. 4 directions per screen.">
    <DCArtboard id="brief" label="Brief" width={340} height={300}>
      <div style={{ padding: 20, fontFamily: "var(--body)", color: "var(--ink)", height: "100%", background: "var(--paper)", display: "flex", flexDirection: "column", gap: 10 }}>
        <div className="wf-hand" style={{ fontSize: 22, fontWeight: 700 }}>
          <span className="wf-underline">The ask</span>
        </div>
        <div style={{ fontSize: 13, lineHeight: 1.5 }}>
          Design a personal messaging app — 1:1, groups, voice. Familiar mental model, original look.
        </div>
        <div className="wf-hand" style={{ fontSize: 16, marginTop: 6, fontWeight: 700 }}>What we'll explore</div>
        <ul style={{ margin: 0, paddingLeft: 18, fontSize: 12, lineHeight: 1.6 }}>
          <li>Inbox structure — list vs. cards vs. strand</li>
          <li>Message reading rhythm — bubbles vs. rail vs. blocks</li>
          <li>Group signal — color, threads, density</li>
          <li>Calling + identity surfaces</li>
        </ul>
        <div className="wf-mono wf-muted" style={{ fontSize: 10, marginTop: "auto" }}>open Tweaks ↗ to swap accent / paper / font</div>
      </div>
    </DCArtboard>
    <DCArtboard id="legend" label="Legend" width={260} height={300}>
      <div style={{ padding: 18, fontFamily: "var(--body)", color: "var(--ink)", height: "100%", background: "var(--paper)", display: "flex", flexDirection: "column", gap: 10 }}>
        <div className="wf-hand" style={{ fontSize: 18, fontWeight: 700 }}>Legend</div>
        <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12 }}>
          <div className="wf-avatar sm">M</div><span>avatar / initials</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12 }}>
          <span className="wf-pill">3</span><span>unread count</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12 }}>
          <span className="wf-icon">A</span><span>icon placeholder</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12 }}>
          <div style={{ width: 18, height: 18, background: "var(--accent)", borderRadius: 4 }} />
          <span>accent — primary action / "me"</span>
        </div>
        <div style={{ fontSize: 11, color: "var(--ink-3)", marginTop: 6, fontFamily: "var(--mono)" }}>
          hatched boxes = image / media placeholders
        </div>
      </div>
    </DCArtboard>
  </DCSection>
);

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(<App />);
