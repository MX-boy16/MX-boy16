Roles = {}

-- In-memory cache:  citizenid -> { 'swat', 'officer', ... }
local roleCache = {}
-- Online sources currently on duty:  src(number) -> true
local onDuty = {}

local QBX = exports.qbx_core

---Returns qbx Player object or nil.
function Roles.GetPlayer(src)
    return QBX:GetPlayer(src)
end

function Roles.IsPolice(src)
    local p = Roles.GetPlayer(src)
    if not p then return false end
    return p.PlayerData.job and p.PlayerData.job.name == Config.PoliceJob
end

function Roles.GetCitizenId(src)
    local p = Roles.GetPlayer(src)
    return p and p.PlayerData.citizenid or nil
end

function Roles.IsLeader(src)
    local p = Roles.GetPlayer(src)
    if not p then return false end
    if not (p.PlayerData.job and p.PlayerData.job.name == Config.PoliceJob) then return false end
    local grade = p.PlayerData.job.grade and (p.PlayerData.job.grade.level or p.PlayerData.job.grade) or 0
    return tonumber(grade) and tonumber(grade) >= Config.LeaderGrade
end

---Load roles for a citizenid into cache (always re-reads from DB).
function Roles.LoadCitizen(citizenid)
    if not citizenid then return {} end
    local list = DB.GetPlayerRoles(citizenid)
    roleCache[citizenid] = list
    return list
end

function Roles.GetRolesByCid(citizenid)
    if not citizenid then return {} end
    if not roleCache[citizenid] then
        return Roles.LoadCitizen(citizenid)
    end
    return roleCache[citizenid]
end

function Roles.GetRoles(src)
    local cid = Roles.GetCitizenId(src)
    if not cid then return {} end
    return Roles.GetRolesByCid(cid)
end

function Roles.HasRole(src, role)
    if not role then return false end
    return Shared.contains(Roles.GetRoles(src), role)
end

function Roles.HasAnyRole(src, list)
    return Shared.anyMatch(Roles.GetRoles(src), list)
end

---Aggregate permissions from all of player's assigned roles.
function Roles.GetPermissions(src)
    local defs = DB.GetAllRoleDefinitions()
    local perms = {}
    for _, roleName in ipairs(Roles.GetRoles(src)) do
        local def = defs[roleName]
        if def and def.permissions then
            for _, p in ipairs(def.permissions) do perms[p] = true end
        end
    end
    return perms
end

function Roles.HasPermission(src, perm)
    if Roles.IsLeader(src) then return true end
    local perms = Roles.GetPermissions(src)
    return perms[perm] == true or perms['access_all'] == true
end

---Can this source manage (assign/remove/create/delete) roles?
function Roles.CanManage(src)
    if Roles.IsLeader(src) then return true end
    if not Config.AllowDelegatedManagement then return false end
    if not Roles.IsPolice(src) then return false end
    return Roles.HasPermission(src, 'can_manage_roles')
end

-- ===========================================================
-- Mutations
-- ===========================================================

function Roles.AssignRole(targetSrc, roleName, grantedBy)
    local cid = Roles.GetCitizenId(targetSrc)
    if not cid then return false, 'player_not_found' end
    local def = DB.GetRoleDefinition(roleName)
    if not def then return false, 'role_not_found' end
    local ok = DB.AssignRole(cid, roleName, grantedBy)
    Roles.LoadCitizen(cid)
    Roles.PushClient(targetSrc)
    return ok, ok and nil or 'role_exists'
end

function Roles.RemoveRole(targetSrc, roleName)
    local cid = Roles.GetCitizenId(targetSrc)
    if not cid then return false, 'player_not_found' end
    local ok = DB.RemoveRole(cid, roleName)
    Roles.LoadCitizen(cid)
    Roles.PushClient(targetSrc)
    return ok
end

function Roles.AssignByCid(cid, roleName, grantedBy)
    local def = DB.GetRoleDefinition(roleName)
    if not def then return false, 'role_not_found' end
    local ok = DB.AssignRole(cid, roleName, grantedBy)
    Roles.LoadCitizen(cid)
    -- if player is online, push update
    local src = Roles.FindOnlineByCid(cid)
    if src then Roles.PushClient(src) end
    return ok
end

function Roles.RemoveByCid(cid, roleName)
    local ok = DB.RemoveRole(cid, roleName)
    Roles.LoadCitizen(cid)
    local src = Roles.FindOnlineByCid(cid)
    if src then Roles.PushClient(src) end
    return ok
end

---Iterates all currently connected players and finds one with matching citizenid.
function Roles.FindOnlineByCid(cid)
    for _, src in ipairs(GetPlayers()) do
        local p = QBX:GetPlayer(tonumber(src))
        if p and p.PlayerData.citizenid == cid then
            return tonumber(src)
        end
    end
    return nil
end

-- ===========================================================
-- Duty
-- ===========================================================

function Roles.IsOnDuty(src)
    return onDuty[src] == true
end

function Roles.ToggleDuty(src)
    onDuty[src] = not onDuty[src]
    return onDuty[src]
end

function Roles.ClearDuty(src) onDuty[src] = nil end

-- ===========================================================
-- Client sync
-- ===========================================================

function Roles.PushClient(src)
    if not src then return end
    local roles = Roles.GetRoles(src)
    local perms = Roles.GetPermissions(src)
    TriggerClientEvent('qbx_policeroles:sync', src, {
        roles       = roles,
        permissions = perms,
        isPolice    = Roles.IsPolice(src),
        isLeader    = Roles.IsLeader(src),
        canManage   = Roles.CanManage(src),
        onDuty      = Roles.IsOnDuty(src),
    })
end

function Roles.OnPlayerDrop(src)
    Roles.ClearDuty(src)
end
