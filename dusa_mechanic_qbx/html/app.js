/* ================================================================
   DUSA MECHANIC :: NUI App Logic
   Plain vanilla JS - no framework, no build step.
   Communicates with FiveM client/nui.lua via NUI callbacks.
   ================================================================ */

const root      = document.getElementById('root');
const closeBtn  = document.getElementById('closeBtn');
const shopName  = document.getElementById('shopName');
const vehModel  = document.getElementById('vehModel');
const vehPlate  = document.getElementById('vehPlate');
const vehBody   = document.getElementById('vehBody');
const vehEngine = document.getElementById('vehEngine');
const tuneList  = document.getElementById('tuneList');
const nosHud    = document.getElementById('nosHud');
const nosFill   = document.getElementById('nosFill');
const nosPct    = document.getElementById('nosPct');

let state = {
    open    : false,
    prices  : {},
    vehicle : null,
    shop    : null,
};

const RESOURCE = (window.GetParentResourceName && window.GetParentResourceName()) || 'dusa_mechanic_qbx';
const IS_DEMO  = typeof window.GetParentResourceName !== 'function';

/* ===== NUI fetch wrapper ===== */
function nui(name, data) {
    return fetch(`https://${RESOURCE}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {}),
    }).then(r => r.json()).catch(() => ({}));
}

/* ===== Tabs ===== */
document.querySelectorAll('.tab').forEach(t => {
    t.addEventListener('click', () => {
        document.querySelectorAll('.tab').forEach(x => x.classList.remove('active'));
        document.querySelectorAll('.pane').forEach(x => x.classList.remove('active'));
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
closeBtn.addEventListener('click', close);
document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && state.open) close();
});

/* ===== Hex helpers ===== */
function hexToRgb(hex) {
    const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return m ? { r: parseInt(m[1], 16), g: parseInt(m[2], 16), b: parseInt(m[3], 16) } : { r: 0, g: 0, b: 0 };
}

/* ===== Apply prices to cards ===== */
function applyPrices() {
    document.querySelectorAll('[data-price-key]').forEach(el => {
        const k  = el.dataset.priceKey;
        const v  = state.prices[k];
        const p  = el.querySelector('.p');
        if (!p) return;
        if (Array.isArray(v)) {
            p.textContent = v[1] || v[0] || '?';
        } else if (typeof v === 'object' && v !== null && !Array.isArray(v)) {
            // For min/max payouts etc – not used in cards but safe
            p.textContent = `${v.min}-${v.max}`;
        } else {
            p.textContent = v ?? '?';
        }
    });
}

/* ===== Build tuning rows ===== */
const TUNES = [
    { kind: 'engine', label: 'ENGINE',       max: 4, priceKey: 'engineUpgrade' },
    { kind: 'brakes', label: 'BRAKES',       max: 3, priceKey: 'brakeUpgrade'  },
    { kind: 'trans',  label: 'TRANSMISSION', max: 3, priceKey: 'transUpgrade'  },
    { kind: 'susp',   label: 'SUSPENSION',   max: 4, priceKey: 'suspUpgrade'   },
    { kind: 'armor',  label: 'ARMOR',        max: 5, priceKey: 'armor'         },
    { kind: 'turbo',  label: 'TURBO',        max: 1, priceKey: 'turbo'         },
];

function buildTuningRows() {
    tuneList.innerHTML = '';
    TUNES.forEach(t => {
        const row = document.createElement('div');
        row.className = 'tune-row';
        const cur = state.vehicle ? state.vehicle.mods[t.kind] : -1;
        const nextLvl = (t.kind === 'turbo')
            ? (cur === true || cur === 1 ? null : 1)
            : (cur === undefined || cur < t.max - 1 ? Math.max(1, (cur ?? -1) + 2) : null);
        const price = t.kind === 'turbo'
            ? state.prices.turbo
            : (state.prices[t.priceKey] || [])[nextLvl];
        row.innerHTML = `
            <div>
                <div class="label">CURRENT LVL ${(cur === true || cur === 1) ? 'INSTALLED' : (cur ?? -1) + 1}</div>
                <h3>${t.label}</h3>
            </div>
            <div class="level-track">
                ${Array.from({ length: t.max }, (_, i) =>
                    `<div class="level-bar ${i < ((cur ?? -1) + 1) ? 'active' : ''}"></div>`
                ).join('')}
            </div>
            <div class="tune-price">${price ? '$' + price : '—'}</div>
            <button class="btn ${nextLvl ? 'primary' : ''}" ${nextLvl ? '' : 'disabled'}>
                ${nextLvl ? (t.kind === 'turbo' ? 'INSTALL' : 'UPGRADE') : 'MAX'}
            </button>
        `;
        const btn = row.querySelector('button');
        if (nextLvl) {
            btn.addEventListener('click', () => {
                nui('action', { kind: 'tune', what: t.kind, level: nextLvl });
            });
        }
        tuneList.appendChild(row);
    });
}

/* ===== Wire universal action buttons ===== */
document.querySelectorAll('[data-action]').forEach(card => {
    const button = card.tagName === 'BUTTON' ? card : card.querySelector('button');
    if (!button) return;
    button.addEventListener('click', e => {
        e.stopPropagation();
        const action = card.dataset.action;
        if (action === 'repair') {
            nui('action', { kind: 'repair', what: card.dataset.what });
        } else if (action === 'cosm') {
            const what = card.dataset.what;
            const payload = { kind: 'cosm', what };
            const colorId = card.dataset.colorFrom;
            if (colorId) {
                const v = document.getElementById(colorId).value;
                payload.value = hexToRgb(v);
            } else {
                const valId = card.dataset.valueFrom;
                if (valId) payload.value = parseInt(document.getElementById(valId).value, 10);
            }
            nui('action', payload);
        } else if (action === 'nosInstall') {
            nui('action', { kind: 'nosInstall' });
        } else if (action === 'nosRefill') {
            nui('action', { kind: 'nosRefill' });
        } else if (action === 'scan') {
            nui('action', { kind: 'scan' });
        }
    });
});

/* ===== Refresh vehicle data ===== */
function paintVehicle(v) {
    if (!v) return;
    vehModel.textContent  = v.model || v.modelName || '--';
    vehPlate.textContent  = v.plate || '--';
    vehBody.textContent   = (v.body ?? '--') + '%';
    vehEngine.textContent = (v.engine ?? '--') + '%';
    state.vehicle = v;
    buildTuningRows();
}

/* ===== Message bus from Lua ===== */
window.addEventListener('message', (event) => {
    const data = event.data || {};
    switch (data.type) {
        case 'open':
            state.open    = true;
            state.prices  = data.prices || {};
            state.shop    = data.shop;
            if (data.shop && data.shop.label) shopName.textContent = data.shop.label;
            paintVehicle(data.vehicle);
            applyPrices();
            root.classList.remove('hidden');
            break;

        case 'close':
            state.open = false;
            root.classList.add('hidden');
            break;

        case 'updateVehicle':
            paintVehicle(data.vehicle);
            break;

        case 'nosHud':
            if (data.show) {
                nosHud.classList.remove('hidden');
                const pct = ((data.fuel ?? 0) / (data.max || 100)) * 100;
                nosFill.style.width = pct + '%';
                nosPct.textContent = Math.round(pct) + '%';
            } else {
                nosHud.classList.add('hidden');
            }
            break;

        case 'nosUpdate':
            if (!nosHud.classList.contains('hidden')) {
                const pct = ((data.fuel ?? 0) / (data.max || 100)) * 100;
                nosFill.style.width = pct + '%';
                nosPct.textContent = Math.round(pct) + '%';
                if (data.active) {
                    nosFill.style.boxShadow = '0 0 22px var(--accent), 0 0 40px var(--accent)';
                } else {
                    nosFill.style.boxShadow = '0 0 10px var(--accent-2)';
                }
            }
            break;
    }
});

/* ===== DEMO MODE (when previewing in a browser, not FiveM) ===== */
if (IS_DEMO) {
    const demoPrices = {
        tire: 150, window: 75, body: 250, engine: 400, fullRepair: 3500, fullClean: 250,
        engineUpgrade: { 1: 2500, 2: 5000, 3: 8500, 4: 14000 },
        brakeUpgrade:  { 1: 1500, 2: 3000, 3: 6000 },
        transUpgrade:  { 1: 2500, 2: 5000, 3: 9000 },
        suspUpgrade:   { 1: 1500, 2: 3000, 3: 5500, 4: 8000 },
        turbo: 12000,
        armor: { 1: 1500, 2: 3000, 3: 4500, 4: 6000, 5: 9000 },
        primaryColor: 300, secondaryColor: 300, pearlColor: 500, wheelColor: 200,
        wheels: 2500, neons: 1500, xenons: 600, smoke: 800, plateIndex: 300,
        nosInstall: 8000, nosRefill: 1200, scanFee: 150,
    };
    // Block the NUI fetch so we don't error in the browser
    window.fetch = () => Promise.resolve({ json: () => Promise.resolve({}) });
    window.postMessage({
        type: 'open',
        shop: { id: 'lsc_main', label: 'LS Customs · Strawberry' },
        vehicle: {
            plate: 'TURBO 24', modelName: 'sultanrs', model: 'Sultan RS',
            body: 87, engine: 92,
            tires: [true, true, true, true],
            mods: { engine: 1, brakes: 0, trans: -1, susp: 2, armor: -1, turbo: false },
            maxMods: { engine: 4, brakes: 3, trans: 3, susp: 4, armor: 5 },
        },
        prices: demoPrices,
        canWork: true,
    }, '*');
    setTimeout(() => {
        window.postMessage({ type: 'nosHud', show: true, fuel: 72, max: 100 }, '*');
    }, 500);
}

