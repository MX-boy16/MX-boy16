-- Public exports + permission callbacks used by other resources / scripts.

Permissions = {}

---Check from server: does source have any of the given roles AND is police?
function Permissions.HasAccess(src, requiredRoles)
    if not Roles.IsPolice(src) then return false end
    if Roles.IsLeader(src) then return true end
    return Roles.HasAnyRole(src, requiredRoles)
end

---Find door config by id (string or number).
function Permissions.GetDoorConfig(doorId)
    if doorId == nil then return nil end
    for _, d in ipairs(Config.Doors) do
        if tostring(d.doorId) == tostring(doorId) then return d end
    end
    return nil
end

---Find stash config by id.
function Permissions.GetStashConfig(stashId)
    for _, s in ipairs(Config.Stashes) do
        if s.id == stashId then return s end
    end
    return nil
end

-- ===========================================================
-- Exports (consumable by other scripts on the server)
-- ===========================================================

exports('HasRole', function(src, role)
    return Roles.HasRole(src, role)
end)

exports('HasAnyRole', function(src, roles)
    return Roles.HasAnyRole(src, roles)
end)

exports('GetPlayerRoles', function(src)
    return Roles.GetRoles(src)
end)

exports('HasPermission', function(src, perm)
    return Roles.HasPermission(src, perm)
end)

exports('IsOnDuty', function(src)
    return Roles.IsOnDuty(src)
end)

exports('AssignRole', function(targetSrc, role, grantedBy)
    return Roles.AssignRole(targetSrc, role, grantedBy or 'export')
end)

exports('RemoveRole', function(targetSrc, role)
    return Roles.RemoveRole(targetSrc, role)
end)

-- ox_lib callback variant (preferred for ox_doorlock + ox_inventory custom checks)
lib.callback.register('qbx_policeroles:hasAccess', function(source, requiredRoles)
    return Permissions.HasAccess(source, requiredRoles or {})
end)

lib.callback.register('qbx_policeroles:doorAccess', function(source, doorId)
    local cfg = Permissions.GetDoorConfig(doorId)
    if not cfg then return true end -- door not gated by this script
    return Permissions.HasAccess(source, cfg.required or {})
end)

lib.callback.register('qbx_policeroles:stashAccess', function(source, stashId)
    local cfg = Permissions.GetStashConfig(stashId)
    if not cfg then return false end
    return Permissions.HasAccess(source, cfg.required or {})
end)
