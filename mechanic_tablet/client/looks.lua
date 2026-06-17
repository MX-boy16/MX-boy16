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

-- Pure native call. Caller must hold network control.
local function applyLooksNative(veh, payload)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    SetVehicleModKit(veh, 0)
    local kind = payload.kind
    if kind == 'primary' then
        SetVehicleCustomPrimaryColour(veh, payload.r or 0, payload.g or 0, payload.b or 0)
    elseif kind == 'secondary' then
        SetVehicleCustomSecondaryColour(veh, payload.r or 0, payload.g or 0, payload.b or 0)
    elseif kind == 'neons' then
        for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, true) end
        SetVehicleNeonLightsColour(veh, payload.r or 0, payload.g or 0, payload.b or 0)
    elseif kind == 'xenons' then
        ToggleVehicleMod(veh, 22, true)
        SetVehicleXenonLightsColor(veh, payload.idx or 0)
    elseif kind == 'plate' then
        SetVehicleNumberPlateTextIndex(veh, payload.idx or 0)
    elseif kind == 'wheelType' then
        SetVehicleWheelType(veh, payload.type or 0)
        SetVehicleMod(veh, 23, payload.mod or 0, false)
    end
end

-- Expose for the remote-apply receiver (defined in main.lua)
Mechanic = Mechanic or {}
Mechanic.applyLooksNative = applyLooksNative

local PRICE_KEY = {
    primary    = 'looksPaint',
    secondary  = 'looksPaint',
    neons      = 'looksNeons',
    xenons     = 'looksXenons',
    plate      = 'looksPlate',
    wheelType  = 'looksWheels',
}

local function trackLocalState(payload)
    local kind = payload.kind
    if kind == 'primary' then
        LooksState.primary = { r = payload.r, g = payload.g, b = payload.b }
    elseif kind == 'secondary' then
        LooksState.secondary = { r = payload.r, g = payload.g, b = payload.b }
    elseif kind == 'neons' then
        LooksState.neon = { r = payload.r, g = payload.g, b = payload.b }
    elseif kind == 'xenons' then
        LooksState.xenon = payload.idx
    elseif kind == 'plate' then
        LooksState.plate = payload.idx
    elseif kind == 'wheelType' then
        LooksState.wheelType = payload.type
        LooksState.wheelMod  = payload.mod or 0
    end
end

RegisterNetEvent('mechanic_tablet:applyLooks', function(payload)
    CreateThread(function()
        local veh = Tablet.veh
        if not veh or veh == 0 or not DoesEntityExist(veh) then
            lib.notify({ type = 'error', description = 'Vehicle no longer exists' })
            return
        end
        if not chargeIfNeeded(PRICE_KEY[payload.kind]) then return end

        trackLocalState(payload)

        -- Fast path: if we are (or can become) the net owner, apply locally.
        local hasControl = NetworkHasControlOfEntity(veh)
        if not hasControl then
            -- Only try to take control if nobody else is sitting inside,
            -- otherwise we'd fight them. Otherwise go straight to relay.
            if not NetSafe.otherPlayerInside(veh) then
                hasControl = NetSafe.requestControl(veh, 800)
            end
        end

        if hasControl then
            applyLooksNative(veh, payload)
        else
            -- Slow path: route via server to the network owner.
            local netId = VehToNet(veh)
            if netId and netId ~= 0 then
                TriggerServerEvent('mechanic_tablet:relay', netId, 'looks', payload)
                lib.notify({ description = 'Applied via remote sync', duration = 1500 })
            else
                lib.notify({ type = 'error', description = 'No network ID for this vehicle' })
            end
        end

        if Tablet.plate then
            TriggerServerEvent('mechanic_tablet:saveLooks', Tablet.plate, snapshot())
        end
    end)
end)
