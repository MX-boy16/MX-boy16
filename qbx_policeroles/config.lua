Config = {}

-- Job name in qbx_core that this script gates against
Config.PoliceJob = 'police'

-- Minimum qbx job grade considered "leader" (can ALWAYS manage roles, regardless of perms).
-- Set to the grade level you use for Chief / Sheriff in qbx_core/shared/jobs.lua
Config.LeaderGrade = 4

-- Allow a player who has the 'can_manage_roles' permission (granted through a role)
-- to also manage roles even if not Chief grade.
Config.AllowDelegatedManagement = true

-- Notify provider: 'ox' (ox_lib) or 'qbx'
Config.Notify = 'ox'

-- Auto-create the SQL tables on resource start if missing.
Config.AutoInstallSQL = true

-- Refresh interval (ms) for client role cache. 0 = never auto refresh, only on event push.
Config.RoleRefreshInterval = 0

-- ============================================================
--  ROLE-GATED DOORS
--  Each door must already be registered in ox_doorlock (with its own doorId).
--  This script only OVERRIDES the unlock check, so the door's
--  built-in groups/items still apply normally for non-role flow.
--
--  required = { 'role_a', 'role_b' }  -> any one of these roles unlocks
--  doorId can be the numeric ID or the door's "name" set in ox_doorlock.
-- ============================================================
Config.Doors = {
    {
        doorId   = 'mrpd_armory',
        label    = 'Armory Door',
        required = { 'officer', 'swat', 'chief' },
    },
    {
        doorId   = 'mrpd_swat_bay',
        label    = 'SWAT Bay',
        required = { 'swat', 'chief' },
    },
    {
        doorId   = 'mrpd_evidence',
        label    = 'Evidence Locker',
        required = { 'detective', 'chief' },
    },
    {
        doorId   = 'mrpd_k9',
        label    = 'K9 Kennels',
        required = { 'k9', 'chief' },
    },
    {
        doorId   = 'mrpd_chief_office',
        label    = 'Chief Office',
        required = { 'chief' },
    },
}

-- ============================================================
--  ROLE-GATED STASHES (ox_inventory)
--  Stashes are registered server-side. Access is checked against police_roles.
-- ============================================================
Config.Stashes = {
    {
        id       = 'police_armory_patrol',
        label    = 'Patrol Armory',
        slots    = 50,
        weight   = 100000,
        required = { 'officer', 'swat', 'chief' },
        coords   = vec3(461.49, -985.32, 30.73),
    },
    {
        id       = 'police_armory_swat',
        label    = 'SWAT Armory',
        slots    = 80,
        weight   = 200000,
        required = { 'swat', 'chief' },
        coords   = vec3(464.20, -985.32, 30.73),
    },
    {
        id       = 'police_evidence',
        label    = 'Evidence Locker',
        slots    = 100,
        weight   = 500000,
        required = { 'detective', 'chief' },
        coords   = vec3(474.94, -1017.46, 26.36),
    },
    {
        id       = 'police_k9_gear',
        label    = 'K9 Gear',
        slots    = 30,
        weight   = 50000,
        required = { 'k9', 'chief' },
        coords   = vec3(457.10, -994.81, 30.69),
    },
}

-- ============================================================
--  DEFAULT ROLES (config side, also seeded into DB on first start)
--  permissions are arbitrary string flags; checked server-side via HasPermission().
-- ============================================================
Config.DefaultRoles = {
    {
        name        = 'chief',
        label       = 'Chief of Police',
        description = 'Department leader. Full control over roles.',
        permissions = { 'can_manage_roles', 'can_create_role', 'can_assign_role', 'can_remove_role', 'access_all' },
    },
    {
        name        = 'captain',
        label       = 'Captain',
        description = 'Senior command. Can assign / remove existing roles.',
        permissions = { 'can_assign_role', 'can_remove_role' },
    },
    {
        name        = 'lieutenant',
        label       = 'Lieutenant',
        description = 'Mid-command supervisor.',
        permissions = { 'can_assign_role' },
    },
    {
        name        = 'sergeant',
        label       = 'Sergeant',
        description = 'Patrol supervisor.',
        permissions = {},
    },
    {
        name        = 'officer',
        label       = 'Patrol Officer',
        description = 'Standard patrol access (armory, patrol cars).',
        permissions = {},
    },
    {
        name        = 'cadet',
        label       = 'Cadet',
        description = 'Probationary officer. Limited access.',
        permissions = {},
    },
    {
        name        = 'swat',
        label       = 'SWAT',
        description = 'Tactical unit. SWAT bay and heavy armory access.',
        permissions = {},
    },
    {
        name        = 'k9',
        label       = 'K9 Handler',
        description = 'K9 unit. Kennel access.',
        permissions = {},
    },
    {
        name        = 'detective',
        label       = 'Detective',
        description = 'Investigations. Evidence locker access.',
        permissions = {},
    },
    {
        name        = 'traffic',
        label       = 'Traffic Division',
        description = 'Traffic enforcement specialist.',
        permissions = {},
    },
}

-- Management menu command
Config.ManageCommand     = 'policeadmin'
-- Player self-view command
Config.MyRolesCommand    = 'myroles'
-- Duty toggle command
Config.DutyCommand       = 'duty'

-- ============================================================
--  MDT (Mobile Data Terminal)
-- ============================================================
Config.MDT = {
    Command        = 'mdt',
    -- Restrict who can ISSUE / REVOKE weapon licenses through the MDT.
    -- Empty table = any police officer on duty. Otherwise list role codenames.
    -- Chief always bypasses this (leader grade).
    LicenseIssuers = {},  -- e.g. { 'chief', 'captain', 'lieutenant', 'detective' }
    MaxResults     = 25,
}

-- ============================================================
--  WEAPON LICENSE CLASSES
--  Class 1: Pistols
--  Class 2: SMGs
--  Class 3: Long arms / heavy (rifles, shotguns, snipers, MGs, launchers)
-- ============================================================
Config.LicenseClasses = {
    [1] = { label = 'Class 1 — Sidearm',           description = 'Pistols & revolvers' },
    [2] = { label = 'Class 2 — Sub-machine',       description = 'SMGs & machine pistols' },
    [3] = { label = 'Class 3 — Long Arms / Heavy', description = 'Rifles, shotguns, heavy weapons' },
}

-- Map ox_inventory item names → required class.
-- Items not listed here are NOT gated by this script.
Config.WeaponClasses = {
    -- Class 1 — pistols
    ['WEAPON_PISTOL']          = 1, ['WEAPON_PISTOL_MK2']     = 1,
    ['WEAPON_COMBATPISTOL']    = 1, ['WEAPON_PISTOL50']       = 1,
    ['WEAPON_SNSPISTOL']       = 1, ['WEAPON_SNSPISTOL_MK2']  = 1,
    ['WEAPON_HEAVYPISTOL']     = 1, ['WEAPON_VINTAGEPISTOL']  = 1,
    ['WEAPON_REVOLVER']        = 1, ['WEAPON_REVOLVER_MK2']   = 1,
    ['WEAPON_DOUBLEACTION']    = 1, ['WEAPON_APPISTOL']       = 1,
    ['WEAPON_CERAMICPISTOL']   = 1, ['WEAPON_NAVYREVOLVER']   = 1,
    ['WEAPON_GADGETPISTOL']    = 1, ['WEAPON_STUNGUN']        = 1,

    -- Class 2 — SMGs / machine pistols
    ['WEAPON_MICROSMG']        = 2, ['WEAPON_SMG']            = 2,
    ['WEAPON_SMG_MK2']         = 2, ['WEAPON_ASSAULTSMG']     = 2,
    ['WEAPON_COMBATPDW']       = 2, ['WEAPON_MACHINEPISTOL']  = 2,
    ['WEAPON_MINISMG']         = 2,

    -- Class 3 — long arms / heavy
    ['WEAPON_ASSAULTRIFLE']      = 3, ['WEAPON_ASSAULTRIFLE_MK2']  = 3,
    ['WEAPON_CARBINERIFLE']      = 3, ['WEAPON_CARBINERIFLE_MK2']  = 3,
    ['WEAPON_ADVANCEDRIFLE']     = 3, ['WEAPON_SPECIALCARBINE']    = 3,
    ['WEAPON_SPECIALCARBINE_MK2']= 3, ['WEAPON_BULLPUPRIFLE']      = 3,
    ['WEAPON_BULLPUPRIFLE_MK2']  = 3, ['WEAPON_COMPACTRIFLE']      = 3,
    ['WEAPON_MILITARYRIFLE']     = 3, ['WEAPON_HEAVYRIFLE']        = 3,
    ['WEAPON_PUMPSHOTGUN']       = 3, ['WEAPON_PUMPSHOTGUN_MK2']   = 3,
    ['WEAPON_SAWNOFFSHOTGUN']    = 3, ['WEAPON_ASSAULTSHOTGUN']    = 3,
    ['WEAPON_BULLPUPSHOTGUN']    = 3, ['WEAPON_HEAVYSHOTGUN']      = 3,
    ['WEAPON_DBSHOTGUN']         = 3, ['WEAPON_AUTOSHOTGUN']       = 3,
    ['WEAPON_COMBATSHOTGUN']     = 3, ['WEAPON_SNIPERRIFLE']       = 3,
    ['WEAPON_HEAVYSNIPER']       = 3, ['WEAPON_HEAVYSNIPER_MK2']   = 3,
    ['WEAPON_MARKSMANRIFLE']     = 3, ['WEAPON_MARKSMANRIFLE_MK2'] = 3,
    ['WEAPON_MG']                = 3, ['WEAPON_COMBATMG']          = 3,
    ['WEAPON_COMBATMG_MK2']      = 3, ['WEAPON_GUSENBERG']         = 3,
    ['WEAPON_RPG']               = 3, ['WEAPON_GRENADELAUNCHER']   = 3,
    ['WEAPON_MINIGUN']           = 3, ['WEAPON_RAILGUN']           = 3,
    ['WEAPON_FIREWORK']          = 3, ['WEAPON_HOMINGLAUNCHER']    = 3,
    ['WEAPON_COMPACTLAUNCHER']   = 3, ['WEAPON_RAYPISTOL']         = 3,
    ['WEAPON_RAYCARBINE']        = 3, ['WEAPON_RAYMINIGUN']        = 3,

    -- Ammo (also gated when GateAmmo = true)
    ['ammo-9']        = 1, ['ammo-45']      = 1,
    ['ammo-smg']      = 2,
    ['ammo-rifle']    = 3, ['ammo-rifle2']  = 3,
    ['ammo-shotgun']  = 3, ['ammo-sniper']  = 3,  ['ammo-mg'] = 3,
}

-- If true, the ammunation hook also blocks ammo without the right license.
Config.GateAmmo = true
