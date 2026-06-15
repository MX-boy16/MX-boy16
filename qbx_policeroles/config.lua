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
