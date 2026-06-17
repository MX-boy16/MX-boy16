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
