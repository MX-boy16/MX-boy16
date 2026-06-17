-- ========================================================
-- Engine / Performance via tablet
-- ========================================================
local PerfState = {}

local function chargePerf(price)
    if not Config.ChargeForMods or not price or price <= 0 then return true end
    local ok = lib.callback.await('mechanic_tablet:charge', false, price)
    if not ok then lib.notify({ type = 'error', description = 'Cannot afford ($' .. price .. ')' }) end
    return ok
end

local function applyPerfNative(veh, kind, level)
    SetVehicleModKit(veh, 0)
    if kind == 'engine' then
        SetVehicleMod(veh, 11, level, false); PerfState.engine = level
    elseif kind == 'brakes' then
        SetVehicleMod(veh, 12, level, false); PerfState.brakes = level
    elseif kind == 'trans' then
        SetVehicleMod(veh, 13, level, false); PerfState.trans = level
    elseif kind == 'susp' then
        SetVehicleMod(veh, 15, level, false); PerfState.susp = level
    elseif kind == 'turbo' then
        ToggleVehicleMod(veh, 18, true); PerfState.turbo = true
    end
end

RegisterNetEvent('mechanic_tablet:applyPerf', function(payload)
    CreateThread(function()
        local veh = Tablet.veh
        if not veh or veh == 0 or not DoesEntityExist(veh) then
            lib.notify({ type = 'error', description = 'Vehicle no longer exists' })
            return
        end
        if NetSafe.otherPlayerInside(veh) then
            lib.notify({ type = 'error', description = 'Another player is inside the vehicle' })
            return
        end

        local kind  = payload.kind
        local level = tonumber(payload.level) or 0
        local price

        if kind == 'engine' then
            if level < 0 or level > Config.Performance.engineMax - 1 then return end
            price = (Config.Prices.enginePerLvl or {})[level + 1]
        elseif kind == 'brakes' then
            if level < 0 or level > Config.Performance.brakeMax - 1 then return end
            price = (Config.Prices.brakePerLvl or {})[level + 1]
        elseif kind == 'trans' then
            if level < 0 or level > Config.Performance.transMax - 1 then return end
            price = (Config.Prices.transPerLvl or {})[level + 1]
        elseif kind == 'susp' then
            if level < 0 or level > Config.Performance.suspMax - 1 then return end
            -- suspension perf is free in this system (stance is separate)
        elseif kind == 'turbo' then
            if not Config.Performance.allowTurbo then return end
            price = Config.Prices.turbo
        else
            return
        end

        if not chargePerf(price) then return end

        NetSafe.withControl(veh, function()
            applyPerfNative(veh, kind, level)
        end)

        if Tablet.plate then
            TriggerServerEvent('mechanic_tablet:savePerformance', Tablet.plate, PerfState)
        end
    end)
end)
