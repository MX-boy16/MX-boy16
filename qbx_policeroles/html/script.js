// MDT NUI controller
const RES = 'qbx_policeroles';
const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

let state = {
    self: null,
    currentTab: 'home',
    dossier: null,
};

const CLASS_LABELS = {
    1: { label: 'Class 1 · Sidearm',   icon: 'fa-gun' },
    2: { label: 'Class 2 · SMG',       icon: 'fa-crosshairs' },
    3: { label: 'Class 3 · Long Arms', icon: 'fa-shield-virus' },
};
const ROLE_TAGS = {
    chief:'command',captain:'command',lieutenant:'command',
    swat:'tactical',k9:'k9',detective:'detective',
};

// ---------- NUI bridge ----------
async function api(path, data = {}) {
    const r = await fetch(`https://${RES}/${path}`, {
        method:'POST', headers:{'Content-Type':'application/json'},
        body: JSON.stringify(data)
    });
    return r.json().catch(() => null);
}

function close() {
    api('close');
    $('#tablet').classList.add('hidden');
}

window.addEventListener('message', (e) => {
    const d = e.data || {};
    if (d.action === 'open') {
        state.self = d.self || {};
        showTablet();
    } else if (d.action === 'close') {
        $('#tablet').classList.add('hidden');
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !$('#tablet').classList.contains('hidden')) {
        if (!$('#modal').classList.contains('hidden')) { closeModal(); return; }
        close();
    }
});

// ---------- header / clock ----------
function tickClock() {
    const d = new Date();
    $('#clock').textContent = d.toTimeString().slice(0,8);
    $('#date').textContent = d.toDateString().toUpperCase();
}
setInterval(tickClock, 1000); tickClock();

function showTablet() {
    $('#tablet').classList.remove('hidden');
    const s = state.self || {};
    $('#officerName').textContent = (s.officerName || '—').toUpperCase();
    $('#officerRank').textContent = s.isLeader ? 'CHIEF OF POLICE' : (s.canManage ? 'COMMAND STAFF' : 'OFFICER');
    $('#badgeNum').textContent = '#' + String(s.badgeId || Math.floor(Math.random()*9000+1000)).padStart(4,'0');

    $$('.admin-only').forEach(el => { el.hidden = !s.canManage; });
    selectTab('home');
}

// ---------- sidebar ----------
$$('.sidebar .nav').forEach(btn => {
    btn.addEventListener('click', () => {
        const tab = btn.dataset.tab;
        const action = btn.dataset.action;
        if (action === 'duty') { api('toggleDuty'); return; }
        if (!tab) return;
        selectTab(tab);
    });
});
$('#closeBtn').addEventListener('click', close);

function selectTab(tab) {
    state.currentTab = tab;
    $$('.sidebar .nav').forEach(b => b.classList.toggle('active', b.dataset.tab === tab));
    const renderer = ({ home: renderHome, citizens: renderCitizens, vehicles: renderVehicles,
                       bolos: renderBolos, roles: renderRoles })[tab];
    if (renderer) renderer();
}

// ---------- HOME ----------
function renderHome() {
    const s = state.self || {};
    const roles = (s.roles || []).map(r => `<span class="role-chip ${ROLE_TAGS[r]||''}">${r}</span>`).join('') || '<span class="role-chip">none</span>';
    $('#content').innerHTML = `
        <div class="page-title">Dashboard</div>
        <div class="page-heading"><i class="fa-solid fa-grip"></i> Welcome, ${(s.officerName||'').split(' ')[0] || 'Officer'}</div>
        <div class="home-grid">
            <div class="stat"><i class="fa-solid fa-shield-halved stat-icon"></i><div class="stat-label">Duty Status</div><div class="stat-value" style="color:${s.onDuty?'#10b981':'#ef4444'}">${s.onDuty?'ON':'OFF'}</div><div class="stat-sub">/duty to toggle</div></div>
            <div class="stat"><i class="fa-solid fa-id-card-clip stat-icon"></i><div class="stat-label">Active Assignments</div><div class="stat-value">${(s.roles||[]).length}</div><div class="stat-sub">${roles}</div></div>
            <div class="stat"><i class="fa-solid fa-gun stat-icon"></i><div class="stat-label">License Authority</div><div class="stat-value" style="font-size:18px">${s.canIssueLic?'AUTHORIZED':'READ-ONLY'}</div><div class="stat-sub">Issue / revoke civilian weapon licenses</div></div>
        </div>

        <div class="section-title"><i class="fa-solid fa-bolt"></i> Quick Actions</div>
        <div class="quick-actions">
            <div class="quick" data-go="citizens"><i class="fa-solid fa-magnifying-glass"></i><div><div class="q-label">Citizen Lookup</div><div class="q-sub">Search by name, CID or phone</div></div></div>
            <div class="quick" data-go="vehicles"><i class="fa-solid fa-car"></i><div><div class="q-label">Plate Lookup</div><div class="q-sub">Run a vehicle through the registry</div></div></div>
            <div class="quick" data-go="bolos"><i class="fa-solid fa-bullhorn"></i><div><div class="q-label">Active BOLOs</div><div class="q-sub">Department-wide alerts</div></div></div>
            ${s.canManage ? `<div class="quick" data-go="roles"><i class="fa-solid fa-user-shield"></i><div><div class="q-label">Manage Roles</div><div class="q-sub">Assign divisions to officers</div></div></div>` : ''}
        </div>
    `;
    $$('.quick').forEach(q => q.addEventListener('click', () => selectTab(q.dataset.go)));
}

// ---------- CITIZENS ----------
function renderCitizens() {
    $('#content').innerHTML = `
        <div class="page-title">Citizens</div>
        <div class="page-heading"><i class="fa-solid fa-id-card"></i> Citizen Lookup</div>
        <div class="searchbar">
            <input id="citizenQuery" placeholder="Name, citizen ID, or phone number…" autocomplete="off" />
            <button class="btn btn-primary" id="citizenSearchBtn"><i class="fa-solid fa-magnifying-glass"></i> Search</button>
        </div>
        <div id="citizenResults"></div>
    `;
    $('#citizenSearchBtn').addEventListener('click', doCitizenSearch);
    $('#citizenQuery').addEventListener('keydown', e => { if (e.key === 'Enter') doCitizenSearch(); });
    $('#citizenQuery').focus();
}

async function doCitizenSearch() {
    const q = $('#citizenQuery').value.trim();
    if (q.length < 2) return;
    const list = await api('searchCitizens', { q }) || [];
    if (!list.length) {
        $('#citizenResults').innerHTML = `<div class="empty"><i class="fa-solid fa-user-slash"></i><h3>No citizens found</h3><div>Try a different search.</div></div>`;
        return;
    }
    $('#citizenResults').innerHTML = `<div class="cards">${list.map(c => `
        <div class="card" data-cid="${c.citizenid}">
            <div class="accent"></div>
            <div class="card-title"><i class="fa-solid fa-user"></i> ${c.firstname} ${c.lastname}</div>
            <div class="card-sub">CID · ${c.citizenid}</div>
            <div class="card-meta">
                <span>Phone</span><span style="color:var(--text)">${c.phone||'—'}</span>
                <span>DOB</span><span style="color:var(--text)">${c.dob||'—'}</span>
            </div>
        </div>`).join('')}</div>`;
    $$('.card[data-cid]').forEach(c => c.addEventListener('click', () => openDossier(c.dataset.cid)));
}

async function openDossier(cid) {
    const d = await api('citizenDossier', { cid });
    if (!d) return;
    state.dossier = d;
    const initials = (d.firstname||'?')[0] + (d.lastname||'')[0];
    const licMap = {}; (d.licenses?.active||[]).forEach(c => licMap[c]=true);
    const roleChips = (d.policeRoles||[]).map(r=>`<span class="role-chip ${ROLE_TAGS[r]||''}">${r}</span>`).join('') || '';

    $('#content').innerHTML = `
        <div class="page-title"><a href="#" id="backToSearch" style="color:var(--blue)">&larr; Back to search</a></div>
        <div class="dossier-header">
            <div class="avatar">${initials.toUpperCase()}</div>
            <div>
                <div class="dossier-name">${d.name}</div>
                <div class="dossier-cid">CID · ${d.citizenid}</div>
                <div class="dossier-meta">
                    <span><b>DOB</b>${d.dob||'—'}</span>
                    <span><b>Phone</b>${d.phone||'—'}</span>
                    <span><b>Gender</b>${d.gender||'—'}</span>
                    <span><b>Job</b>${d.job||'—'}</span>
                </div>
                ${roleChips ? `<div style="margin-top:10px">${roleChips}</div>` : ''}
            </div>
            <div class="dossier-actions">
                <button class="btn btn-gold" id="fileReportBtn"><i class="fa-solid fa-file-pen"></i> File Report</button>
            </div>
        </div>

        <div class="section">
            <div class="section-title"><i class="fa-solid fa-gun"></i> Weapon Licenses</div>
            <div class="licenses-row">
                ${[1,2,3].map(cls => {
                    const has = licMap[cls];
                    const info = CLASS_LABELS[cls];
                    return `<div class="license ${has?'active':''}" data-class="${cls}">
                        <i class="fa-solid ${info.icon} lic-icon"></i>
                        <div class="lic-label">${info.label}</div>
                        <div class="lic-status">${has?'✓ Active':'Not issued'}</div>
                    </div>`;
                }).join('')}
            </div>
        </div>

        <div class="section">
            <div class="section-title"><i class="fa-solid fa-folder-open"></i> Records · ${(d.records||[]).length}</div>
            ${(d.records||[]).length ? (d.records.map(r => `
                <div class="record sev-${r.severity||'minor'}">
                    <i class="rec-icon fa-solid ${({charge:'fa-gavel',warrant:'fa-file-shield',note:'fa-note-sticky'})[r.type]||'fa-folder'}"></i>
                    <div>
                        <div class="rec-title">${r.title}</div>
                        <div class="rec-sub">${(r.severity||'').toUpperCase()} · $${r.fine||0} · ${r.jail_minutes||0}min · ${r.officer_name||'?'} · ${r.created_at||''}</div>
                    </div>
                    <div class="rec-badge">${r.resolved?'CLOSED':'OPEN'}</div>
                </div>`).join('')) : `<div class="empty"><i class="fa-solid fa-circle-check"></i><h3>Clean record</h3></div>`}
        </div>

        <div class="section">
            <div class="section-title"><i class="fa-solid fa-car"></i> Registered Vehicles · ${(d.vehicles||[]).length}</div>
            ${(d.vehicles||[]).length ? `<div class="cards">${d.vehicles.map(v=>`
                <div class="card"><div class="accent"></div>
                    <div class="card-title"><i class="fa-solid fa-car"></i> ${v.plate}</div>
                    <div class="card-sub">${v.vehicle}</div>
                    <div class="card-meta"><span>State</span><span style="color:var(--text)">${v.state===0?'In garage':'Out'}</span><span>Garage</span><span style="color:var(--text)">${v.garage||'—'}</span></div>
                </div>`).join('')}</div>` : `<div class="empty"><i class="fa-solid fa-car-burst"></i><h3>No vehicles on record</h3></div>`}
        </div>
    `;
    $('#backToSearch').addEventListener('click', e => { e.preventDefault(); renderCitizens(); });
    $('#fileReportBtn').addEventListener('click', () => openFileReportModal(d));
    $$('.license').forEach(el => el.addEventListener('click', () => toggleLicense(d, +el.dataset.class, el.classList.contains('active'))));
}

async function toggleLicense(d, cls, isActive) {
    if (!state.self.canIssueLic) return toast('Not authorized to issue licenses.', 'error');
    const action = isActive ? 'revoke' : 'issue';
    const ok = await confirmModal(
        `${action.toUpperCase()} LICENSE`,
        `${action.toUpperCase()} <b style="color:var(--gold)">${CLASS_LABELS[cls].label}</b> ${isActive?'from':'to'} <b>${d.name}</b>?`
    );
    if (!ok) return;
    const res = await api(action+'License', { cid: d.citizenid, class: cls });
    if (res && res.ok) { toast('License updated.', 'success'); openDossier(d.citizenid); }
    else toast('Failed: ' + (res && res.err || 'unknown'), 'error');
}

// ---------- File report modal ----------
function openFileReportModal(d) {
    showModal(`File Report · ${d.name}`, `
        <div><label>Type</label><select id="rType"><option value="charge">Criminal Charge</option><option value="warrant">Warrant</option><option value="note">Note / Field interview</option></select></div>
        <div><label>Severity</label><select id="rSev"><option value="minor">Minor</option><option value="moderate">Moderate</option><option value="severe">Severe</option><option value="felony">Felony</option></select></div>
        <div><label>Title</label><input id="rTitle" placeholder="e.g. Speeding 30+ over" /></div>
        <div><label>Details</label><textarea id="rBody" placeholder="Incident notes…"></textarea></div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
            <div><label>Fine ($)</label><input id="rFine" type="number" min="0" value="0" /></div>
            <div><label>Jail (minutes)</label><input id="rJail" type="number" min="0" value="0" /></div>
        </div>
    `, async () => {
        const data = {
            citizenid: d.citizenid,
            type: $('#rType').value, severity: $('#rSev').value,
            title: $('#rTitle').value || '(untitled)', body: $('#rBody').value || '',
            fine: +$('#rFine').value || 0, jail_minutes: +$('#rJail').value || 0,
        };
        const res = await api('createRecord', data);
        if (res && res.ok) {
            toast('Report filed.', 'success');
            const p = res.penalty;
            if (p && (p.fine_requested>0 || p.jail_minutes>0)) {
                const lines = p.target_online
                    ? [`Collected $${p.fine_taken} (bank $${p.from_bank} · cash $${p.from_cash})`,
                       p.fine_unpaid>0?`Unpaid: $${p.fine_unpaid}`:'',
                       p.jailed?`Jailed for ${p.jail_minutes} min`:''].filter(Boolean).join(' · ')
                    : 'Citizen offline · penalties not applied';
                toast(lines, 'info', 6000);
            }
            openDossier(d.citizenid);
        } else toast('Failed.', 'error');
    });
}

// ---------- VEHICLES ----------
function renderVehicles() {
    $('#content').innerHTML = `
        <div class="page-title">Vehicles</div>
        <div class="page-heading"><i class="fa-solid fa-car"></i> Plate Lookup</div>
        <div class="searchbar">
            <input id="vehQuery" placeholder="License plate (partial OK)…" autocomplete="off" />
            <button class="btn btn-primary" id="vehSearchBtn"><i class="fa-solid fa-magnifying-glass"></i> Search</button>
        </div>
        <div id="vehResults"></div>
    `;
    $('#vehSearchBtn').addEventListener('click', doVehSearch);
    $('#vehQuery').addEventListener('keydown', e => { if (e.key==='Enter') doVehSearch(); });
    $('#vehQuery').focus();
}
async function doVehSearch() {
    const q = $('#vehQuery').value.trim();
    if (q.length < 2) return;
    const list = await api('searchVehicles', { q }) || [];
    if (!list.length) { $('#vehResults').innerHTML = `<div class="empty"><i class="fa-solid fa-car-burst"></i><h3>No matches</h3></div>`; return; }
    $('#vehResults').innerHTML = `<div class="cards">${list.map(v=>`
        <div class="card accent-green" data-cid="${v.owner_cid||''}">
            <div class="accent"></div>
            <div class="card-title"><i class="fa-solid fa-car"></i> ${v.plate}</div>
            <div class="card-sub">${v.model} · ${v.state===0?'in garage':'out'}</div>
            <div class="card-meta"><span>Owner</span><span style="color:var(--text)">${v.owner}</span><span>CID</span><span style="color:var(--text)">${v.owner_cid||'—'}</span></div>
        </div>`).join('')}</div>`;
    $$('.card[data-cid]').forEach(c => c.addEventListener('click', () => c.dataset.cid && openDossier(c.dataset.cid)));
}

// ---------- BOLOs ----------
async function renderBolos() {
    const list = await api('listBolos') || [];
    $('#content').innerHTML = `
        <div class="page-title">Department</div>
        <div class="page-heading" style="justify-content:space-between"><span><i class="fa-solid fa-bullhorn"></i> Active BOLOs · ${list.length}</span>
            <button class="btn btn-gold" id="newBolo"><i class="fa-solid fa-tower-broadcast"></i> Issue BOLO</button></div>
        ${list.length ? `<div class="cards">${list.map(b=>`
            <div class="card accent-${({minor:'',moderate:'amber',severe:'red',felony:'purple'})[b.severity]||''}" data-id="${b.id}">
                <div class="accent"></div>
                <div class="card-title"><i class="fa-solid fa-bullhorn"></i> ${b.subject}</div>
                <div class="card-sub">${(b.severity||'').toUpperCase()} · ${b.created_at||''}</div>
                <div style="margin-top:10px;font-size:13px;color:var(--text)">${b.description||'—'}</div>
                <button class="btn btn-ghost" style="margin-top:12px;padding:6px 14px;font-size:11px" data-clear="${b.id}">Mark Cleared</button>
            </div>`).join('')}</div>` : `<div class="empty"><i class="fa-solid fa-bullhorn"></i><h3>No active BOLOs</h3></div>`}
    `;
    $('#newBolo').addEventListener('click', openBoloModal);
    $$('[data-clear]').forEach(b => b.addEventListener('click', async (e) => {
        e.stopPropagation();
        await api('clearBolo', { id: +b.dataset.clear }); toast('BOLO cleared.', 'success'); renderBolos();
    }));
}
function openBoloModal() {
    showModal('Issue New BOLO', `
        <div><label>Subject</label><input id="bSubj" placeholder="Person, vehicle, or plate" /></div>
        <div><label>Severity</label><select id="bSev"><option value="minor">Minor</option><option value="moderate">Moderate</option><option value="severe">Severe</option><option value="felony">Felony</option></select></div>
        <div><label>Description</label><textarea id="bDesc"></textarea></div>
    `, async () => {
        await api('createBolo', { subject: $('#bSubj').value, severity: $('#bSev').value, description: $('#bDesc').value });
        toast('BOLO issued.', 'success'); renderBolos();
    });
}

// ---------- ROLES ----------
async function renderRoles() {
    const [officers, roleDefs] = await Promise.all([api('getOnlineOfficers'), api('getRoleDefinitions')]);
    state.officers = officers || []; state.roleDefs = roleDefs || [];

    $('#content').innerHTML = `
        <div class="page-title">Administration</div>
        <div class="page-heading" style="justify-content:space-between"><span><i class="fa-solid fa-user-shield"></i> Role Management</span>
            ${state.self.isLeader || (state.self.permissions||{}).can_create_role ?
                `<button class="btn btn-gold" id="createRole"><i class="fa-solid fa-plus"></i> New Role</button>` : ''}</div>

        <div class="section">
            <div class="section-title"><i class="fa-solid fa-users"></i> On-duty Officers · ${state.officers.length}</div>
            ${state.officers.length ? `<div class="cards">${state.officers.map(o=>{
                const chips = (o.roles||[]).map(r=>`<span class="role-chip ${ROLE_TAGS[r]||''}">${r}</span>`).join('') || '<span class="role-chip">none</span>';
                return `<div class="card" data-officer="${o.source}">
                    <div class="accent"></div>
                    <div class="card-title"><i class="fa-solid fa-user-shield"></i> ${o.name}</div>
                    <div class="card-sub">ID ${o.source} · ${o.gradeLabel||('Grade '+o.grade)}</div>
                    <div style="margin-top:10px">${chips}</div>
                </div>`;}).join('')}</div>` : `<div class="empty"><i class="fa-solid fa-user-slash"></i><h3>No officers on duty</h3></div>`}
        </div>

        <div class="section">
            <div class="section-title"><i class="fa-solid fa-book-bookmark"></i> Role Index · ${state.roleDefs.length}</div>
            <div class="cards">${state.roleDefs.map(r=>`
                <div class="card accent-${ROLE_TAGS[r.name]||''}">
                    <div class="accent"></div>
                    <div class="card-title">${r.label}</div>
                    <div class="card-sub">${r.name} · ${r.is_default?'system':'custom'}</div>
                    <div style="margin-top:8px;font-size:12px;color:var(--muted)">${r.description||''}</div>
                    <div style="margin-top:10px;font-size:11px;color:var(--gold)">${(r.permissions||[]).join(', ')||'no permissions'}</div>
                    ${!r.is_default && state.self.isLeader ? `<button class="btn btn-danger" style="margin-top:12px;padding:6px 14px;font-size:11px" data-del="${r.name}">Disband</button>` : ''}
                </div>`).join('')}</div>
        </div>
    `;
    $$('[data-officer]').forEach(c => c.addEventListener('click', () => openOfficerActions(+c.dataset.officer)));
    $$('[data-del]').forEach(b => b.addEventListener('click', async (e) => {
        e.stopPropagation();
        const ok = await confirmModal('DISBAND ROLE', `Disband role <b style="color:var(--gold)">${b.dataset.del}</b> and remove it from all officers? This cannot be undone.`);
        if (!ok) return;
        await api('deleteRole', { name: b.dataset.del }); toast('Role deleted.', 'success'); renderRoles();
    }));
    const cb = $('#createRole'); if (cb) cb.addEventListener('click', openCreateRoleModal);
}

function openOfficerActions(src) {
    const o = state.officers.find(x => x.source === src); if (!o) return;
    const assigned = new Set(o.roles||[]);
    showModal(`Manage · ${o.name}`, `
        <div style="font-size:12px;color:var(--muted);margin-bottom:6px">Click a role to assign or revoke it.</div>
        <div class="licenses-row" style="grid-template-columns:repeat(2,1fr)">
            ${state.roleDefs.map(r => {
                const has = assigned.has(r.name);
                return `<div class="license ${has?'active':''}" data-role="${r.name}">
                    <i class="fa-solid ${has?'fa-circle-check':'fa-circle-plus'} lic-icon"></i>
                    <div class="lic-label">${r.label}</div>
                    <div class="lic-status">${has?'✓ Active':'Not assigned'}</div>
                </div>`;
            }).join('')}
        </div>
    `, null, true);
    $$('[data-role]', $('#modalBody')).forEach(el => el.addEventListener('click', async () => {
        const role = el.dataset.role;
        const has = el.classList.contains('active');
        const res = await api(has?'removeRole':'assignRole', { target: src, role });
        if (res && res.ok) { toast((has?'Revoked ':'Assigned ')+role, 'success'); closeModal(); renderRoles(); }
        else toast('Failed: '+(res&&res.err||'unknown'),'error');
    }));
}

function openCreateRoleModal() {
    showModal('Charter New Division', `
        <div><label>Codename (lowercase, no spaces)</label><input id="nName" maxlength="50" /></div>
        <div><label>Display Label</label><input id="nLabel" maxlength="100" /></div>
        <div><label>Description</label><textarea id="nDesc" maxlength="255"></textarea></div>
        <div><label>Permissions</label>
            ${['can_manage_roles','can_assign_role','can_remove_role','can_create_role','access_all']
                .map(p=>`<label style="display:flex;align-items:center;gap:8px;margin:6px 0;font-size:13px;color:var(--text);text-transform:none;letter-spacing:0"><input type="checkbox" value="${p}" style="width:auto" />${p}</label>`).join('')}
        </div>
    `, async () => {
        const perms = $$('input[type=checkbox]:checked', $('#modalBody')).map(c=>c.value);
        const res = await api('createRole', { name: $('#nName').value, label: $('#nLabel').value, description: $('#nDesc').value, permissions: perms });
        if (res && res.ok) { toast('Role created.', 'success'); renderRoles(); }
        else toast('Failed: '+(res&&res.err||'unknown'),'error');
    });
}

// ---------- modal & toast ----------
function showModal(title, html, onConfirm, hideOk) {
    $('#modalTitle').textContent = title;
    $('#modalBody').innerHTML = html;
    $('#modal').classList.remove('hidden');
    $('#modalOk').style.display = hideOk ? 'none' : '';
    $('#modalOk').onclick = async () => { if (onConfirm) await onConfirm(); closeModal(); };
}
function closeModal() { $('#modal').classList.add('hidden'); }
$('#modalClose').addEventListener('click', closeModal);
$('#modalCancel').addEventListener('click', closeModal);

// FiveM CEF has no native confirm(); use the in-page modal instead.
function confirmModal(title, message) {
    return new Promise((resolve) => {
        showModal(title, `<div style="font-size:14px;line-height:1.5;color:var(--text)">${message}</div>`, () => resolve(true));
        const cancel = () => resolve(false);
        $('#modalCancel').addEventListener('click', cancel, { once: true });
        $('#modalClose').addEventListener('click', cancel, { once: true });
    });
}

function toast(msg, type='info', dur=3500) {
    const t = document.createElement('div');
    t.textContent = msg;
    t.style.cssText = `position:fixed;top:30px;left:50%;transform:translateX(-50%);background:${({success:'#065f46',error:'#7f1d1d',info:'#1e3a8a'})[type]};color:#fff;padding:14px 22px;border-radius:8px;font-weight:600;font-size:13px;letter-spacing:.08em;z-index:100;box-shadow:0 10px 30px rgba(0,0,0,.4)`;
    document.body.appendChild(t);
    setTimeout(()=>t.remove(), dur);
}
