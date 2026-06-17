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

-- Run the actual native calls. Assumes we already have network control.
local function applyLooksNative(veh, payload)
    SetVehicleModKit(veh, 0)
    local kind = payload.kind
    if kind == 'primary' then
        SetVehicleCustomPrimaryColour(veh, payload.r or 0, payload.g or 0, payload.b or 0)
        LooksState.primary = { r = payload.r, g = payload.g, b = payload.b }
    elseif kind == 'secondary' then
        SetVehicleCustomSecondaryColour(veh, payload.r or 0, payload.g or 0, payload.b or 0)
        LooksState.secondary = { r = payload.r, g = payload.g, b = payload.b }
    elseif kind == 'neons' then
        for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, true) end
        SetVehicleNeonLightsColour(veh, payload.r or 0, payload.g or 0, payload.b or 0)
        LooksState.neon = { r = payload.r, g = payload.g, b = payload.b }
    elseif kind == 'xenons' then
        ToggleVehicleMod(veh, 22, true)
        SetVehicleXenonLightsColor(veh, payload.idx or 0)
        LooksState.xenon = payload.idx
    elseif kind == 'plate' then
        SetVehicleNumberPlateTextIndex(veh, payload.idx or 0)
        LooksState.plate = payload.idx
    elseif kind == 'wheelType' then
        SetVehicleWheelType(veh, payload.type or 0)
        SetVehicleMod(veh, 23, payload.mod or 0, false)
        LooksState.wheelType = payload.type
        LooksState.wheelMod  = payload.mod or 0
    end
end

local PRICE_KEY = {
    primary    = 'looksPaint',
    secondary  = 'looksPaint',
    neons      = 'looksNeons',
    xenons     = 'looksXenons',
    plate      = 'looksPlate',
    wheelType  = 'looksWheels',
}

-- Run on its own thread so the NUI callback returns immediately and the
-- game never appears frozen while we try to acquire network ownership.
RegisterNetEvent('mechanic_tablet:applyLooks', function(payload)
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
        if not chargeIfNeeded(PRICE_KEY[payload.kind]) then return end

        NetSafe.withControl(veh, function()
            applyLooksNative(veh, payload)
        end)

        if Tablet.plate then
            TriggerServerEvent('mechanic_tablet:saveLooks', Tablet.plate, snapshot())
        end
    end)
end)
