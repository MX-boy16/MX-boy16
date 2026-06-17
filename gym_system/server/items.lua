--[[ gym_system - server/items.lua
     Registers all supplement / steroid / card items as usable (QBX). ]]

-----------------------------------------------------------------------
-- SUPPLEMENTS & STEROIDS
-----------------------------------------------------------------------
for itemName, cfg in pairs(Config.Items) do
    exports.qbx_core:CreateUseableItem(itemName, function(source)
        local src = source
        local isInject = cfg.injectAnim == true
        -- play animation on client, which calls back to consume
        TriggerClientEvent('gym:client:useItem', src, itemName, isInject)
    end)
end

-- Client finished the animation -> apply the effect & remove the item.
RegisterNetEvent('gym:server:consumeItem', function(itemName)
    local src = source
    local cfg = Config.Items[itemName]
    if not cfg then return end

    -- verify & remove one
    local has = exports.ox_inventory:Search(src, 'count', itemName)
    if (has or 0) < 1 then return end
    if not exports.ox_inventory:RemoveItem(src, itemName, 1) then return end

    -- permanent stat growth
    if cfg.grant then
        GrantStatXp(src, cfg.grant)
    end

    -- temporary buff (sprint / energy) + side effect (steroid health drain)
    if cfg.buff or cfg.sideEffect then
        TriggerClientEvent('gym:client:itemEffect', src, cfg.buff, cfg.sideEffect)
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
exports.qbx_core:CreateUseableItem(Config.Membership.cardItem, function(source)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    if Config.Membership.cardGrantsLifetime then
        player.Functions.SetMetaData('gymmembership', { active = true, expires = 0, lifetime = true })
        exports.ox_inventory:RemoveItem(src, Config.Membership.cardItem, 1)
        TriggerClientEvent('ox_lib:notify', src, { title = 'Gym', description = 'LIFETIME membership activated!', type = 'success' })
    else
        local expires = os.time() + (Config.Membership.durationDays * 86400)
        player.Functions.SetMetaData('gymmembership', { active = true, expires = expires, lifetime = false })
        exports.ox_inventory:RemoveItem(src, Config.Membership.cardItem, 1)
        TriggerClientEvent('ox_lib:notify', src, { title = 'Gym', description = ('%d-day membership activated!'):format(Config.Membership.durationDays), type = 'success' })
    end
end)
