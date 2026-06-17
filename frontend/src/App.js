import { useEffect, useState } from "react";
import "@/App.css";
import "@/landing.css";
import axios from "axios";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

function formatBytes(b) {
  if (b < 1024) return b + " B";
  if (b < 1024 * 1024) return (b / 1024).toFixed(1) + " KB";
  return (b / 1024 / 1024).toFixed(2) + " MB";
}

const RESOURCE_META = {
  mechanic_tablet: {
    accent: "var(--mint)",
    headline: "An in-car tuning tablet, gated by job.",
    sub: "One item. Sit in any vehicle. Open the tablet. Tune looks, engine, stance — tire width, ride height, camber. Mechanic-only, with a configurable allowed-jobs list so you can add more roles later.",
    features: [
      ["01", "Tablet Item", "Single ox_inventory item triggers the UI"],
      ["02", "Job Gating", "Configurable AllowedJobs[] list, easy to extend"],
      ["03", "Looks", "Paint, neons, xenons, plates"],
      ["04", "Engine", "Engine, brakes, trans, suspension, turbo levels"],
      ["05", "Stance", "Tire width, ride height, camber F+R, track width sliders"],
      ["06", "Wheels", "Wheel type + design index"],
      ["07", "Persistence", "All values saved per plate in MySQL"],
      ["08", "Fake-Fail Mode", "Non-mechanics get a believable error animation"],
    ],
    commands: [
      ["/mechtab", "Open the tablet manually (testing)"],
      ["use item", "Use the mechanic_tablet item from inventory while seated as the driver"],
    ],
    install: `# 1. Copy folder
resources/[scripts]/mechanic_tablet

# 2. Import database schema
mysql -u root -p qbx < sql/install.sql

# 3. Add to ox_inventory/data/items.lua
['mechanic_tablet'] = {
    label = 'Mechanic Tablet', weight = 500,
    stack = false, close = true,
    client = { export = 'mechanic_tablet.useMechanicTablet' }
}

# 4. ensure mechanic_tablet  (server.cfg)
# 5. /giveitem <id> mechanic_tablet 1
# 6. Get in a car & use it.`,
  },
  dusa_mechanic_qbx: {
    accent: "var(--accent)",
    headline: "A full dusa-style shop system.",
    sub: "Multi-shop garages with 3D vehicle lifts, society/boss menus, towing, diagnostic scanner, NOS with LSHIFT boost. The complete mechanic experience.",
    features: [
      ["01", "Repair Bay", "Tires, body, engine, full restore, wash"],
      ["02", "Performance", "Engine, Brakes, Trans, Susp, Turbo, Armor"],
      ["03", "Visual", "Paint, Pearl, Neons, Xenons, Wheels, Smoke"],
      ["04", "NOS", "Install, refill, in-game HUD, LSHIFT boost"],
      ["05", "Vehicle Lifts", "3D prop lifts at each shop"],
      ["06", "Boss & Society", "Hire, fire, promote, deposit, withdraw"],
      ["07", "Towing", "Flatbed truck, hook, deliver to impound"],
      ["08", "Diagnostic", "OBD-II scanner item with wear stats"],
    ],
    commands: [
      ["/mechmenu", "Open mechanic NUI on closest vehicle"],
      ["/mechduty", "Toggle on/off duty"],
      ["/mechtow",  "Spawn a flatbed tow truck"],
      ["/mechhook", "Hook nearest vehicle to truck"],
      ["LSHIFT",    "Activate NOS while seated"],
    ],
    install: `# 1. Copy folder
resources/[scripts]/dusa_mechanic_qbx

# 2. Import database schema
mysql -u root -p qbx < sql/install.sql

# 3. Add 7 items to ox_inventory/data/items.lua
# repairkit, advancedrepairkit, cleaningkit,
# nos_bottle, nos_refill, diagnostic_scanner, towrope

# 4. ensure dusa_mechanic_qbx  (server.cfg)
# 5. Restart, drive to LSC
# 6. /mechduty -> go on duty
#    /mechmenu -> open NUI on closest car`,
  },
};

const STACK = [
  { k: "qbx_core",   v: "framework" },
  { k: "ox_lib",     v: "menus + callbacks" },
  { k: "ox_target",  v: "interactions" },
  { k: "ox_inventory", v: "items + stash" },
  { k: "oxmysql",    v: "database" },
];

function App() {
  const [resources, setResources] = useState([]);
  const [activeKey, setActiveKey] = useState("mechanic_tablet");

  useEffect(() => {
    axios.get(`${API}/resources`).then(r => setResources(r.data || [])).catch(() => {});
  }, []);

  const active   = resources.find(r => r.key === activeKey) || resources[0];
  const activeKeyResolved = active?.key || activeKey;
  const meta = RESOURCE_META[activeKeyResolved] || RESOURCE_META.mechanic_tablet;

  return (
    <div className="dusa-landing" style={{ "--active": meta.accent }}>
      {/* HEADER */}
      <header className="hdr" data-testid="landing-header">
        <div className="hdr-left">
          <div className="logo-mark" style={{ background: meta.accent }}>FM</div>
          <div>
            <div className="hdr-title">FIVEM MECHANIC SUITE</div>
            <div className="hdr-sub">2 RESOURCES · QBX + OX</div>
          </div>
        </div>
        <div className="hdr-right">
          {active && (
            <a className="btn primary" href={`${API}${active.download_path}`} data-testid="hero-download-btn">
              DOWNLOAD <span className="size">{formatBytes(active.total_size)}</span>
            </a>
          )}
        </div>
      </header>

      {/* RESOURCE SWITCHER */}
      <div className="switcher" data-testid="switcher">
        {resources.map(r => (
          <button key={r.key}
                  className={`sw ${r.key === activeKeyResolved ? "on" : ""}`}
                  onClick={() => setActiveKey(r.key)}
                  data-testid={`switch-${r.key}`}>
            <span className="sw-k">{r.key}</span>
            <span className="sw-l">{r.label}</span>
            <span className="sw-s">{r.file_count} files · {formatBytes(r.total_size)}</span>
          </button>
        ))}
      </div>

      {/* HERO */}
      {active && (
        <section className="hero" data-testid="hero-section">
          <div className="hero-grid">
            <div>
              <div className="kicker" style={{ borderColor: meta.accent, color: meta.accent, background: "transparent" }}>
                <span className="dot" style={{ background: meta.accent, boxShadow: `0 0 10px ${meta.accent}` }} />
                {active.key.replace("_", " ").toUpperCase()}
              </div>
              <h1 className="hero-title">
                {meta.headline.split(" ").slice(0, 4).join(" ")}{" "}
                <span style={{ color: meta.accent }}>
                  {meta.headline.split(" ").slice(4).join(" ")}
                </span>
              </h1>
              <p className="hero-lead">{meta.sub}</p>
              <div className="hero-actions">
                <a className="btn primary lg" href={`${API}${active.download_path}`} data-testid="dl-btn">
                  DOWNLOAD .ZIP
                </a>
                <a className="btn ghost lg" href="#preview" data-testid="goto-preview">SCROLL TO LIVE UI ↓</a>
              </div>
              <div className="stack-row">
                {STACK.map(s => (
                  <div key={s.k} className="stack-pill">
                    <b>{s.k}</b><span>{s.v}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="hero-card">
              <div className="hero-card-h">
                <div className="led" style={{ background: meta.accent, boxShadow: `0 0 10px ${meta.accent}` }} />
                <span>{active.key.toUpperCase()} · v1.0</span>
              </div>
              <pre className="code">{meta.install}</pre>
            </div>
          </div>
        </section>
      )}

      {/* FEATURES */}
      <section className="features" data-testid="features-section">
        <h2 className="sec-title">MODULES</h2>
        <div className="features-grid">
          {meta.features.map(([n, t, d]) => (
            <div className="feature" key={n} data-testid={`feature-${n}`}>
              <div className="feature-n" style={{ color: meta.accent }}>{n}</div>
              <div className="feature-t">{t}</div>
              <div className="feature-d">{d}</div>
            </div>
          ))}
        </div>
      </section>

      {/* PREVIEW */}
      <section className="preview-sec" id="preview" data-testid="preview-section">
        <div className="preview-h">
          <h2 className="sec-title">LIVE NUI PREVIEW</h2>
          <p className="sec-sub">This is the actual HTML/CSS/JS that ships with the resource and renders inside FiveM.</p>
        </div>
        <div className="preview-frame">
          {active && (
            <iframe
              key={active.key}
              title={`${active.key}-preview`}
              src={`${BACKEND_URL}${active.preview_path}`}
              data-testid="preview-iframe"
            />
          )}
        </div>
      </section>

      {/* COMMANDS */}
      <section className="commands">
        <h2 className="sec-title">COMMANDS / USAGE</h2>
        <div className="commands-grid">
          {meta.commands.map(([c, d], i) => (
            <div key={i} className="cmd-row" data-testid={`cmd-${i}`}
                 style={{ borderLeftColor: meta.accent }}>
              <code style={{ color: meta.accent }}>{c}</code>
              <span>{d}</span>
            </div>
          ))}
        </div>
      </section>

      {/* FOOTER */}
      <footer className="ftr">
        <span>FIVEM MECHANIC SUITE · QBX + OX · MIT LICENSE</span>
        {active && (
          <a href={`${API}${active.download_path}`} data-testid="footer-download">
            DOWNLOAD {active.key.toUpperCase()}.ZIP
          </a>
        )}
      </footer>
    </div>
  );
}

export default App;
