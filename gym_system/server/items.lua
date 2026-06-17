--[[ gym_system - server/items.lua
     Item effects. Items are triggered via ox_inventory's native client
     export (see client/items.lua + install/items.lua). ox_inventory
     consumes the item itself (consume = 1); the server only grants XP /
     activates membership. ]]

-----------------------------------------------------------------------
-- SUPPLEMENTS & STEROIDS -> permanent stat growth
-----------------------------------------------------------------------
RegisterNetEvent('gym:server:itemUsed', function(itemName)
    local src = source
    local cfg = Config.Items[itemName]
    if not cfg then return end

    if cfg.grant then
        GrantStatXp(src, cfg.grant)
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Gym',
        description = ('Used %s — gains applied!'):format(cfg.label),
        type = 'success'
    })
end)

-----------------------------------------------------------------------
-- MEMBERSHIP CARD (redeemable)
-----------------------------------------------------------------------
RegisterNetEvent('gym:server:cardUsed', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    if Config.Membership.cardGrantsLifetime then
        player.Functions.SetMetaData('gymmembership', { active = true, expires = 0, lifetime = true })
        TriggerClientEvent('ox_lib:notify', src, { title = 'Gym', description = 'LIFETIME membership activated!', type = 'success' })
    else
        local expires = os.time() + (Config.Membership.durationDays * 86400)
        player.Functions.SetMetaData('gymmembership', { active = true, expires = expires, lifetime = false })
        TriggerClientEvent('ox_lib:notify', src, { title = 'Gym', description = ('%d-day membership activated!'):format(Config.Membership.durationDays), type = 'success' })
    end
end)

-----------------------------------------------------------------------
-- MIXING SYSTEM
-----------------------------------------------------------------------
local function notify(src, desc, type)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Gym', description = desc, type = type or 'inform' })
end

-- Return the supplement bags the player is carrying (for the mix menu).
lib.callback.register('gym:server:getMixables', function(src)
    local names = {}
    for name in pairs(Config.Mix.bags) do names[#names + 1] = name end
    local slots = exports.ox_inventory:Search(src, 'slots', names) or {}
    local result = {}
    for _, s in ipairs(slots) do
        local dur = (s.metadata and s.metadata.durability) or Config.Mix.startPercent
        local item = exports.ox_inventory:Items(s.name)
        result[#result + 1] = {
            slot = s.slot,
            name = s.name,
            label = (item and item.label) or s.name,
            durability = math.floor(dur),
        }
    end
    return result
end)

-- Mix a bag (+ water) into a gym bottle.
RegisterNetEvent('gym:server:mixBottle', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end

    local bottle = exports.ox_inventory:GetSlot(src, payload.bottleSlot)
    local bag = exports.ox_inventory:GetSlot(src, payload.bagSlot)
    if not bottle or not bag then return end

    local bcfg = Config.Mix.bottles[bottle.name]
    if not bcfg then return end
    if not Config.Mix.bags[bag.name] then return end
    if bottle.metadata and bottle.metadata.mixed then
        return notify(src, 'That bottle is already full. Drink it first.', 'error')
    end

    -- need enough water
    local water = exports.ox_inventory:Search(src, 'count', Config.Mix.waterItem) or 0
    if water < bcfg.water then
        return notify(src, ('You need %d water for a %s.'):format(bcfg.water, bcfg.label), 'error')
    end

    -- need enough product left in the bag
    local dur = (bag.metadata and bag.metadata.durability) or Config.Mix.startPercent
    if dur < bcfg.productPct then
        return notify(src, 'Not enough supplement left in that bag.', 'error')
    end

    -- consume water + bag percentage
    exports.ox_inventory:RemoveItem(src, Config.Mix.waterItem, bcfg.water)
    local newDur = dur - bcfg.productPct
    if newDur <= 0 then
        exports.ox_inventory:RemoveItem(src, bag.name, 1, nil, payload.bagSlot)
    else
        exports.ox_inventory:SetDurability(src, payload.bagSlot, newDur)
    end

    -- fill the bottle
    local item = exports.ox_inventory:Items(bag.name)
    local label = ('Shake (%s)'):format((item and item.label) or bag.name)
    exports.ox_inventory:SetMetadata(src, payload.bottleSlot, {
        mixed = true,
        bag = bag.name,
        label = label,
        description = 'A freshly mixed gym shake. Drink for a 2-minute training boost.',
    })
    notify(src, ('Mixed a %s! Drink it to get a boost.'):format(label), 'success')
end)

-- Drink a mixed bottle -> 2-minute training boost, bottle empties (reusable).
RegisterNetEvent('gym:server:drinkBottle', function(bottleSlot)
    local src = source
    local bottle = exports.ox_inventory:GetSlot(src, bottleSlot)
    if not bottle or not bottle.metadata or not bottle.metadata.mixed then return end

    -- empty the bottle (keeps it, resets to default label)
    exports.ox_inventory:SetMetadata(src, bottleSlot, {})

    ActivateGymBoost(src, Config.Mix.boostDuration)
    TriggerClientEvent('gym:client:boost', src, Config.Mix.boostDuration)
    notify(src, ('Training boost active for %d min! XP x%s while you work out.'):format(math.floor(Config.Mix.boostDuration / 60), Config.Mix.boostMultiplier), 'success')
end)
