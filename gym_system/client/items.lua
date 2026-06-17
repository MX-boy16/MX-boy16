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

    -- Bags can't be used directly anymore - they must be mixed in a bottle.
    if Config.Mix.bags[itemName] then
        lib.notify({ title = 'Gym', description = 'Pour this into a Gym Bottle (with water) to mix a shake.', type = 'inform' })
        return
    end

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

-----------------------------------------------------------------------
-- GYM BOTTLE: mix (empty) or drink (mixed)
-----------------------------------------------------------------------
local function drinkBottle(slot)
    local ped = cache.ped
    lib.requestAnimDict('mp_player_intdrink', 3000)
    TaskPlayAnim(ped, 'mp_player_intdrink', 'loop_bottle', 8.0, -8.0, 4000, 49, 0, false, false, false)
    local ok = lib.progressBar({
        duration = 4000,
        label = 'Drinking shake...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true },
    })
    ClearPedTasks(ped)
    if not ok then return end
    TriggerServerEvent('gym:server:drinkBottle', slot)
end

local function openMixMenu(data, slot)
    local bottle = Config.Mix.bottles[data.name]
    if not bottle then return end

    local mixables = lib.callback.await('gym:server:getMixables', false)
    local options = {}

    if not mixables or #mixables == 0 then
        options[#options + 1] = {
            title = 'No supplement bags',
            description = 'Buy a protein, pre-workout or creatine bag at the front desk.',
            icon = 'fa-solid fa-ban',
            readOnly = true,
        }
    else
        for _, m in ipairs(mixables) do
            local enough = m.durability >= bottle.productPct
            options[#options + 1] = {
                title = m.label,
                description = ('%d%% left • needs %d water + %d%% powder'):format(m.durability, bottle.water, bottle.productPct),
                icon = 'fa-solid fa-blender',
                disabled = not enough,
                progress = m.durability,
                onSelect = function()
                    TriggerServerEvent('gym:server:mixBottle', { bottleSlot = slot, bagSlot = m.slot })
                end,
            }
        end
    end

    lib.registerContext({
        id = 'gym_mix_menu',
        title = ('Mix — %s (water: %d, powder: %d%%)'):format(bottle.label, bottle.water, bottle.productPct),
        options = options,
    })
    lib.showContext('gym_mix_menu')
end

exports('useGymBottle', function(data, slot)
    local theSlot = data.slot or slot
    local meta = data.metadata or {}
    if meta.mixed then
        drinkBottle(theSlot)
    else
        openMixMenu(data, theSlot)
    end
end)

-- Drink boost feedback (XP x multiplier handled server-side).
RegisterNetEvent('gym:client:boost', function(duration)
    ApplySprintBuff(duration)
    lib.notify({
        title = 'Gym',
        description = ('Training boost active for %d min! XP x%s'):format(math.floor(duration / 60), Config.Mix.boostMultiplier),
        type = 'success',
    })
end)
