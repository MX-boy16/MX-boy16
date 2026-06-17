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

-- Read a bag's remaining percentage (defaults to 100 if it has no metadata yet).
local function bagPercent(slotData)
    if slotData and slotData.metadata then
        return slotData.metadata.percent or slotData.metadata.durability or Config.Mix.startPercent
    end
    return Config.Mix.startPercent
end

-- Return the supplement bags the player is carrying (for the mix menu).
-- Uses GetInventoryItems (Search is a CLIENT-only export and fails server-side).
lib.callback.register('gym:server:getMixables', function(src)
    local result = {}
    local items = exports.ox_inventory:GetInventoryItems(src) or {}
    for _, slot in pairs(items) do
        if slot and Config.Mix.bags[slot.name] then
            local item = exports.ox_inventory:Items(slot.name)
            result[#result + 1] = {
                slot = slot.slot,
                name = slot.name,
                label = (item and item.label) or slot.name,
                durability = math.floor(bagPercent(slot)),
            }
        end
    end
    return result
end)

-- Mix a bag (+ water) into a gym bottle.
RegisterNetEvent('gym:server:mixBottle', function(payload)
    local src = source
    if type(payload) ~= 'table' then return end

    local bottle = exports.ox_inventory:GetSlot(src, payload.bottleSlot)
    local bag = exports.ox_inventory:GetSlot(src, payload.bagSlot)
    if not bottle then return notify(src, 'Bottle not found, try again.', 'error') end
    if not bag then return notify(src, 'That bag is no longer in your inventory.', 'error') end

    local bcfg = Config.Mix.bottles[bottle.name]
    if not bcfg then return end
    if not Config.Mix.bags[bag.name] then
        return notify(src, 'You need a protein, pre-workout or creatine bag.', 'error')
    end
    if bottle.metadata and bottle.metadata.mixed then
        return notify(src, 'That bottle is already full. Drink it first.', 'error')
    end

    -- need enough water (GetItem with returnsCount = true; server-side safe)
    local water = exports.ox_inventory:GetItem(src, Config.Mix.waterItem, nil, true) or 0
    if water < bcfg.water then
        return notify(src, ('You need %d water for a %s.'):format(bcfg.water, bcfg.label), 'error')
    end

    -- need enough product left in the bag (nil metadata = full 100%)
    local pct = bagPercent(bag)
    if pct < bcfg.productPct then
        return notify(src, ('Bag too low (%d%%). A %s needs %d%%.'):format(math.floor(pct), bcfg.label, bcfg.productPct), 'error')
    end

    -- consume water
    exports.ox_inventory:RemoveItem(src, Config.Mix.waterItem, bcfg.water)

    -- reduce the bag; remove it when it hits 0%
    local newPct = pct - bcfg.productPct
    if newPct <= 0 then
        exports.ox_inventory:RemoveItem(src, bag.name, 1, nil, payload.bagSlot)
    else
        local meta = bag.metadata or {}
        meta.percent = newPct
        meta.durability = newPct -- keeps the visible bar in sync
        exports.ox_inventory:SetMetadata(src, payload.bagSlot, meta)
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
    notify(src, ('Mixed a %s! Bag now at %d%%.'):format(label, math.max(0, math.floor(newPct))), 'success')
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
