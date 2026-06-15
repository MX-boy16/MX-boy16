-- Police MDT — ox_lib menu UI, police-themed to match /policeadmin.
-- Dashboard → Citizens / Vehicles / Licenses / Records / BOLOs

local cb = lib.callback.await

local CLASS_VIS = {
    [1] = { icon = 'gun',          color = '#3B82F6', label = 'Class 1 — Sidearm' },
    [2] = { icon = 'crosshairs',   color = '#F59E0B', label = 'Class 2 — SMG'     },
    [3] = { icon = 'shield-virus', color = '#DC2626', label = 'Class 3 — Heavy'   },
}

local SEVERITY_VIS = {
    minor    = { icon = 'circle-info',          color = '#3B82F6', label = 'Minor'    },
    moderate = { icon = 'triangle-exclamation', color = '#F59E0B', label = 'Moderate' },
    severe   = { icon = 'circle-exclamation',   color = '#EF4444', label = 'Severe'   },
    felony   = { icon = 'gavel',                color = '#7C3AED', label = 'Felony'   },
}

local function sevVis(s) return SEVERITY_VIS[s] or SEVERITY_VIS.minor end

local function notify(msg, type_) Client.Notify(msg, type_ or 'inform') end

-- forward declarations
local openDashboard, openCitizenSearch, openCitizenDossier, openVehicleSearch
local openLicensePanel, openIssueLicense, openRevokeLicense
local openCreateRecord, openBoloList, openCreateBolo

-- ---- Dashboard ---------------------------------------------------------------

function openDashboard()
    local self = cb('qbx_policeroles:mdt:openSelf', false)
    if not self then notify(Client.L('not_police'), 'error') return end

    local statusColor = self.onDuty and '#10B981' or '#9CA3AF'
    local statusText  = self.onDuty and 'ON DUTY' or 'OFF DUTY'

    local options = {
        {
            title    = '— OFFICER TERMINAL —',
            description = self.officerName,
            icon     = 'id-card',
            iconColor = '#FFD700',
            readOnly = true,
            metadata = {
                { label = 'Callsign',  value = self.callsign or '—' },
                { label = 'Status',    value = statusText },
                { label = 'Divisions', value = (#(self.roles or {}) > 0) and table.concat(self.roles, ', ') or '—' },
                { label = 'Licenses',  value = self.canIssueLic and 'Authorized to issue' or 'Read-only' },
            },
        },
        {
            title       = '▸  CITIZEN LOOKUP',
            description = 'Search civilians by name, citizenid, or phone',
            icon        = 'magnifying-glass',
            iconColor   = '#3B82F6',
            arrow       = true,
            onSelect    = function() openCitizenSearch(self) end,
        },
        {
            title       = '▸  VEHICLE LOOKUP',
            description = 'Run a plate through the registry',
            icon        = 'car',
            iconColor   = '#10B981',
            arrow       = true,
            onSelect    = function() openVehicleSearch(self) end,
        },
        {
            title       = '▸  ACTIVE BOLOS',
            description = 'Be-on-the-lookout alerts in effect',
            icon        = 'bullhorn',
            iconColor   = '#F59E0B',
            arrow       = true,
            onSelect    = function() openBoloList(self) end,
        },
        {
            title       = '✚  ISSUE BOLO',
            description = 'Broadcast a new alert to the department',
            icon        = 'tower-broadcast',
            iconColor   = '#FACC15',
            arrow       = true,
            onSelect    = function() openCreateBolo(self) end,
        },
    }

    lib.registerContext({
        id      = 'qbx_policeroles_mdt',
        title   = '🚓  M D T   T E R M I N A L',
        options = options,
    })
    lib.showContext('qbx_policeroles_mdt')
    _ = statusColor
end

-- ---- Citizen search ----------------------------------------------------------

function openCitizenSearch(self)
    local input = lib.inputDialog('🔎  CITIZEN LOOKUP', {
        { type = 'input', label = 'Name, citizenid, or phone', required = true, min = 2, max = 60, icon = 'magnifying-glass' },
    })
    if not input then openDashboard() return end

    local results = cb('qbx_policeroles:mdt:searchCitizens', false, input[1]) or {}
    if #results == 0 then
        notify('No matches found.', 'error')
        openDashboard()
        return
    end

    local options = {}
    for _, c in ipairs(results) do
        options[#options + 1] = {
            title       = ('%s %s'):format(c.firstname, c.lastname),
            description = ('CID: %s   •   📞 %s'):format(c.citizenid, c.phone or '—'),
            icon        = 'user',
            iconColor   = '#3B82F6',
            arrow       = true,
            metadata    = {
                { label = 'Date of Birth', value = c.dob or '—' },
                { label = 'Gender',        value = c.gender or '—' },
            },
            onSelect = function() openCitizenDossier(self, c.citizenid) end,
        }
    end

    lib.registerContext({
        id      = 'qbx_policeroles_mdt_citizens',
        title   = '🔎  CITIZEN RESULTS  •  ' .. tostring(#results),
        menu    = 'qbx_policeroles_mdt',
        options = options,
    })
    lib.showContext('qbx_policeroles_mdt_citizens')
end

-- ---- Citizen dossier ---------------------------------------------------------

function openCitizenDossier(self, cid)
    local d = cb('qbx_policeroles:mdt:citizenDossier', false, cid)
    if not d then notify('Citizen not found.', 'error') openDashboard() return end

    local licenseSummary = {}
    if #d.licenses.active == 0 then
        licenseSummary[1] = 'None'
    else
        for _, c in ipairs(d.licenses.active) do
            licenseSummary[#licenseSummary + 1] = 'Class ' .. tostring(c)
        end
    end

    local options = {
        {
            title       = '— PROFILE —',
            description = d.name,
            icon        = 'id-badge',
            iconColor   = '#FFD700',
            readOnly    = true,
            metadata    = {
                { label = 'CID',         value = d.citizenid },
                { label = 'DOB',         value = d.dob or '—' },
                { label = 'Phone',       value = d.phone or '—' },
                { label = 'Gender',      value = d.gender or '—' },
                { label = 'Nationality', value = d.nationality or '—' },
                { label = 'Job',         value = d.job or '—' },
                { label = 'Weapon Lic.', value = table.concat(licenseSummary, ', ') },
            },
        },
        {
            title       = ('📋  RECORDS  ·  %d entr%s'):format(#d.records, (#d.records == 1) and 'y' or 'ies'),
            description = 'Charges, warrants, notes',
            icon        = 'folder-open',
            iconColor   = '#A855F7',
            arrow       = true,
            onSelect    = function()
                local opts = {}
                for _, r in ipairs(d.records) do
                    local sv = sevVis(r.severity)
                    opts[#opts + 1] = {
                        title       = ('[%s]  %s'):format((r.type or 'note'):upper(), r.title),
                        description = ('%s  •  $%d  •  %d min  •  %s'):format(sv.label, r.fine or 0, r.jail_minutes or 0, r.officer_name or '?'),
                        icon        = sv.icon,
                        iconColor   = sv.color,
                        metadata    = {
                            { label = 'When',     value = tostring(r.created_at) },
                            { label = 'Status',   value = (r.resolved == 1) and 'resolved' or 'open' },
                            { label = 'Details',  value = r.body ~= '' and r.body or '—' },
                        },
                        onSelect = function()
                            if r.resolved == 1 then notify('Already resolved.', 'inform') return end
                            local ok = cb('qbx_policeroles:mdt:resolveRecord', false, r.id)
                            notify(ok and 'Record resolved.' or 'Failed.', ok and 'success' or 'error')
                            openCitizenDossier(self, cid)
                        end,
                    }
                end
                if #opts == 0 then
                    opts[1] = { title = 'No records on file', readOnly = true, icon = 'check' }
                end
                lib.registerContext({
                    id = 'qbx_policeroles_mdt_dossier_records', title = '📋  ' .. d.name .. ' — RECORDS',
                    menu = 'qbx_policeroles_mdt_dossier', options = opts,
                })
                lib.showContext('qbx_policeroles_mdt_dossier_records')
            end,
        },
        {
            title       = '✚  FILE NEW REPORT',
            description = 'Charge, warrant, or note',
            icon        = 'file-pen',
            iconColor   = '#10B981',
            arrow       = true,
            onSelect    = function() openCreateRecord(self, d) end,
        },
        {
            title       = '🔫  WEAPON LICENSES',
            description = self.canIssueLic and 'Issue or revoke' or 'View only',
            icon        = 'gun',
            iconColor   = '#F59E0B',
            arrow       = true,
            onSelect    = function() openLicensePanel(self, d) end,
        },
        {
            title       = ('🚗  REGISTERED VEHICLES  ·  %d'):format(#d.vehicles),
            description = 'Plates owned by this citizen',
            icon        = 'car',
            iconColor   = '#10B981',
            arrow       = true,
            onSelect    = function()
                local opts = {}
                for _, v in ipairs(d.vehicles) do
                    opts[#opts + 1] = {
                        title       = v.plate,
                        description = ('Model: %s   •   %s'):format(v.vehicle, v.state == 0 and 'in garage' or 'out'),
                        icon        = 'car',
                        iconColor   = '#10B981',
                        metadata    = { { label = 'Garage', value = v.garage or '—' } },
                    }
                end
                if #opts == 0 then opts[1] = { title = 'No vehicles registered', readOnly = true, icon = 'ban' } end
                lib.registerContext({
                    id = 'qbx_policeroles_mdt_dossier_vehicles', title = '🚗  ' .. d.name .. ' — VEHICLES',
                    menu = 'qbx_policeroles_mdt_dossier', options = opts,
                })
                lib.showContext('qbx_policeroles_mdt_dossier_vehicles')
            end,
        },
    }

    lib.registerContext({
        id      = 'qbx_policeroles_mdt_dossier',
        title   = '👤  DOSSIER  •  ' .. d.name:upper(),
        menu    = 'qbx_policeroles_mdt_citizens',
        options = options,
    })
    lib.showContext('qbx_policeroles_mdt_dossier')
end

-- ---- License panel -----------------------------------------------------------

function openLicensePanel(self, d)
    local active = {}
    for _, c in ipairs(d.licenses.active) do active[c] = true end

    local options = {
        {
            title    = '— ACTIVE LICENSES —',
            description = d.name,
            icon     = 'id-card-clip',
            iconColor = '#FFD700',
            readOnly = true,
        },
    }

    for class = 1, 3 do
        local vis = CLASS_VIS[class]
        local has = active[class] == true
        options[#options + 1] = {
            title       = vis.label .. (has and '   ✓ ACTIVE' or '   ✖ NONE'),
            description = has and 'Citizen may purchase these weapons' or 'Citizen is BLOCKED from purchasing these',
            icon        = vis.icon,
            iconColor   = has and '#10B981' or vis.color,
            disabled    = not self.canIssueLic,
            arrow       = self.canIssueLic,
            onSelect    = function()
                if not self.canIssueLic then notify('Not authorized to issue licenses.', 'error') return end
                if has then
                    local confirm = lib.alertDialog({
                        header  = '⚠  REVOKE ' .. vis.label,
                        content = ('Revoke %s license from %s?'):format(vis.label, d.name),
                        cancel  = true,
                        labels  = { confirm = 'Revoke', cancel = 'Cancel' },
                    })
                    if confirm == 'confirm' then
                        local ok = cb('qbx_policeroles:mdt:revokeLicense', false, d.citizenid, class)
                        notify(ok and 'License revoked.' or 'Failed.', ok and 'success' or 'error')
                        openCitizenDossier(self, d.citizenid)
                    end
                else
                    local confirm = lib.alertDialog({
                        header  = '✚  ISSUE ' .. vis.label,
                        content = ('Issue %s to %s? This will allow them to purchase the listed weapon class.'):format(vis.label, d.name),
                        cancel  = true,
                        labels  = { confirm = 'Issue', cancel = 'Cancel' },
                    })
                    if confirm == 'confirm' then
                        local ok, err = cb('qbx_policeroles:mdt:issueLicense', false, d.citizenid, class)
                        notify(ok and 'License issued.' or ('Failed: ' .. tostring(err)), ok and 'success' or 'error')
                        openCitizenDossier(self, d.citizenid)
                    end
                end
            end,
        }
    end

    lib.registerContext({
        id      = 'qbx_policeroles_mdt_licenses',
        title   = '🔫  WEAPON LICENSES  •  ' .. d.name:upper(),
        menu    = 'qbx_policeroles_mdt_dossier',
        options = options,
    })
    lib.showContext('qbx_policeroles_mdt_licenses')
end

-- ---- Create record -----------------------------------------------------------

function openCreateRecord(self, d)
    local input = lib.inputDialog('✚  NEW REPORT  •  ' .. d.name, {
        { type = 'select', label = 'Type', required = true, options = {
            { value = 'charge',  label = 'Criminal Charge' },
            { value = 'warrant', label = 'Warrant'         },
            { value = 'note',    label = 'Note / Field interview' },
        }},
        { type = 'select', label = 'Severity', required = true, options = {
            { value = 'minor',    label = 'Minor'    },
            { value = 'moderate', label = 'Moderate' },
            { value = 'severe',   label = 'Severe'   },
            { value = 'felony',   label = 'Felony'   },
        }},
        { type = 'input',    label = 'Title',           required = true, max = 200 },
        { type = 'textarea', label = 'Details / body',  max = 2000 },
        { type = 'number',   label = 'Fine ($)',        min = 0, default = 0 },
        { type = 'number',   label = 'Jail (minutes)',  min = 0, default = 0 },
    })
    if not input then openCitizenDossier(self, d.citizenid) return end

    local ok, err, penalty = cb('qbx_policeroles:mdt:createRecord', false, {
        citizenid    = d.citizenid,
        type         = input[1],
        severity     = input[2],
        title        = input[3],
        body         = input[4],
        fine         = input[5],
        jail_minutes = input[6],
    })

    if not ok then
        notify('Failed: ' .. tostring(err), 'error')
    else
        notify('Report filed.', 'success')
        if penalty and (penalty.fine_requested > 0 or penalty.jail_minutes > 0) then
            local lines = {}
            if not penalty.target_online then
                lines[#lines + 1] = '⚠  Citizen is offline — penalties not applied.'
            else
                if penalty.fine_requested > 0 then
                    lines[#lines + 1] = ('💰 Collected $%d  (bank $%d • cash $%d)'):format(
                        penalty.fine_taken, penalty.from_bank, penalty.from_cash)
                    if penalty.fine_unpaid > 0 then
                        lines[#lines + 1] = ('❗ Unpaid balance: $%d'):format(penalty.fine_unpaid)
                    end
                end
                if penalty.jailed then
                    lines[#lines + 1] = ('🔒 Jailed for %d minute(s).'):format(penalty.jail_minutes)
                end
            end
            lib.notify({
                title       = 'Penalty Applied',
                description = table.concat(lines, '\n'),
                type        = (penalty.target_online and penalty.fine_unpaid == 0) and 'success' or 'warning',
                duration    = 9000,
                position    = 'top',
            })
        end
    end
    openCitizenDossier(self, d.citizenid)
end

-- ---- Vehicle search ----------------------------------------------------------

function openVehicleSearch(self)
    local input = lib.inputDialog('🚗  PLATE LOOKUP', {
        { type = 'input', label = 'License plate (partial OK)', required = true, min = 2, max = 8, icon = 'car' },
    })
    if not input then openDashboard() return end

    local results = cb('qbx_policeroles:mdt:searchVehicles', false, input[1]) or {}
    if #results == 0 then notify('No vehicles match that plate.', 'error') openDashboard() return end

    local options = {}
    for _, v in ipairs(results) do
        options[#options + 1] = {
            title       = v.plate,
            description = ('%s   •   owner: %s'):format(v.model, v.owner),
            icon        = 'car',
            iconColor   = '#10B981',
            metadata    = {
                { label = 'Model',     value = v.model },
                { label = 'Owner',     value = v.owner },
                { label = 'Owner CID', value = v.owner_cid or '—' },
                { label = 'State',     value = v.state == 0 and 'In garage' or 'Out / impounded?' },
                { label = 'Garage',    value = v.garage or '—' },
            },
            onSelect = function()
                if v.owner_cid then openCitizenDossier(self, v.owner_cid) end
            end,
        }
    end
    lib.registerContext({
        id      = 'qbx_policeroles_mdt_vehicles',
        title   = '🚗  VEHICLE RESULTS  •  ' .. tostring(#results),
        menu    = 'qbx_policeroles_mdt',
        options = options,
    })
    lib.showContext('qbx_policeroles_mdt_vehicles')
end

-- ---- BOLOs -------------------------------------------------------------------

function openBoloList(self)
    local list = cb('qbx_policeroles:mdt:listBolos', false) or {}
    local options = {}
    for _, b in ipairs(list) do
        local sv = sevVis(b.severity)
        options[#options + 1] = {
            title       = '[' .. sv.label:upper() .. ']  ' .. b.subject,
            description = b.description,
            icon        = 'bullhorn',
            iconColor   = sv.color,
            metadata    = {
                { label = 'Posted',  value = tostring(b.created_at) },
                { label = 'Officer', value = b.created_by or '—' },
            },
            onSelect = function()
                local confirm = lib.alertDialog({
                    header  = 'Clear BOLO: ' .. b.subject,
                    content = 'Mark this BOLO as cleared?',
                    cancel  = true,
                })
                if confirm == 'confirm' then
                    local ok = cb('qbx_policeroles:mdt:clearBolo', false, b.id)
                    notify(ok and 'BOLO cleared.' or 'Failed.', ok and 'success' or 'error')
                    openBoloList(self)
                end
            end,
        }
    end
    if #options == 0 then options[1] = { title = 'No active BOLOs', readOnly = true, icon = 'check' } end
    lib.registerContext({
        id = 'qbx_policeroles_mdt_bolos', title = '📣  ACTIVE BOLOS  •  ' .. tostring(#list),
        menu = 'qbx_policeroles_mdt', options = options,
    })
    lib.showContext('qbx_policeroles_mdt_bolos')
end

function openCreateBolo(self)
    local input = lib.inputDialog('📣  NEW BOLO', {
        { type = 'input',    label = 'Subject (person / vehicle / plate)', required = true, max = 200 },
        { type = 'textarea', label = 'Description',                         max = 2000 },
        { type = 'select',   label = 'Severity', required = true, options = {
            { value = 'minor',    label = 'Minor'    },
            { value = 'moderate', label = 'Moderate' },
            { value = 'severe',   label = 'Severe'   },
            { value = 'felony',   label = 'Felony'   },
        }},
    })
    if not input then openDashboard() return end
    local ok = cb('qbx_policeroles:mdt:createBolo', false, {
        subject = input[1], description = input[2], severity = input[3],
    })
    notify(ok and 'BOLO issued.' or 'Failed.', ok and 'success' or 'error')
    openDashboard()
end

-- ---- Entry point -------------------------------------------------------------

RegisterNetEvent('qbx_policeroles:openMDT', function()
    if not Client.data.isPolice then
        Client.Notify(Client.L('not_police'), 'error')
        return
    end
    openDashboard()
end)
