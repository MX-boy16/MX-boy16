/* ================================================================
   MECHANIC TABLET :: NUI App Logic
   Vanilla JS - no framework. Talks to client/nui.lua via NUI callbacks.
   ================================================================ */

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => document.querySelectorAll(sel);

const root        = $('#root');
const sbTime      = $('#sbTime');
const sbClose     = $('#sbClose');
const vcName      = $('#vcName');
const vcPlate     = $('#vcPlate');
const vcBody      = $('#vcBody');
const vcEngine    = $('#vcEngine');
const vcWheels    = $('#vcWheels');
const engineList  = $('#engineList');
const stanceGrid  = $('#stanceGrid');
const stanceSave  = $('#stanceSave');
const stanceReset = $('#stanceReset');
const sessionJob  = $('#sessionJob');

const RESOURCE = (window.GetParentResourceName && window.GetParentResourceName()) || 'mechanic_tablet';
const IS_DEMO  = typeof window.GetParentResourceName !== 'function';

const state = {
    open: false,
    vehicle: null,
    config:  null,
    stance:  null,
};

/* ===== nui fetch ===== */
function nui(name, data) {
    if (IS_DEMO) return Promise.resolve({});
    return fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {}),
    }).then(r => r.json()).catch(() => ({}));
}

/* ===== Hex helpers ===== */
function hexToRgb(hex) {
    const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex || '#000');
    return m ? { r: +parseInt(m[1], 16), g: +parseInt(m[2], 16), b: +parseInt(m[3], 16) } : { r: 0, g: 0, b: 0 };
}

/* ===== Status bar clock ===== */
function tickClock() {
    const d = new Date();
    sbTime.textContent =
        String(d.getHours()).padStart(2, '0') + ':' +
        String(d.getMinutes()).padStart(2, '0');
}
setInterval(tickClock, 30 * 1000);
tickClock();

/* ===== Tabs ===== */
$$('.tab').forEach(t => {
    t.addEventListener('click', () => {
        $$('.tab').forEach(x => x.classList.remove('active'));
        $$('.pane').forEach(x => x.classList.remove('active'));
        t.classList.add('active');
        const pane = document.querySelector(`[data-pane="${t.dataset.tab}"]`);
        if (pane) pane.classList.add('active');
    });
});

/* ===== Close ===== */
function close() {
    state.open = false;
    root.classList.add('hidden');
    nui('close', {});
}
sbClose.addEventListener('click', close);
document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && state.open) close();
});

/* ===== Render vehicle ===== */
function paintVehicle(v) {
    if (!v) {
        vcName.textContent = '— NO VEHICLE —';
        vcPlate.textContent = '----';
        vcBody.textContent = '--%';
        vcEngine.textContent = '--%';
        vcWheels.textContent = '--';
        return;
    }
    vcName.textContent   = v.modelName || v.rawName || 'UNKNOWN';
    vcPlate.textContent  = v.plate || '----';
    vcBody.textContent   = (v.body ?? '--') + '%';
    vcEngine.textContent = (v.engine ?? '--') + '%';
    vcWheels.textContent = v.wheelCount ?? '--';
}

/* ===== Build Performance rows ===== */
const PERF_DEFS = [
    { kind: 'engine', label: 'ENGINE',       desc: 'Power output',           maxKey: 'engineMax' },
    { kind: 'brakes', label: 'BRAKES',       desc: 'Stopping force',         maxKey: 'brakeMax'  },
    { kind: 'trans',  label: 'TRANSMISSION', desc: 'Gear ratio + shift',     maxKey: 'transMax'  },
    { kind: 'susp',   label: 'SUSPENSION',   desc: 'Ride dampening (perf.)', maxKey: 'suspMax'   },
    { kind: 'turbo',  label: 'TURBO',        desc: 'Forced induction',       maxKey: null        },
];

function buildEngineList() {
    if (!state.config) return;
    engineList.innerHTML = '';
    PERF_DEFS.forEach(def => {
        const isTurbo = def.kind === 'turbo';
        const max = isTurbo ? 1 : state.config.performance[def.maxKey];
        const cur = state.vehicle ? state.vehicle.mods[def.kind] : -1;
        const installed = isTurbo ? (cur === true || cur === 1) : ((cur ?? -1) + 1);

        const row = document.createElement('div');
        row.className = 'perf-row';
        row.dataset.testid = `perf-${def.kind}`;
        row.innerHTML = `
            <div class="label">
                <div class="label-h">${def.label}</div>
                <div class="label-s">${def.desc}</div>
            </div>
            <div class="perf-bars">
                ${Array.from({ length: max }, (_, i) => `
                    <div class="perf-bar ${i < (isTurbo ? (installed ? 1 : 0) : installed) ? 'active' : ''}"
                         data-level="${i}"
                         data-testid="perf-${def.kind}-${i}"></div>
                `).join('')}
            </div>
            <button class="btn ${ (isTurbo && installed) || (!isTurbo && installed >= max) ? '' : 'primary'}"
                    ${ (isTurbo && installed) || (!isTurbo && installed >= max) ? 'disabled' : ''}
                    data-testid="apply-${def.kind}">
                ${ isTurbo
                    ? (installed ? 'INSTALLED' : 'INSTALL')
                    : (installed >= max ? 'MAX' : 'UPGRADE') }
            </button>`;
        const btn = row.querySelector('button');
        btn.addEventListener('click', () => {
            const nextLevel = isTurbo ? 1 : installed; // installed equals (cur+1) which is the next level index
            nui('perf', { kind: def.kind, level: nextLevel });
        });
        // Click on individual bars to set exact level (skipping doesn't refund)
        row.querySelectorAll('.perf-bar').forEach(b => {
            b.addEventListener('click', () => {
                if (isTurbo) {
                    nui('perf', { kind: 'turbo', level: 1 });
                } else {
                    const lvl = parseInt(b.dataset.level, 10);
                    nui('perf', { kind: def.kind, level: lvl });
                }
            });
        });
        engineList.appendChild(row);
    });
}

/* ===== Build Stance sliders ===== */
const STANCE_DEFS = [
    { key: 'wheelWidth',  label: 'TIRE WIDTH',        unit: 'x' },
    { key: 'wheelSize',   label: 'WHEEL SIZE',        unit: 'x' },
    { key: 'suspHeight',  label: 'RIDE HEIGHT',       unit: 'm' },
    { key: 'trackWidth',  label: 'TRACK WIDTH',       unit: 'm' },
    { key: 'camberFront', label: 'CAMBER · FRONT',    unit: 'rad' },
    { key: 'camberRear',  label: 'CAMBER · REAR',     unit: 'rad' },
];

function buildStance() {
    if (!state.config) return;
    stanceGrid.innerHTML = '';
    state.stance = state.stance || {};
    STANCE_DEFS.forEach(def => {
        const limits = state.config.stance[def.key];
        const cur    = state.stance[def.key] ?? limits.default;
        const row = document.createElement('div');
        row.className = 'stance-row';
        row.dataset.testid = `stance-${def.key}`;
        row.innerHTML = `
            <div class="stance-head">
                <div class="stance-name">${def.label}</div>
                <div class="stance-val"><span data-bind-val>${cur.toFixed(3)}</span> ${def.unit}</div>
            </div>
            <input type="range"
                   min="${limits.min}" max="${limits.max}" step="${limits.step}"
                   value="${cur}"
                   data-testid="slider-${def.key}">
        `;
        const slider = row.querySelector('input');
        const valEl  = row.querySelector('[data-bind-val]');
        slider.addEventListener('input', () => {
            const v = parseFloat(slider.value);
            valEl.textContent = v.toFixed(3);
            state.stance[def.key] = v;
            nui('stance', { mode: 'preview', ...state.stance });
        });
        stanceGrid.appendChild(row);
    });
}

stanceSave.addEventListener('click', () => {
    nui('stance', { mode: 'save', ...state.stance });
});
stanceReset.addEventListener('click', () => {
    // reset all to defaults
    const defaults = {};
    Object.keys(state.config.stance).forEach(k => {
        defaults[k] = state.config.stance[k].default;
    });
    state.stance = defaults;
    nui('stance', { mode: 'reset' });
    buildStance();
});

/* ===== Looks buttons ===== */
$$('[data-look]').forEach(b => {
    b.addEventListener('click', () => {
        const kind  = b.dataset.look;
        const colId = b.dataset.color;
        const selId = b.dataset.sel;
        const payload = { kind };
        if (colId) {
            const c = hexToRgb(document.getElementById(colId).value);
            Object.assign(payload, c);
        } else if (selId) {
            payload.idx = parseInt(document.getElementById(selId).value, 10);
        }
        if (kind === 'wheelType') {
            payload.type = parseInt(document.getElementById('wheelType').value, 10);
            payload.mod  = parseInt(document.getElementById('wheelMod').value, 10);
        }
        nui('looks', payload);
    });
});

/* ===== Message bus from Lua ===== */
window.addEventListener('message', (event) => {
    const data = event.data || {};
    switch (data.type) {
        case 'open':
            state.open    = true;
            state.config  = data.config;
            state.vehicle = data.vehicle;
            state.stance  = null;
            paintVehicle(data.vehicle);
            buildEngineList();
            buildStance();
            sessionJob.textContent = (data.config && data.config.allowedJobs && data.config.allowedJobs[0]) || '--';
            root.classList.remove('hidden');
            break;
        case 'close':
            state.open = false;
            root.classList.add('hidden');
            break;
        case 'updateVehicle':
            state.vehicle = data.vehicle;
            paintVehicle(data.vehicle);
            buildEngineList();
            break;
    }
});

/* ===== DEMO MODE (preview outside FiveM) ===== */
if (IS_DEMO) {
    window.postMessage({
        type: 'open',
        vehicle: {
            plate: 'TUNE 24',
            modelName: 'sultanrs',
            rawName: 'sultanrs',
            body: 92,
            engine: 96,
            wheelCount: 4,
            mods: { engine: 1, brakes: -1, trans: 0, susp: -1, turbo: false, wheelType: 7, wheelMod: 3 },
            maxMods: { engine: 4, brakes: 3, trans: 3, susp: 4 },
        },
        config: {
            stance: {
                wheelWidth:   { min: 0.3,   max: 2.0,  default: 1.0, step: 0.05 },
                wheelSize:    { min: 0.5,   max: 1.5,  default: 1.0, step: 0.05 },
                suspHeight:   { min: -0.25, max: 0.15, default: 0.0, step: 0.005 },
                trackWidth:   { min: -0.15, max: 0.30, default: 0.0, step: 0.01 },
                camberFront:  { min: -0.6,  max: 0.6,  default: 0.0, step: 0.02 },
                camberRear:   { min: -0.6,  max: 0.6,  default: 0.0, step: 0.02 },
            },
            charge: false,
            currency: 'cash',
            prices: {},
            performance: { engineMax: 4, brakeMax: 3, transMax: 3, suspMax: 4, allowTurbo: true },
            allowedJobs: ['mechanic', 'tuner', 'lscustoms'],
        },
    }, '*');
}
