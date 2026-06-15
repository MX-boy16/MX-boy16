local function notify(src, key, type_)
    TriggerClientEvent('qbx_policeroles:notify', src, key, type_ or 'inform')
end

local function getTargetSource(arg)
    if not arg then return nil end
    local id = tonumber(arg)
    if not id then return nil end
    if GetPlayerName(id) then return id end
    return nil
end

-- /policeadmin → opens the MDT tablet directly on the Roles tab (unified UX).
lib.addCommand(Config.ManageCommand, {
    help = 'Open role management (jumps into the MDT)',
}, function(source)
    if not Roles.CanManage(source) then
        notify(source, 'no_permission', 'error')
        return
    end
    TriggerClientEvent('qbx_policeroles:openMDT', source, 'roles')
end)

-- /myroles → list own roles
lib.addCommand(Config.MyRolesCommand, {
    help = 'View your assigned police roles',
}, function(source)
    if not Roles.IsPolice(source) then
        notify(source, 'not_police', 'error')
        return
    end
    Roles.PushClient(source)
    TriggerClientEvent('qbx_policeroles:showMyRoles', source)
end)

-- /duty → toggle on/off duty
lib.addCommand(Config.DutyCommand, {
    help = 'Toggle on/off duty',
}, function(source)
    if not Roles.IsPolice(source) then
        notify(source, 'not_police', 'error')
        return
    end
    local now = Roles.ToggleDuty(source)
    Roles.PushClient(source)
    TriggerClientEvent('qbx_policeroles:notify', source, now and 'duty_on' or 'duty_off', 'success')
end)

-- /policegive [id] [role]
lib.addCommand('policegive', {
    help = 'Assign a police role to a player',
    params = {
        { name = 'id',   type = 'playerId', help = 'Target player ID' },
        { name = 'role', type = 'string',   help = 'Role name' },
    },
}, function(source, args)
    if not Roles.CanManage(source) then notify(source, 'no_permission', 'error') return end
    local target = getTargetSource(args.id)
    if not target then notify(source, 'player_not_found', 'error') return end
    local roleName = Shared.normalizeRoleName(args.role)
    if not roleName then notify(source, 'role_not_found', 'error') return end

    local ok, err = Roles.AssignRole(target, roleName, Roles.GetCitizenId(source) or ('src:' .. source))
    if ok then
        TriggerClientEvent('qbx_policeroles:notifyFormat', source, 'role_assigned', { roleName, GetPlayerName(target) }, 'success')
        TriggerClientEvent('qbx_policeroles:notifyFormat', target, 'role_assigned', { roleName, GetPlayerName(target) }, 'success')
    else
        notify(source, err or 'role_not_found', 'error')
    end
end)

-- /policetake [id] [role]
lib.addCommand('policetake', {
    help = 'Remove a police role from a player',
    params = {
        { name = 'id',   type = 'playerId', help = 'Target player ID' },
        { name = 'role', type = 'string',   help = 'Role name' },
    },
}, function(source, args)
    if not Roles.CanManage(source) then notify(source, 'no_permission', 'error') return end
    local target = getTargetSource(args.id)
    if not target then notify(source, 'player_not_found', 'error') return end
    local roleName = Shared.normalizeRoleName(args.role)
    if not roleName then notify(source, 'role_not_found', 'error') return end

    local ok = Roles.RemoveRole(target, roleName)
    if ok then
        TriggerClientEvent('qbx_policeroles:notifyFormat', source, 'role_removed', { roleName, GetPlayerName(target) }, 'success')
        TriggerClientEvent('qbx_policeroles:notifyFormat', target, 'role_removed', { roleName, GetPlayerName(target) }, 'inform')
    else
        notify(source, 'role_not_found', 'error')
    end
end)
