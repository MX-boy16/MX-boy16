-- Weapon license storage + checks.
-- Schema: police_weapon_licenses (citizenid, class, issued_by, issued_at, revoked).
-- A player may hold at most ONE active license per class.

Licenses = {}

-- in-memory cache: citizenid -> { [class] = true }
local cache = {}

local function loadIntoCache(cid)
    cache[cid] = {}
    local rows = MySQL.query.await(
        'SELECT class FROM police_weapon_licenses WHERE citizenid = ? AND revoked = 0',
        { cid }
    ) or {}
    for _, r in ipairs(rows) do
        cache[cid][tonumber(r.class)] = true
    end
    return cache[cid]
end

function Licenses.GetActive(cid)
    if not cid then return {} end
    if not cache[cid] then loadIntoCache(cid) end
    return cache[cid]
end

function Licenses.HasActive(cid, class)
    if not cid or not class then return false end
    local active = Licenses.GetActive(cid)
    return active[tonumber(class)] == true
end

---Issue a license. Returns ok, errorKey.
function Licenses.Issue(cid, class, issuedByCid)
    if not cid or not class then return false, 'invalid_args' end
    class = tonumber(class)
    if not Config.LicenseClasses[class] then return false, 'invalid_class' end

    if Licenses.HasActive(cid, class) then return false, 'license_already_active' end

    local id = MySQL.insert.await([[
        INSERT INTO police_weapon_licenses (citizenid, class, issued_by, revoked)
        VALUES (?, ?, ?, 0)
    ]], { cid, class, issuedByCid or 'unknown' })

    cache[cid] = cache[cid] or {}
    cache[cid][class] = true
    return id and id > 0, nil
end

---Revoke ANY active license of this class held by cid.
function Licenses.Revoke(cid, class, revokedByCid)
    if not cid or not class then return false, 'invalid_args' end
    class = tonumber(class)
    local n = MySQL.update.await([[
        UPDATE police_weapon_licenses
        SET revoked = 1, revoked_by = ?, revoked_at = CURRENT_TIMESTAMP
        WHERE citizenid = ? AND class = ? AND revoked = 0
    ]], { revokedByCid or 'unknown', cid, class })

    if cache[cid] then cache[cid][class] = nil end
    return (n or 0) > 0
end

---Full history for a citizen (incl. revoked).
function Licenses.History(cid)
    return MySQL.query.await([[
        SELECT id, class, issued_by, issued_at, revoked, revoked_by, revoked_at
        FROM police_weapon_licenses
        WHERE citizenid = ?
        ORDER BY issued_at DESC
        LIMIT 50
    ]], { cid }) or {}
end

function Licenses.InvalidateCache(cid)
    cache[cid] = nil
end

---Mirror license state into the qbx metadata.licences map so the
---server's existing weapon-shop / vendor system (which reads metadata)
---also recognises the player as licensed.
function Licenses.SyncMetadata(cid)
    if not Config.SyncToMetadata then return end
    if not cid then return end
    local src = Roles.FindOnlineByCid(cid)
    if not src then return end
    local p = exports.qbx_core:GetPlayer(src)
    if not p then return end

    local active = Licenses.GetActive(cid)
    local licences = p.PlayerData.metadata.licences or {}

    local anyActive = (active[1] or active[2] or active[3]) and true or false

    -- Generic flag: any class = "weapon license" (matches stock qb/qbx checks)
    licences.weapon         = anyActive
    -- Granular per-class flags (in case your shop wants them)
    licences.weapon_class_1 = active[1] == true
    licences.weapon_class_2 = active[2] == true
    licences.weapon_class_3 = active[3] == true

    p.Functions.SetMetaData('licences', licences)
end

-- Hook into the existing mutator functions so every issue/revoke also syncs.
local _origIssue  = Licenses.Issue
local _origRevoke = Licenses.Revoke

function Licenses.Issue(cid, class, issuedByCid)
    local ok, err = _origIssue(cid, class, issuedByCid)
    if ok then Licenses.SyncMetadata(cid) end
    return ok, err
end

function Licenses.Revoke(cid, class, revokedByCid)
    local ok = _origRevoke(cid, class, revokedByCid)
    if ok then Licenses.SyncMetadata(cid) end
    return ok
end

-- Re-sync on player load (DB may have changed while they were offline).
AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local p = exports.qbx_core:GetPlayer(src)
    if not p then return end
    cache[p.PlayerData.citizenid] = nil    -- force reload
    Licenses.SyncMetadata(p.PlayerData.citizenid)
end)

-- Exports for other resources
exports('HasWeaponLicense', function(src, class)
    local p = exports.qbx_core:GetPlayer(src)
    if not p then return false end
    return Licenses.HasActive(p.PlayerData.citizenid, class)
end)

exports('GetWeaponLicenses', function(src)
    local p = exports.qbx_core:GetPlayer(src)
    if not p then return {} end
    return Licenses.GetActive(p.PlayerData.citizenid)
end)

lib.callback.register('qbx_policeroles:getMyLicenses', function(source)
    local p = exports.qbx_core:GetPlayer(source)
    if not p then return {} end
    return Licenses.GetActive(p.PlayerData.citizenid)
end)
