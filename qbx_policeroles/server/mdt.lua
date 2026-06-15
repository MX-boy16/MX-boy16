-- Police MDT server logic.
-- All queries gated by Roles.IsPolice + (for sensitive ops) Roles.IsOnDuty / LicenseIssuers role check.

MDT = {}

local QBX = exports.qbx_core

local function canUseMDT(src)
    return Roles.IsPolice(src)
end

local function canIssueLicense(src)
    if not Roles.IsPolice(src) then return false end
    if not Roles.IsOnDuty(src) then return false end
    local allowed = Config.MDT.LicenseIssuers or {}
    if #allowed == 0 then return true end                 -- any police on duty
    if Roles.IsLeader(src) then return true end
    return Roles.HasAnyRole(src, allowed)
end

local function jdecode(s)
    if not s or s == '' then return {} end
    local ok, v = pcall(json.decode, s)
    return ok and v or {}
end

-- ===========================================================
-- Citizen search
-- ===========================================================

local function searchCitizens(query)
    query = (query or ''):lower()
    if #query < 2 then return {} end

    local like = '%' .. query .. '%'
    local rows = MySQL.query.await([[
        SELECT citizenid, charinfo, metadata
        FROM players
        WHERE citizenid LIKE ?
           OR LOWER(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname'))) LIKE ?
           OR LOWER(JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) LIKE ?
           OR LOWER(CONCAT(
                JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), ' ',
                JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))
              )) LIKE ?
           OR JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.phone')) LIKE ?
        LIMIT ?
    ]], { like, like, like, like, like, Config.MDT.MaxResults })

    local out = {}
    for _, r in ipairs(rows or {}) do
        local ci = jdecode(r.charinfo)
        out[#out + 1] = {
            citizenid = r.citizenid,
            firstname = ci.firstname or '?',
            lastname  = ci.lastname  or '?',
            phone     = ci.phone,
            dob       = ci.birthdate,
            gender    = ci.gender,
        }
    end
    return out
end

local function citizenDossier(cid)
    if not cid then return nil end
    local row = MySQL.single.await(
        'SELECT citizenid, charinfo, metadata FROM players WHERE citizenid = ?',
        { cid }
    )
    if not row then return nil end

    local ci = jdecode(row.charinfo)
    local md = jdecode(row.metadata)

    -- Vehicles
    local vehicles = MySQL.query.await([[
        SELECT plate, vehicle, garage, state
        FROM player_vehicles
        WHERE citizenid = ?
        LIMIT 50
    ]], { cid }) or {}

    -- Police records
    local records = MySQL.query.await([[
        SELECT id, type, title, body, severity, fine, jail_minutes, officer_name, created_at, resolved
        FROM police_mdt_records
        WHERE citizenid = ?
        ORDER BY created_at DESC
        LIMIT 100
    ]], { cid }) or {}

    -- Licenses (active + history)
    local active = Licenses.GetActive(cid)
    local activeList = {}
    for cls in pairs(active) do activeList[#activeList + 1] = cls end
    table.sort(activeList)

    local policeRoles = DB.GetPlayerRoles(cid)

    return {
        citizenid = cid,
        name      = ('%s %s'):format(ci.firstname or '?', ci.lastname or ''),
        firstname = ci.firstname,
        lastname  = ci.lastname,
        dob       = ci.birthdate,
        phone     = ci.phone,
        gender    = ci.gender,
        nationality = ci.nationality,
        job       = (md.job and md.job.label) or nil,
        vehicles  = vehicles,
        records   = records,
        licenses  = {
            active  = activeList,
            history = Licenses.History(cid),
        },
        policeRoles = policeRoles,
    }
end

-- ===========================================================
-- Vehicle search
-- ===========================================================

local function searchVehicles(query)
    query = (query or ''):upper():gsub('%s+', '')
    if #query < 2 then return {} end
    local like = '%' .. query .. '%'
    local rows = MySQL.query.await([[
        SELECT pv.plate, pv.vehicle, pv.garage, pv.state, pv.citizenid,
               p.charinfo
        FROM player_vehicles pv
        LEFT JOIN players p ON p.citizenid = pv.citizenid
        WHERE pv.plate LIKE ?
        LIMIT ?
    ]], { like, Config.MDT.MaxResults }) or {}

    local out = {}
    for _, r in ipairs(rows) do
        local ci = jdecode(r.charinfo)
        out[#out + 1] = {
            plate     = r.plate,
            model     = r.vehicle,
            state     = r.state,
            garage    = r.garage,
            owner_cid = r.citizenid,
            owner     = ('%s %s'):format(ci.firstname or '?', ci.lastname or ''),
        }
    end
    return out
end

-- ===========================================================
-- Records (charges / notes / warrants / BOLOs)
-- ===========================================================

local function applyPenalties(officerSrc, targetCid, fine, jailMinutes)
    local result = {
        fine_requested = fine or 0,
        fine_taken     = 0,
        fine_unpaid    = 0,
        from_bank      = 0,
        from_cash      = 0,
        jail_minutes   = jailMinutes or 0,
        jailed         = false,
        target_online  = false,
        message        = nil,
    }

    if not Config.MDT.AutoApplyPenalties then
        result.message = 'Auto-penalties disabled in config.'
        return result
    end

    if (fine or 0) <= 0 and (jailMinutes or 0) <= 0 then
        return result
    end

    local targetSrc = Roles.FindOnlineByCid(targetCid)
    if not targetSrc then
        result.message     = 'Citizen offline — penalties not applied.'
        result.fine_unpaid = fine or 0
        return result
    end
    result.target_online = true

    local target = QBX:GetPlayer(targetSrc)
    if not target then return result end

    -- Fine
    if (fine or 0) > 0 then
        local remaining = fine
        local acct      = Config.MDT.FineAccount or 'bank'
        local reason    = 'Police fine — filed by officer ' .. tostring(officerSrc)

        local bankBal = target.PlayerData.money[acct] or 0
        local takeBank = math.min(bankBal, remaining)
        if takeBank > 0 then
            target.Functions.RemoveMoney(acct, takeBank, reason)
            result.from_bank = takeBank
            remaining = remaining - takeBank
        end

        if remaining > 0 and Config.MDT.AllowCashFallback then
            local cashBal = target.PlayerData.money.cash or 0
            local takeCash = math.min(cashBal, remaining)
            if takeCash > 0 then
                target.Functions.RemoveMoney('cash', takeCash, reason)
                result.from_cash = takeCash
                remaining = remaining - takeCash
            end
        end

        result.fine_taken  = (result.from_bank + result.from_cash)
        result.fine_unpaid = remaining

        TriggerClientEvent('ox_lib:notify', targetSrc, {
            title       = 'Fine Issued',
            description = ('$%d debited (bank: $%d, cash: $%d%s)'):format(
                result.fine_taken, result.from_bank, result.from_cash,
                remaining > 0 and (', UNPAID: $' .. remaining) or ''
            ),
            type        = 'error',
            duration    = 8000,
            icon        = 'sack-dollar',
        })
    end

    -- Jail
    if (jailMinutes or 0) > 0 then
        for _, ev in ipairs(Config.MDT.JailClientEvents or {}) do
            local val = (ev.arg == 'seconds') and (jailMinutes * 60) or jailMinutes
            TriggerClientEvent(ev.event, targetSrc, val)
        end
        if Config.MDT.SetInJailMetadata then
            target.Functions.SetMetaData('injail', jailMinutes * 60)
        end
        result.jailed = true

        TriggerClientEvent('ox_lib:notify', targetSrc, {
            title       = 'Sentenced',
            description = ('You have been sentenced to %d minute(s) in jail.'):format(jailMinutes),
            type        = 'error',
            duration    = 8000,
            icon        = 'handcuffs',
        })
    end

    return result
end

local function createRecord(officerSrc, data)
    local p = QBX:GetPlayer(officerSrc)
    if not p then return false, 'not_logged_in' end

    local cid = data.citizenid
    if not cid then return false, 'player_not_found' end

    -- Validate target exists
    local target = MySQL.single.await('SELECT citizenid FROM players WHERE citizenid = ?', { cid })
    if not target then return false, 'player_not_found' end

    local officerName = ('%s %s'):format(p.PlayerData.charinfo.firstname or '?', p.PlayerData.charinfo.lastname or '')

    local fine         = tonumber(data.fine) or 0
    local jailMinutes  = tonumber(data.jail_minutes) or 0

    local id = MySQL.insert.await([[
        INSERT INTO police_mdt_records
            (citizenid, type, title, body, severity, fine, jail_minutes, officer_cid, officer_name)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        cid,
        data.type or 'note',
        data.title or '(untitled)',
        data.body or '',
        data.severity or 'minor',
        fine,
        jailMinutes,
        p.PlayerData.citizenid,
        officerName,
    })

    if not (id and id > 0) then return false, 'db_error' end

    local penalty = applyPenalties(officerSrc, cid, fine, jailMinutes)
    return true, nil, penalty
end

local function resolveRecord(officerSrc, recordId)
    return (MySQL.update.await(
        'UPDATE police_mdt_records SET resolved = 1 WHERE id = ?',
        { recordId }
    ) or 0) > 0
end

local function listBolos()
    return MySQL.query.await([[
        SELECT id, subject, description, severity, created_by, created_at
        FROM police_mdt_bolos
        WHERE active = 1
        ORDER BY created_at DESC
        LIMIT 50
    ]]) or {}
end

local function createBolo(officerSrc, data)
    local p = QBX:GetPlayer(officerSrc)
    if not p then return false end
    local id = MySQL.insert.await([[
        INSERT INTO police_mdt_bolos (subject, description, severity, created_by)
        VALUES (?, ?, ?, ?)
    ]], { data.subject or '(no subject)', data.description or '', data.severity or 'moderate', p.PlayerData.citizenid })
    return id and id > 0
end

local function clearBolo(officerSrc, boloId)
    return (MySQL.update.await('UPDATE police_mdt_bolos SET active = 0 WHERE id = ?', { boloId }) or 0) > 0
end

-- ===========================================================
-- Callbacks
-- ===========================================================

lib.callback.register('qbx_policeroles:mdt:openSelf', function(source)
    if not canUseMDT(source) then return nil end
    local p = QBX:GetPlayer(source)
    if not p then return nil end
    local officerName = ('%s %s'):format(p.PlayerData.charinfo.firstname or '?', p.PlayerData.charinfo.lastname or '')
    return {
        officerName  = officerName,
        callsign     = p.PlayerData.metadata and p.PlayerData.metadata.callsign or 'NO CALLSIGN',
        onDuty       = Roles.IsOnDuty(source),
        roles        = Roles.GetRoles(source),
        canIssueLic  = canIssueLicense(source),
        permissions  = Roles.GetPermissions(source),
        isLeader     = Roles.IsLeader(source),
    }
end)

lib.callback.register('qbx_policeroles:mdt:searchCitizens', function(source, q)
    if not canUseMDT(source) then return {} end
    return searchCitizens(q)
end)

lib.callback.register('qbx_policeroles:mdt:citizenDossier', function(source, cid)
    if not canUseMDT(source) then return nil end
    return citizenDossier(cid)
end)

lib.callback.register('qbx_policeroles:mdt:searchVehicles', function(source, q)
    if not canUseMDT(source) then return {} end
    return searchVehicles(q)
end)

lib.callback.register('qbx_policeroles:mdt:issueLicense', function(source, cid, class)
    if not canIssueLicense(source) then return false, 'no_permission' end
    local p = QBX:GetPlayer(source)
    local ok, err = Licenses.Issue(cid, class, p and p.PlayerData.citizenid or 'unknown')
    return ok, err
end)

lib.callback.register('qbx_policeroles:mdt:revokeLicense', function(source, cid, class)
    if not canIssueLicense(source) then return false, 'no_permission' end
    local p = QBX:GetPlayer(source)
    local ok = Licenses.Revoke(cid, class, p and p.PlayerData.citizenid or 'unknown')
    return ok
end)

lib.callback.register('qbx_policeroles:mdt:createRecord', function(source, data)
    if not canUseMDT(source) then return false, 'no_permission' end
    local ok, err, penalty = createRecord(source, data)
    return ok, err, penalty
end)

lib.callback.register('qbx_policeroles:mdt:resolveRecord', function(source, id)
    if not canUseMDT(source) then return false end
    return resolveRecord(source, id)
end)

lib.callback.register('qbx_policeroles:mdt:listBolos', function(source)
    if not canUseMDT(source) then return {} end
    return listBolos()
end)

lib.callback.register('qbx_policeroles:mdt:createBolo', function(source, data)
    if not canUseMDT(source) then return false end
    return createBolo(source, data)
end)

lib.callback.register('qbx_policeroles:mdt:clearBolo', function(source, id)
    if not canUseMDT(source) then return false end
    return clearBolo(source, id)
end)

-- /mdt command
lib.addCommand(Config.MDT.Command, {
    help = 'Open the Police MDT',
}, function(source)
    if not canUseMDT(source) then
        TriggerClientEvent('qbx_policeroles:notify', source, 'not_police', 'error')
        return
    end
    TriggerClientEvent('qbx_policeroles:openMDT', source)
end)
