--[[ gym_system - client/items.lua
     Items are wired through ox_inventory's NATIVE client export
     (client = { export = 'gym_system.useGymItem' } in items.lua).
     This is the reliable method on all ox_inventory versions. ]]

local function playConsume(isInject)
    local ped = cache.ped
    if isInject then
        lib.requestAnimDict('anim@amb@business@weed@weed_inspecting_high_dry@', 4000)
        TaskPlayAnim(ped, 'anim@amb@business@weed@weed_inspecting_high_dry@', 'weed_inspecting_high_base_inspector', 8.0, -8.0, Config.ConsumeTime, 49, 0, false, false, false)
    else
        lib.requestAnimDict('mp_player_inteat@burger', 4000)
        TaskPlayAnim(ped, 'mp_player_inteat@burger', 'mp_player_int_eat_burger', 8.0, -8.0, Config.ConsumeTime, 49, 0, false, false, false)
    end
end

-- Single export handles ALL supplements/steroids (data.name distinguishes them).
exports('useGymItem', function(data)
    local itemName = data.name
    local cfg = Config.Items[itemName]
    if not cfg then return end
    local isInject = cfg.injectAnim == true

    playConsume(isInject)

    local ok = lib.progressBar({
        duration = Config.ConsumeTime,
        label = isInject and ('Injecting %s...'):format(cfg.label) or ('Consuming %s...'):format(cfg.label),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true },
    })

    ClearPedTasks(cache.ped)

    if not ok then
        lib.notify({ title = 'Gym', description = 'Cancelled.', type = 'inform' })
        return
    end

    -- ox_inventory verifies the player still has it and removes one (consume = 1)
    exports.ox_inventory:useItem(data, function(verified)
        if not verified then return end

        -- temporary buff (sprint / energy)
        if cfg.buff and cfg.buff.sprint and cfg.buff.duration then
            ApplySprintBuff(cfg.buff.duration)
        end

        -- steroid side effect (health drain)
        if cfg.sideEffect and cfg.sideEffect.healthDrain then
            local ped = cache.ped
            SetEntityHealth(ped, math.max(101, GetEntityHealth(ped) - cfg.sideEffect.healthDrain))
            lib.notify({ title = 'Gym', description = 'The injection takes a toll on your body...', type = 'warning' })
        end

        -- grant permanent stat XP (server authoritative)
        TriggerServerEvent('gym:server:itemUsed', itemName)
    end)
end)

-- Membership card redeem
exports('useGymCard', function(data)
    exports.ox_inventory:useItem(data, function(verified)
        if not verified then return end
        TriggerServerEvent('gym:server:cardUsed')
    end)
end)
