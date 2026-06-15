-- Bootstrap + lifecycle + management RPCs.

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if Config.AutoInstallSQL then DB.Install() end
end)

AddEventHandler('playerDropped', function()
    local src = source
    Roles.OnPlayerDrop(src)
end)

-- qbx_core fires this when player fully loads
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    Roles.LoadCitizen(Roles.GetCitizenId(src))
    Roles.PushClient(src)
end)

RegisterNetEvent('qbx_core:server:onJobUpdate', function(_, _) end)

RegisterNetEvent('qbx_policeroles:requestSync', function()
    Roles.PushClient(source)
end)

-- ===========================================================
-- Management callbacks (used by ox_lib menu on client)
-- ===========================================================

lib.callback.register('qbx_policeroles:getRoleDefinitions', function(source)
    if not Roles.IsPolice(source) then return {} end
    local defs = DB.GetAllRoleDefinitions()
    local out = {}
    for _, d in pairs(defs) do out[#out + 1] = d end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end)

lib.callback.register('qbx_policeroles:getOnlineOfficers', function(source)
    if not Roles.CanManage(source) then return {} end
    local list = {}
    for _, sid in ipairs(GetPlayers()) do
        local s = tonumber(sid)
        if Roles.IsPolice(s) then
            local p = Roles.GetPlayer(s)
            list[#list + 1] = {
                source     = s,
                citizenid  = p.PlayerData.citizenid,
                name       = ('%s %s'):format(p.PlayerData.charinfo.firstname or '?', p.PlayerData.charinfo.lastname or ''),
                grade      = p.PlayerData.job.grade and p.PlayerData.job.grade.level or 0,
                gradeLabel = p.PlayerData.job.grade and p.PlayerData.job.grade.name or '',
                roles      = Roles.GetRoles(s),
            }
        end
    end
    table.sort(list, function(a, b) return (a.name or '') < (b.name or '') end)
    return list
end)

lib.callback.register('qbx_policeroles:assignRole', function(source, targetSrc, roleName)
    if not Roles.CanManage(source) then return false, 'no_permission' end
    local ok, err = Roles.AssignRole(targetSrc, roleName, Roles.GetCitizenId(source) or ('src:' .. source))
    return ok, err
end)

lib.callback.register('qbx_policeroles:removeRole', function(source, targetSrc, roleName)
    if not Roles.CanManage(source) then return false, 'no_permission' end
    local ok = Roles.RemoveRole(targetSrc, roleName)
    return ok
end)

lib.callback.register('qbx_policeroles:createRole', function(source, data)
    if not Roles.HasPermission(source, 'can_create_role') and not Roles.IsLeader(source) then
        return false, 'no_permission'
    end
    local name = Shared.normalizeRoleName(data.name)
    if not name then return false, 'role_not_found' end
    if DB.GetRoleDefinition(name) then return false, 'role_exists' end
    local ok = DB.CreateRole(name, data.label or name, data.description, data.permissions or {}, Roles.GetCitizenId(source))
    return ok, ok and nil or 'role_exists'
end)

lib.callback.register('qbx_policeroles:deleteRole', function(source, roleName)
    if not Roles.IsLeader(source) then return false, 'no_permission' end
    local def = DB.GetRoleDefinition(roleName)
    if not def then return false, 'role_not_found' end
    if def.is_default then return false, 'cannot_delete_default' end
    local ok = DB.DeleteRole(roleName)
    return ok
end)
