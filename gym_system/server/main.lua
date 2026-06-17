--[[ gym_system - server/main.lua
     Authoritative stats, XP, membership & money handling for QBX. ]]

local STAT_KEY = 'gymstats'
local MEMBER_KEY = 'gymmembership'

-- Active training-boost timers (from drinking a mixed shake), keyed by source.
local BoostUntil = {}

function ActivateGymBoost(src, duration)
    BoostUntil[src] = os.time() + duration
end

-----------------------------------------------------------------------
-- HELPERS
-----------------------------------------------------------------------
local function xpNeeded(level)
    return Config.Progress.baseXp + (level * Config.Progress.levelStep)
end

local function defaultStats()
    return {
        strength = { level = 0, xp = 0 },
        stamina  = { level = 0, xp = 0 },
        punch    = { level = 0, xp = 0 },
        muscle   = { level = 0, xp = 0 },
    }
end

local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

local function getStats(player)
    local data = player.PlayerData.metadata[STAT_KEY]
    if type(data) ~= 'table' then data = defaultStats() end
    -- backfill any missing stat
    for _, s in ipairs({ 'strength', 'stamina', 'punch', 'muscle' }) do
        if type(data[s]) ~= 'table' then data[s] = { level = 0, xp = 0 } end
    end
    return data
end

-- Build the flat table the client expects.
local function buildSync(data)
    return {
        strength = data.strength.level,
        stamina  = data.stamina.level,
        punch    = data.punch.level,
        muscle   = data.muscle.level,
        xp = {
            strength = data.strength.xp,
            stamina  = data.stamina.xp,
            punch    = data.punch.xp,
            muscle   = data.muscle.xp,
        }
    }
end

local function addXp(data, stat, amount)
    local s = data[stat]
    if not s then return false end
    if s.level >= Config.MaxLevel then return false end
    s.xp = s.xp + amount
    local leveled = false
    while s.level < Config.MaxLevel and s.xp >= xpNeeded(s.level) do
        s.xp = s.xp - xpNeeded(s.level)
        s.level = s.level + 1
        leveled = true
    end
    if s.level >= Config.MaxLevel then s.xp = 0 end
    return leveled
end

local function saveAndSync(src, player, data)
    player.Functions.SetMetaData(STAT_KEY, data)
    TriggerClientEvent('gym:client:syncStats', src, buildSync(data))
end

-- exposed so item handler can grant XP too
function GrantStatXp(src, grantTable)
    local player = getPlayer(src)
    if not player then return end
    local data = getStats(player)
    local leveledAny = false
    for stat, amount in pairs(grantTable) do
        if addXp(data, stat, amount) then leveledAny = true end
    end
    saveAndSync(src, player, data)
    return leveledAny
end

-----------------------------------------------------------------------
-- MEMBERSHIP
-----------------------------------------------------------------------
local function getMembership(player)
    local m = player.PlayerData.metadata[MEMBER_KEY]
    if type(m) ~= 'table' then m = { active = false, expires = 0, lifetime = false } end
    return m
end

local function hasCard(src)
    -- GetItem with returnsCount = true (Search is client-only and fails server-side)
    local count = exports.ox_inventory:GetItem(src, Config.Membership.cardItem, nil, true)
    return (count or 0) > 0
end

function PlayerHasAccess(src)
    local player = getPlayer(src)
    if not player then return false end
    local m = getMembership(player)
    if m.lifetime then return true end
    if m.active and m.expires > os.time() then return true end
    if Config.Membership.ownershipGrantsAccess and hasCard(src) then return true end
    return false
end

-----------------------------------------------------------------------
-- EVENTS
-----------------------------------------------------------------------
RegisterNetEvent('gym:server:requestStats', function()
    local src = source
    local player = getPlayer(src)
    if not player then return end
    TriggerClientEvent('gym:client:syncStats', src, buildSync(getStats(player)))
end)

RegisterNetEvent('gym:server:gainXp', function(statType, amount)
    local src = source
    local valid = { stamina = true, strength = true, punch = true, muscle = true }
    if not valid[statType] then return end
    amount = math.min(tonumber(amount) or 0, 50) -- clamp to stop abuse
    if amount <= 0 then return end
    if not PlayerHasAccess(src) then return end
    -- shake boost doubles XP gains while active
    if BoostUntil[src] and os.time() < BoostUntil[src] then
        amount = math.floor(amount * Config.Mix.boostMultiplier)
    end
    local leveled = GrantStatXp(src, { [statType] = amount })
    if leveled then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Gym', description = ('Your %s went up!'):format(statType), type = 'success' })
    end
end)

-----------------------------------------------------------------------
-- CALLBACKS
-----------------------------------------------------------------------
lib.callback.register('gym:server:hasAccess', function(src)
    return PlayerHasAccess(src)
end)

lib.callback.register('gym:server:membershipStatus', function(src)
    local player = getPlayer(src)
    if not player then return { active = false } end
    local m = getMembership(player)
    local lifetime = m.lifetime or (Config.Membership.ownershipGrantsAccess and hasCard(src) and Config.Membership.cardGrantsLifetime)
    local active = m.active and m.expires > os.time()
    local daysLeft = active and math.max(0, math.ceil((m.expires - os.time()) / 86400)) or 0
    return { active = active or lifetime, lifetime = lifetime, daysLeft = daysLeft }
end)

lib.callback.register('gym:server:buyMembership', function(src)
    local player = getPlayer(src)
    if not player then return false end
    if (player.PlayerData.money[Config.Account] or 0) < Config.Membership.price then return 'broke' end
    if not player.Functions.RemoveMoney(Config.Account, Config.Membership.price, 'gym-membership') then return 'broke' end
    local expires = os.time() + (Config.Membership.durationDays * 86400)
    player.Functions.SetMetaData(MEMBER_KEY, { active = true, expires = expires, lifetime = false })
    return true
end)

lib.callback.register('gym:server:buyCard', function(src)
    local player = getPlayer(src)
    if not player then return false end
    if (player.PlayerData.money[Config.Account] or 0) < Config.Membership.cardPrice then return 'broke' end
    if not exports.ox_inventory:CanCarryItem(src, Config.Membership.cardItem, 1) then return 'full' end
    if not player.Functions.RemoveMoney(Config.Account, Config.Membership.cardPrice, 'gym-card') then return 'broke' end
    exports.ox_inventory:AddItem(src, Config.Membership.cardItem, 1)
    return true
end)

-----------------------------------------------------------------------
-- FRONT DESK SHOP (bags / bottles / steroids)
-----------------------------------------------------------------------
lib.callback.register('gym:server:buyShopItem', function(src, itemName)
    local player = getPlayer(src)
    if not player then return false end

    local entry
    for _, e in ipairs(Config.Shop) do
        if e.item == itemName then entry = e break end
    end
    if not entry then return false end

    if (player.PlayerData.money[Config.Account] or 0) < entry.price then return 'broke' end
    if not exports.ox_inventory:CanCarryItem(src, entry.item, 1) then return 'full' end
    if not player.Functions.RemoveMoney(Config.Account, entry.price, 'gym-shop') then return 'broke' end

    -- bags spawn full (100%) using durability metadata for the visible bar
    local meta = entry.bag and { durability = Config.Mix.startPercent } or nil
    exports.ox_inventory:AddItem(src, entry.item, 1, meta)
    return true
end)
