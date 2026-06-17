--[[ gym_system - client/items.lua
     Plays the eat / inject animation when a supplement is used.
     Triggered from the server item handler. ]]

local function playConsume(isInject)
    local ped = cache.ped
    local dict = isInject and 'amb@world_human_drug_dealer@male@base' or 'mp_player_inteat@burger'
    local clip = isInject and 'base' or 'mp_player_int_eat_burger'

    if isInject then
        -- inject into the arm
        lib.requestAnimDict('anim@amb@business@weed@weed_inspecting_high_dry@', 4000)
        TaskPlayAnim(ped, 'anim@amb@business@weed@weed_inspecting_high_dry@', 'weed_inspecting_high_base_inspector', 8.0, -8.0, Config.ConsumeTime, 49, 0, false, false, false)
    else
        lib.requestAnimDict(dict, 4000)
        TaskPlayAnim(ped, dict, clip, 8.0, -8.0, Config.ConsumeTime, 49, 0, false, false, false)
    end
end

RegisterNetEvent('gym:client:useItem', function(itemName, isInject)
    local cfg = Config.Items[itemName]
    if not cfg then return end

    playConsume(isInject)

    local ok = lib.progressBar({
        duration = Config.ConsumeTime,
        label = isInject and ('Injecting %s...'):format(cfg.label) or ('Consuming %s...'):format(cfg.label),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true },
    })

    ClearPedTasks(cache.ped)

    if ok then
        TriggerServerEvent('gym:server:consumeItem', itemName)
    else
        lib.notify({ title = 'Gym', description = 'Cancelled.', type = 'inform' })
    end
end)

-- server confirms the effect + applies temp buff client-side
RegisterNetEvent('gym:client:itemEffect', function(buff, sideEffect)
    if buff and buff.sprint and buff.duration then
        ApplySprintBuff(buff.duration)
    end
    if sideEffect and sideEffect.healthDrain then
        local ped = cache.ped
        local hp = GetEntityHealth(ped)
        SetEntityHealth(ped, math.max(101, hp - sideEffect.healthDrain))
        lib.notify({ title = 'Gym', description = 'The injection takes a toll on your body...', type = 'warning' })
    end
end)
