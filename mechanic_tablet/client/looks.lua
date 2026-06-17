-- ========================================================
-- Looks: paint, neons, xenons, wheels, plate
-- ========================================================
local LooksState = {}

local function snapshot()
    return LooksState
end

local function chargeIfNeeded(key)
    if not Config.ChargeForMods then return true end
    local price = Config.Prices[key]
    if not price or price <= 0 then return true end
    local ok = lib.callback.await('mechanic_tablet:charge', false, price)
    if not ok then lib.notify({ type = 'error', description = 'Cannot afford ($' .. price .. ')' }) end
    return ok
end

RegisterNetEvent('mechanic_tablet:applyLooks', function(payload)
    local veh = Tablet.veh
    if not veh or not DoesEntityExist(veh) then return end
    SetVehicleModKit(veh, 0)

    local kind = payload.kind
    if kind == 'primary' then
        if not chargeIfNeeded('looksPaint') then return end
        SetVehicleCustomPrimaryColour(veh, payload.r, payload.g, payload.b)
        LooksState.primary = { r = payload.r, g = payload.g, b = payload.b }

    elseif kind == 'secondary' then
        if not chargeIfNeeded('looksPaint') then return end
        SetVehicleCustomSecondaryColour(veh, payload.r, payload.g, payload.b)
        LooksState.secondary = { r = payload.r, g = payload.g, b = payload.b }

    elseif kind == 'neons' then
        if not chargeIfNeeded('looksNeons') then return end
        for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, true) end
        SetVehicleNeonLightsColour(veh, payload.r, payload.g, payload.b)
        LooksState.neon = { r = payload.r, g = payload.g, b = payload.b }

    elseif kind == 'xenons' then
        if not chargeIfNeeded('looksXenons') then return end
        ToggleVehicleMod(veh, 22, true)
        SetVehicleXenonLightsColor(veh, payload.idx)
        LooksState.xenon = payload.idx

    elseif kind == 'plate' then
        if not chargeIfNeeded('looksPlate') then return end
        SetVehicleNumberPlateTextIndex(veh, payload.idx)
        LooksState.plate = payload.idx

    elseif kind == 'wheelType' then
        if not chargeIfNeeded('looksWheels') then return end
        SetVehicleWheelType(veh, payload.type)
        SetVehicleMod(veh, 23, payload.mod or 0, false)
        LooksState.wheelType = payload.type
        LooksState.wheelMod  = payload.mod or 0
    end

    if Tablet.plate then
        TriggerServerEvent('mechanic_tablet:saveLooks', Tablet.plate, snapshot())
    end
end)
