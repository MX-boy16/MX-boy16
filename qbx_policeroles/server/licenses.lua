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
