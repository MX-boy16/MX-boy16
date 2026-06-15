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

const FEATURES = [
  { n: "01", t: "Repair Bay", d: "Tires, windows, body, engine, full restore & wash" },
  { n: "02", t: "Performance Tuning", d: "Engine, Brakes, Transmission, Suspension, Turbo, Armor" },
  { n: "03", t: "Visual Customization", d: "Paint, Pearl, Neons, Xenons, Wheels, Smoke, Plates" },
  { n: "04", t: "NOS / Nitrous", d: "Install, refill, in-game HUD, LSHIFT boost keybind" },
  { n: "05", t: "Vehicle Lifts", d: "3D lift props with raise/lower animation at each shop" },
  { n: "06", t: "Boss & Society", d: "Hire, fire, promote, deposit, withdraw, society funds" },
  { n: "07", t: "Towing", d: "Spawn flatbed, hook vehicle, deliver to impound for payout" },
  { n: "08", t: "Diagnostic Scanner", d: "OBD-II item reads body, engine, wear, NOS state" },
];

const STACK = [
  { k: "qbx_core", v: "framework" },
  { k: "ox_lib", v: "menus + callbacks" },
  { k: "ox_target", v: "interactions" },
  { k: "ox_inventory", v: "items + stash" },
  { k: "oxmysql", v: "database" },
];

const COMMANDS = [
  { c: "/mechmenu", d: "Open mechanic NUI for closest vehicle (testing)" },
  { c: "/mechduty", d: "Toggle on/off duty as a mechanic" },
  { c: "/mechtow",  d: "Spawn a flatbed tow truck (on-duty mechs only)" },
  { c: "/mechhook", d: "Hook the nearest vehicle to the tow truck" },
  { c: "LSHIFT",    d: "Activate NOS while seated in a NOS-equipped vehicle" },
];

function App() {
  const [manifest, setManifest] = useState({ files: [], total_size: 0, file_count: 0 });
  const [previewOpen, setPreviewOpen] = useState(false);

  useEffect(() => {
    axios.get(`${API}/resource/manifest`).then(r => setManifest(r.data)).catch(() => {});
  }, []);

  return (
    <div className="dusa-landing">
      {/* HEADER */}
      <header className="hdr" data-testid="landing-header">
        <div className="hdr-left">
          <div className="logo-mark">DM</div>
          <div>
            <div className="hdr-title">DUSA MECHANIC</div>
            <div className="hdr-sub">FiveM Resource · QBX + OX</div>
          </div>
        </div>
        <div className="hdr-right">
          <a className="btn ghost" href="#preview" data-testid="nav-preview">PREVIEW UI</a>
          <a className="btn" href={`${API}/resource/download`} data-testid="download-btn">
            DOWNLOAD .ZIP <span className="size">{formatBytes(manifest.total_size)}</span>
          </a>
        </div>
      </header>

      {/* HERO */}
      <section className="hero">
        <div className="hero-grid">
          <div>
            <div className="kicker">
              <span className="dot" /> READY TO DROP IN · {manifest.file_count} files
            </div>
            <h1 className="hero-title">
              A complete <span className="accent">dusa-style</span><br />
              mechanic system for<br />
              <span className="cyan">QBX + OX.</span>
            </h1>
            <p className="hero-lead">
              Repair, tune, paint, NOS, tow, scan. Multi-shop lifts, society boss menu,
              custom NUI. Everything you need to run a mechanic job — server-validated,
              database-backed, single resource.
            </p>
            <div className="hero-actions">
              <a className="btn primary lg" href={`${API}/resource/download`} data-testid="hero-download-btn">
                DOWNLOAD RESOURCE
              </a>
              <button className="btn ghost lg" onClick={() => setPreviewOpen(true)} data-testid="hero-preview-btn">
                OPEN LIVE UI PREVIEW
              </button>
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
              <div className="led" />
              <span>DUSA_MECHANIC_OS v1.0</span>
            </div>
            <pre className="code">
{`# 1. Copy folder to resources/
resources/[scripts]/dusa_mechanic_qbx

# 2. Import database schema
mysql -u root -p qbx < sql/install.sql

# 3. Add to server.cfg (after ox_*)
ensure dusa_mechanic_qbx

# 4. Add items to ox_inventory
repairkit, nos_bottle, diagnostic_scanner ...

# 5. Restart server, drive to LSC
/mechduty   -> go on duty
/mechmenu   -> open NUI on closest car`}
            </pre>
          </div>
        </div>
      </section>

      {/* FEATURES */}
      <section className="features" data-testid="features-section">
        <h2 className="sec-title">8 MODULES · ONE RESOURCE</h2>
        <div className="features-grid">
          {FEATURES.map((f) => (
            <div className="feature" key={f.n} data-testid={`feature-${f.n}`}>
              <div className="feature-n">{f.n}</div>
              <div className="feature-t">{f.t}</div>
              <div className="feature-d">{f.d}</div>
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
          <iframe
            title="dusa-nui-preview"
            src={`${BACKEND_URL}/api/preview/index.html`}
            data-testid="preview-iframe"
          />
          <div className="preview-overlay-hint">
            Click on the iframe and the UI is fully interactive. Tabs, color pickers, hover states, animations — everything works.
          </div>
        </div>
      </section>

      {/* COMMANDS */}
      <section className="commands">
        <h2 className="sec-title">COMMANDS & KEYBINDS</h2>
        <div className="commands-grid">
          {COMMANDS.map((c, i) => (
            <div key={i} className="cmd-row" data-testid={`cmd-${i}`}>
              <code>{c.c}</code>
              <span>{c.d}</span>
            </div>
          ))}
        </div>
      </section>

      {/* FILES */}
      <section className="files">
        <h2 className="sec-title">FILE TREE · {manifest.file_count} FILES · {formatBytes(manifest.total_size)}</h2>
        <div className="files-grid">
          {manifest.files.map(f => (
            <div className="file-row" key={f.path}>
              <code>{f.path}</code>
              <span>{formatBytes(f.size)}</span>
            </div>
          ))}
        </div>
      </section>

      {/* FOOTER */}
      <footer className="ftr">
        <span>DUSA_MECHANIC_QBX · MIT · BUILT FOR QBOX</span>
        <a href={`${API}/resource/download`} data-testid="footer-download">DOWNLOAD .ZIP</a>
      </footer>

      {/* MODAL PREVIEW */}
      {previewOpen && (
        <div className="modal" onClick={() => setPreviewOpen(false)} data-testid="modal-overlay">
          <div className="modal-frame" onClick={e => e.stopPropagation()}>
            <button className="modal-close" onClick={() => setPreviewOpen(false)} data-testid="modal-close">✕</button>
            <iframe
              title="dusa-nui-modal"
              src={`${BACKEND_URL}/api/preview/index.html`}
              data-testid="modal-iframe"
            />
          </div>
        </div>
      )}
    </div>
  );
}

export default App;
