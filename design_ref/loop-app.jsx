// loop-app.jsx — main canvas composition for Loop hi-fi

const { useEffect } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "brand": "#0f6b56",
  "brandDark": "#14a085"
}/*EDITMODE-END*/;

const BRAND_PALETTES = [
  ["#0f6b56", "#14a085"],  // forest teal (default)
  ["#1f6b48", "#2dab6b"],  // emerald
  ["#0a6373", "#19a3b8"],  // ocean teal
  ["#3a5fd9", "#5681ff"],  // indigo
  ["#7048bf", "#9a72e0"],  // violet
  ["#c64a30", "#e8744d"],  // sunset
];

function LoopApp() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  useEffect(() => {
    const css = `
      .lp-phone { --lp-brand: ${t.brand}; }
      .lp-phone.lp-dark { --lp-brand: ${t.brandDark}; }
    `;
    let s = document.getElementById("lp-brand-override");
    if (!s) {
      s = document.createElement("style");
      s.id = "lp-brand-override";
      document.head.appendChild(s);
    }
    s.textContent = css;
  }, [t.brand, t.brandDark]);

  return (
    <>
      <DesignCanvas>
        <DCSection id="intro" title="Loop · hi-fi messaging" subtitle="Distinct identity, familiar mental model. Light + dark side-by-side.">
          <DCArtboard id="brief" label="System notes" width={380} height={400}>
            <div style={{ padding: 24, fontFamily: "Inter, system-ui, sans-serif", color: "#0f1a17", height: "100%", background: "#f3efe6", display: "flex", flexDirection: "column", gap: 14 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <div style={{ width: 36, height: 36, borderRadius: 12, background: t.brand, display: "inline-flex", alignItems: "center", justifyContent: "center" }}>
                  <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" width="20" height="20"><path d="M5 7c0-2 4-3 7-3s7 1 7 3-4 3-7 3-7 1-7 3 4 3 7 3 7 1 7 3-4 3-7 3-7-1-7-3"/></svg>
                </div>
                <span style={{ fontWeight: 700, fontSize: 24, letterSpacing: "-0.5px" }}>Loop</span>
              </div>
              <div style={{ fontSize: 14, lineHeight: 1.5, color: "#4a5650" }}>
                A messaging app with its own identity — forest-teal brand, soft-grain backgrounds, custom bubble & icon language. Same mental model people already know, original visual system.
              </div>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, fontSize: 12, marginTop: 4 }}>
                <Swatch hex={t.brand} name="brand" />
                <Swatch hex={t.brandDark} name="brand · dark" />
                <Swatch hex="#daede5" name="brand tint" />
                <Swatch hex="#e8a13a" name="accent" />
                <Swatch hex="#f3efe6" name="paper" border />
                <Swatch hex="#0a1310" name="ink · dark" />
              </div>
              <div style={{ fontSize: 12, color: "#8a9690", marginTop: "auto", lineHeight: 1.4 }}>
                Type: Plus Jakarta Sans (display) + Inter (body). Drag any board to reorder. Open Tweaks to recolor.
              </div>
            </div>
          </DCArtboard>
        </DCSection>

        <DCSection id="list" title="① Chat list" subtitle="Inbox · light & dark">
          <DCArtboard id="list-light" label="Light" width={380} height={780}>
            <LpChatList />
          </DCArtboard>
          <DCArtboard id="list-dark" label="Dark" width={380} height={780}>
            <LpChatList dark />
          </DCArtboard>
        </DCSection>

        <DCSection id="chat" title="② 1:1 conversation" subtitle="Messages, voice, media, encryption notice">
          <DCArtboard id="chat-light" label="Light" width={380} height={780}>
            <LpChat />
          </DCArtboard>
          <DCArtboard id="chat-dark" label="Dark" width={380} height={780}>
            <LpChat dark />
          </DCArtboard>
        </DCSection>

        <DCSection id="group" title="③ Group conversation" subtitle="Color-coded senders, reactions">
          <DCArtboard id="group-light" label="Light" width={380} height={780}>
            <LpGroup />
          </DCArtboard>
          <DCArtboard id="group-dark" label="Dark" width={380} height={780}>
            <LpGroup dark />
          </DCArtboard>
        </DCSection>

        <DCSection id="call" title="④ Voice call & Profile" subtitle="Encrypted call screen + contact profile">
          <DCArtboard id="call-light" label="Call · Light" width={380} height={780}>
            <LpCall />
          </DCArtboard>
          <DCArtboard id="call-dark" label="Call · Dark" width={380} height={780}>
            <LpCall dark />
          </DCArtboard>
          <DCArtboard id="profile-light" label="Profile · Light" width={380} height={780}>
            <LpProfile />
          </DCArtboard>
          <DCArtboard id="profile-dark" label="Profile · Dark" width={380} height={780}>
            <LpProfile dark />
          </DCArtboard>
        </DCSection>
      </DesignCanvas>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Brand color">
          <TweakColor
            label="Palette"
            value={[t.brand, t.brandDark]}
            options={BRAND_PALETTES}
            onChange={(v) => setTweak({ brand: v[0], brandDark: v[1] })}
          />
        </TweakSection>
      </TweaksPanel>
    </>
  );
}

const Swatch = ({ hex, name, border }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
    <div style={{ width: 26, height: 26, borderRadius: 8, background: hex, border: border ? "1px solid rgba(0,0,0,0.12)" : "none" }} />
    <div style={{ display: "flex", flexDirection: "column", lineHeight: 1.2 }}>
      <span style={{ fontWeight: 600, fontSize: 11 }}>{name}</span>
      <span style={{ fontFamily: "ui-monospace, monospace", fontSize: 10, color: "#8a9690" }}>{hex}</span>
    </div>
  </div>
);

const root2 = ReactDOM.createRoot(document.getElementById("root"));
root2.render(<LoopApp />);
