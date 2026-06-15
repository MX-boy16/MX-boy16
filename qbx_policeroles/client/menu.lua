-- ox_lib menu used by the Chief / managers (/policeadmin).

local function notify(text, type_) Client.Notify(text, type_) end

local function openMainMenu() end
local function openAssignSubmenu(officer) end
local function openOfficerSelect(actionLabel, onPick) end

-- ---- police-themed visuals -------------------------------------------------
-- Each role has its own FontAwesome icon + accent color so the menu reads
-- like a real precinct roster instead of a generic list.

local ROLE_VISUALS = {
    chief      = { icon = 'star',             color = '#FFD700', tag = 'COMMAND'    },
    captain    = { icon = 'shield-halved',    color = '#E5E7EB', tag = 'COMMAND'    },
    lieutenant = { icon = 'bars-staggered',   color = '#CBD5E1', tag = 'SUPERVISOR' },
    sergeant   = { icon = 'medal',            color = '#94A3B8', tag = 'SUPERVISOR' },
    officer    = { icon = 'user-shield',      color = '#3B82F6', tag = 'PATROL'     },
    cadet      = { icon = 'graduation-cap',   color = '#60A5FA', tag = 'TRAINEE'    },
    swat       = { icon = 'helmet-safety',    color = '#DC2626', tag = 'TACTICAL'   },
    k9         = { icon = 'dog',              color = '#B45309', tag = 'K-9 UNIT'   },
    detective  = { icon = 'magnifying-glass', color = '#A855F7', tag = 'INVESTIG.'  },
    traffic    = { icon = 'traffic-light',    color = '#F59E0B', tag = 'TRAFFIC'    },
}

local DEFAULT_ROLE_VIS = { icon = 'id-badge', color = '#64748B', tag = 'UNIT' }

local function roleVis(name)
    return ROLE_VISUALS[name] or DEFAULT_ROLE_VIS
end

-- Color an officer card by their highest-ranking role (or default blue).
local TIER_ORDER = { 'chief', 'captain', 'lieutenant', 'sergeant', 'swat', 'detective', 'k9', 'traffic', 'officer', 'cadet' }
local function officerVis(o)
    for _, t in ipairs(TIER_ORDER) do
        for _, r in ipairs(o.roles or {}) do
            if r == t then return roleVis(t) end
        end
    end
    return { icon = 'user-police', color = '#3B82F6', tag = 'OFFICER' }
end

-- Build the badge-style metadata block shown on every option.
local function officerMetadata(o)
    local md = {
        { label = 'Badge #',  value = ('#%04d'):format(o.source) },
        { label = 'Rank',     value = o.gradeLabel ~= '' and o.gradeLabel or ('Grade ' .. tostring(o.grade)) },
        { label = 'Division', value = (officerVis(o).tag) },
    }
    if #(o.roles or {}) > 0 then
        md[#md + 1] = { label = 'Assignments', value = table.concat(o.roles, ', ') }
    else
        md[#md + 1] = { label = 'Assignments', value = '—' }
    end
    return md
end

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
        local vis = officerVis(o)
        options[#options + 1] = {
            title       = ('[%s]  %s'):format(vis.tag, o.name),
            description = ('Badge #%04d  •  %s  •  %d assignment(s)'):format(
                o.source,
                o.gradeLabel ~= '' and o.gradeLabel or ('Grade ' .. tostring(o.grade)),
                #(o.roles or {})
            ),
            icon        = vis.icon,
            iconColor   = vis.color,
            metadata    = officerMetadata(o),
            arrow       = true,
            onSelect    = function() onPick(o) end,
        }
    end

    lib.registerContext({
        id        = 'qbx_policeroles_officers',
        title     = '🛡  OFFICER ROSTER  •  ' .. actionLabel:upper(),
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
        local vis = roleVis(r.name)
        options[#options + 1] = {
            title       = ('%s  %s%s'):format(vis.tag, r.label, has and '   ✓ ACTIVE' or ''),
            description = r.description or r.name,
            icon        = vis.icon,
            iconColor   = has and '#10B981' or vis.color,
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
        title   = '➤  ASSIGN DIVISION  •  ' .. officer.name:upper(),
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
        local vis = roleVis(roleName)
        options[#options + 1] = {
            title       = ('%s  %s'):format(vis.tag, roleName),
            description = 'Revoke this assignment',
            icon        = 'circle-minus',
            iconColor   = '#EF4444',
            onSelect    = function()
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
        title   = '✖  REVOKE DIVISION  •  ' .. officer.name:upper(),
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
        local vis = roleVis(r.name)
        options[#options + 1] = {
            title       = ('[%s]  %s'):format(vis.tag, r.label),
            description = r.description or r.name,
            icon        = vis.icon,
            iconColor   = vis.color,
            metadata    = {
                { label = 'Codename',    value = r.name },
                { label = 'Default',     value = r.is_default and 'system role' or 'custom role' },
                { label = 'Permissions', value = (#r.permissions > 0) and table.concat(r.permissions, ', ') or 'none' },
            },
        }
    end
    lib.registerContext({
        id      = 'qbx_policeroles_list',
        title   = '📋  PRECINCT ROLE INDEX',
        menu    = 'qbx_policeroles_main',
        options = options,
    })
    lib.showContext('qbx_policeroles_list')
end

-- ---- create role ------------------------------------------------------------

local function openCreateRole()
    local input = lib.inputDialog('🏛  CHARTER A NEW DIVISION', {
        { type = 'input', label = 'Codename (lowercase, no spaces)', required = true, max = 50, icon = 'hashtag' },
        { type = 'input', label = 'Display Label',                   required = true, max = 100, icon = 'tag' },
        { type = 'input', label = 'Description',                     max = 255, icon = 'align-left' },
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
            local vis = roleVis(r.name)
            options[#options + 1] = {
                title       = ('[%s]  %s'):format(vis.tag, r.label),
                description = 'Codename: ' .. r.name,
                icon        = 'trash-can',
                iconColor   = '#EF4444',
                onSelect    = function()
                    local confirm = lib.alertDialog({
                        header  = '⚠  DISBAND DIVISION: ' .. r.label,
                        content = 'This permanently removes the role and **unassigns it from every officer**.\n\nProceed?',
                        cancel  = true,
                        labels  = { confirm = 'Disband', cancel = 'Stand Down' },
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
        title   = '🗑  DISBAND CUSTOM DIVISION',
        menu    = 'qbx_policeroles_main',
        options = options,
    })
    lib.showContext('qbx_policeroles_delete')
end

-- ---- main menu --------------------------------------------------------------

function openMainMenu()
    local d = Client.data
    local rank      = d.isLeader and 'CHIEF OF POLICE' or (d.canManage and 'COMMAND STAFF' or 'OFFICER')
    local statusTxt = d.onDuty and 'ON DUTY' or 'OFF DUTY'
    local statusCol = d.onDuty and '#10B981' or '#9CA3AF'
    local clearance = d.isLeader and 'Tier 5 — Unrestricted' or
                      (d.permissions and d.permissions.access_all and 'Tier 5 — Master Key') or
                      (d.canManage and 'Tier 3 — Role Management') or
                      'Tier 1 — Standard'

    local options = {
        {
            title       = '— PRECINCT HEADER —',
            description = ('Logged in as %s'):format(rank),
            icon        = 'shield-halved',
            iconColor   = '#FFD700',
            readOnly    = true,
            metadata    = {
                { label = 'Status',         value = statusTxt },
                { label = 'Clearance',      value = clearance },
                { label = 'Active Roles',   value = (#(d.roles or {}) > 0) and table.concat(d.roles, ', ') or '—' },
            },
        },
        {
            title       = '▸  ASSIGN DIVISION',
            description = 'Promote an officer into a specialized unit',
            icon        = 'user-plus',
            iconColor   = '#10B981',
            iconAnimation = 'fade',
            arrow       = true,
            onSelect    = function() openOfficerSelect('Assign', openAssignSubmenu) end,
        },
        {
            title       = '▸  REVOKE DIVISION',
            description = 'Strip an officer of a current assignment',
            icon        = 'user-minus',
            iconColor   = '#EF4444',
            arrow       = true,
            onSelect    = function() openOfficerSelect('Revoke', openRemoveSubmenu) end,
        },
        {
            title       = '▸  ROLE INDEX',
            description = 'Browse every division on the precinct charter',
            icon        = 'book-bookmark',
            iconColor   = '#3B82F6',
            arrow       = true,
            onSelect    = openRolesList,
        },
    }
    if d.isLeader or (d.permissions and d.permissions.can_create_role) then
        options[#options + 1] = {
            title       = '✚  CHARTER NEW DIVISION',
            description = 'Define a brand-new role with its own permissions',
            icon        = 'plus',
            iconColor   = '#FACC15',
            arrow       = true,
            onSelect    = openCreateRole,
        }
    end
    if d.isLeader then
        options[#options + 1] = {
            title       = '✖  DISBAND DIVISION',
            description = 'Permanently delete a custom (non-default) role',
            icon        = 'trash-can',
            iconColor   = '#EF4444',
            arrow       = true,
            onSelect    = openDeleteRole,
        }
    end

    lib.registerContext({
        id    = 'qbx_policeroles_main',
        title = '★  POLICE COMMAND  ★',
        options = options,
    })
    lib.showContext('qbx_policeroles_main')
    -- ignore unused statusCol warning (reserved for future header tinting)
    _ = statusCol
end

RegisterNetEvent('qbx_policeroles:openMenu', function()
    if not Client.data.canManage then
        Client.Notify(Client.L('no_permission'), 'error')
        return
    end
    openMainMenu()
end)
