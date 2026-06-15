-- ox_lib menu used by the Chief / managers (/policeadmin).

local function notify(text, type_) Client.Notify(text, type_) end

local function openMainMenu() end
local function openAssignSubmenu(officer) end
local function openOfficerSelect(actionLabel, onPick) end

-- ---- helpers ----------------------------------------------------------------

local function fetchOfficers()
    return lib.callback.await('qbx_policeroles:getOnlineOfficers', false) or {}
end

local function fetchRoles()
    return lib.callback.await('qbx_policeroles:getRoleDefinitions', false) or {}
end

-- ---- officer picker ---------------------------------------------------------

function openOfficerSelect(actionLabel, onPick)
    local officers = fetchOfficers()
    if #officers == 0 then
        notify('No police officers are currently online.', 'error')
        openMainMenu()
        return
    end

    local options = {}
    for _, o in ipairs(officers) do
        options[#options + 1] = {
            title       = o.name,
            description = ('ID %d · Grade %s · %d role(s)'):format(o.source, o.gradeLabel or tostring(o.grade), #(o.roles or {})),
            metadata    = #(o.roles or {}) > 0 and { ['Roles'] = table.concat(o.roles, ', ') } or nil,
            onSelect    = function() onPick(o) end,
        }
    end

    lib.registerContext({
        id        = 'qbx_policeroles_officers',
        title     = actionLabel .. ' — Select Officer',
        menu      = 'qbx_policeroles_main',
        options   = options,
    })
    lib.showContext('qbx_policeroles_officers')
end

-- ---- assign submenu ---------------------------------------------------------

function openAssignSubmenu(officer)
    local roles = fetchRoles()
    local options = {}
    local assigned = {}
    for _, r in ipairs(officer.roles or {}) do assigned[r] = true end

    for _, r in ipairs(roles) do
        local has = assigned[r.name]
        options[#options + 1] = {
            title       = r.label .. (has and '  ✓' or ''),
            description = r.description or r.name,
            disabled    = has,
            onSelect    = function()
                local ok, err = lib.callback.await('qbx_policeroles:assignRole', false, officer.source, r.name)
                if ok then
                    notify(('Assigned %s to %s'):format(r.label, officer.name), 'success')
                else
                    notify('Failed: ' .. tostring(err or 'unknown'), 'error')
                end
                openMainMenu()
            end,
        }
    end

    lib.registerContext({
        id      = 'qbx_policeroles_assign',
        title   = ('Assign role to %s'):format(officer.name),
        menu    = 'qbx_policeroles_officers',
        options = options,
    })
    lib.showContext('qbx_policeroles_assign')
end

local function openRemoveSubmenu(officer)
    if #(officer.roles or {}) == 0 then
        notify(officer.name .. ' has no roles to remove.', 'error')
        openMainMenu()
        return
    end
    local options = {}
    for _, roleName in ipairs(officer.roles) do
        options[#options + 1] = {
            title    = roleName,
            onSelect = function()
                local ok = lib.callback.await('qbx_policeroles:removeRole', false, officer.source, roleName)
                if ok then
                    notify(('Removed %s from %s'):format(roleName, officer.name), 'success')
                else
                    notify('Failed to remove role.', 'error')
                end
                openMainMenu()
            end,
        }
    end
    lib.registerContext({
        id      = 'qbx_policeroles_remove',
        title   = ('Remove role from %s'):format(officer.name),
        menu    = 'qbx_policeroles_officers',
        options = options,
    })
    lib.showContext('qbx_policeroles_remove')
end

-- ---- view all roles ---------------------------------------------------------

local function openRolesList()
    local roles = fetchRoles()
    local options = {}
    for _, r in ipairs(roles) do
        options[#options + 1] = {
            title       = r.label,
            description = r.description or r.name,
            metadata    = {
                ['Name']        = r.name,
                ['Default']     = r.is_default and 'yes' or 'no',
                ['Permissions'] = (#r.permissions > 0) and table.concat(r.permissions, ', ') or 'none',
            },
        }
    end
    lib.registerContext({
        id      = 'qbx_policeroles_list',
        title   = 'All Police Roles',
        menu    = 'qbx_policeroles_main',
        options = options,
    })
    lib.showContext('qbx_policeroles_list')
end

-- ---- create role ------------------------------------------------------------

local function openCreateRole()
    local input = lib.inputDialog('Create New Role', {
        { type = 'input', label = 'Role Name (lowercase, no spaces)', required = true, max = 50 },
        { type = 'input', label = 'Display Label', required = true, max = 100 },
        { type = 'input', label = 'Description', max = 255 },
        { type = 'checkbox', label = 'Permission: can_manage_roles' },
        { type = 'checkbox', label = 'Permission: can_assign_role' },
        { type = 'checkbox', label = 'Permission: can_remove_role' },
        { type = 'checkbox', label = 'Permission: can_create_role' },
        { type = 'checkbox', label = 'Permission: access_all (unlocks everything)' },
    })
    if not input then openMainMenu() return end

    local perms = {}
    if input[4] then perms[#perms + 1] = 'can_manage_roles' end
    if input[5] then perms[#perms + 1] = 'can_assign_role' end
    if input[6] then perms[#perms + 1] = 'can_remove_role' end
    if input[7] then perms[#perms + 1] = 'can_create_role' end
    if input[8] then perms[#perms + 1] = 'access_all' end

    local ok, err = lib.callback.await('qbx_policeroles:createRole', false, {
        name        = input[1],
        label       = input[2],
        description = input[3],
        permissions = perms,
    })
    if ok then notify('Role created.', 'success') else notify('Failed: ' .. tostring(err), 'error') end
    openMainMenu()
end

-- ---- delete role ------------------------------------------------------------

local function openDeleteRole()
    local roles = fetchRoles()
    local options = {}
    for _, r in ipairs(roles) do
        if not r.is_default then
            options[#options + 1] = {
                title       = r.label,
                description = r.name,
                onSelect    = function()
                    local confirm = lib.alertDialog({
                        header  = 'Delete role: ' .. r.label,
                        content = 'This will remove the role from ALL officers permanently. Continue?',
                        cancel  = true,
                    })
                    if confirm == 'confirm' then
                        local ok, err = lib.callback.await('qbx_policeroles:deleteRole', false, r.name)
                        if ok then notify('Role deleted.', 'success') else notify('Failed: ' .. tostring(err), 'error') end
                    end
                    openMainMenu()
                end,
            }
        end
    end
    if #options == 0 then
        notify('No custom roles to delete.', 'error')
        openMainMenu()
        return
    end
    lib.registerContext({
        id      = 'qbx_policeroles_delete',
        title   = 'Delete Custom Role',
        menu    = 'qbx_policeroles_main',
        options = options,
    })
    lib.showContext('qbx_policeroles_delete')
end

-- ---- main menu --------------------------------------------------------------

function openMainMenu()
    local options = {
        {
            title       = Client.L('menu_assign'),
            description = 'Pick an officer and grant a role',
            icon        = 'user-plus',
            onSelect    = function() openOfficerSelect(Client.L('menu_assign'), openAssignSubmenu) end,
        },
        {
            title       = Client.L('menu_remove'),
            description = 'Pick an officer and revoke a role',
            icon        = 'user-minus',
            onSelect    = function() openOfficerSelect(Client.L('menu_remove'), openRemoveSubmenu) end,
        },
        {
            title       = Client.L('menu_list'),
            description = 'View all defined police roles',
            icon        = 'list',
            onSelect    = openRolesList,
        },
    }
    if Client.data.isLeader or (Client.data.permissions and Client.data.permissions.can_create_role) then
        options[#options + 1] = {
            title       = Client.L('menu_create'),
            description = 'Define a brand-new role',
            icon        = 'plus',
            onSelect    = openCreateRole,
        }
    end
    if Client.data.isLeader then
        options[#options + 1] = {
            title       = Client.L('menu_delete'),
            description = 'Delete a custom (non-default) role',
            icon        = 'trash',
            onSelect    = openDeleteRole,
        }
    end

    lib.registerContext({
        id      = 'qbx_policeroles_main',
        title   = Client.L('menu_title'),
        options = options,
    })
    lib.showContext('qbx_policeroles_main')
end

RegisterNetEvent('qbx_policeroles:openMenu', function()
    if not Client.data.canManage then
        Client.Notify(Client.L('no_permission'), 'error')
        return
    end
    openMainMenu()
end)
