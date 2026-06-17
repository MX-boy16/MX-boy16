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

RegisterNetEvent('mechanic_tablet:applyPerf', function(payload)
    local veh = Tablet.veh
    if not veh or not DoesEntityExist(veh) then return end
    SetVehicleModKit(veh, 0)

    local kind = payload.kind
    local level = tonumber(payload.level) or 0

    if kind == 'engine' then
        if level < 0 or level > Config.Performance.engineMax - 1 then return end
        if not chargePerf((Config.Prices.enginePerLvl or {})[level + 1]) then return end
        SetVehicleMod(veh, 11, level, false)
        PerfState.engine = level

    elseif kind == 'brakes' then
        if level < 0 or level > Config.Performance.brakeMax - 1 then return end
        if not chargePerf((Config.Prices.brakePerLvl or {})[level + 1]) then return end
        SetVehicleMod(veh, 12, level, false)
        PerfState.brakes = level

    elseif kind == 'trans' then
        if level < 0 or level > Config.Performance.transMax - 1 then return end
        if not chargePerf((Config.Prices.transPerLvl or {})[level + 1]) then return end
        SetVehicleMod(veh, 13, level, false)
        PerfState.trans = level

    elseif kind == 'susp' then
        if level < 0 or level > Config.Performance.suspMax - 1 then return end
        SetVehicleMod(veh, 15, level, false)
        PerfState.susp = level

    elseif kind == 'turbo' then
        if not Config.Performance.allowTurbo then return end
        if not chargePerf(Config.Prices.turbo) then return end
        ToggleVehicleMod(veh, 18, true)
        PerfState.turbo = true
    end

    if Tablet.plate then
        TriggerServerEvent('mechanic_tablet:savePerformance', Tablet.plate, PerfState)
    end
end)
