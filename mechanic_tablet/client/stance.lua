-- ========================================================
-- Stance: tire width, wheel size, suspension height,
-- track width, camber (front + rear).
-- Live preview while sliding in NUI.
-- ========================================================

local CurrentStance = {
    wheelWidth  = 1.0,
    wheelSize   = 1.0,
    suspHeight  = 0.0,
    trackWidth  = 0.0,
    camberFront = 0.0,
    camberRear  = 0.0,
}

local function clampStance(v, key)
    local lim = Config.Stance[key]
    if not lim then return v end
    return Utils.clamp(v, lim.min, lim.max)
end

-- Pure native call. Caller must hold network control.
function ApplyStance(veh, st)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    SetVehicleModKit(veh, 0)

    if SetVehicleWheelWidth then
        SetVehicleWheelWidth(veh, st.wheelWidth or 1.0)
    end
    if SetVehicleWheelSize then
        SetVehicleWheelSize(veh, st.wheelSize or 1.0)
    end
    if SetVehicleSuspensionHeight then
        SetVehicleSuspensionHeight(veh, st.suspHeight or 0.0)
    end

    local wheelCount = GetVehicleNumberOfWheels(veh)
    for i = 0, wheelCount - 1 do
        local sign = (i % 2 == 0) and -1.0 or 1.0
        SetVehicleWheelXOffset(veh, i, sign * (st.trackWidth or 0.0))
        local isFront = (i == 0 or i == 1)
        local cam     = isFront and (st.camberFront or 0.0) or (st.camberRear or 0.0)
        local camSign = (i % 2 == 0) and 1.0 or -1.0
        SetVehicleWheelYRotation(veh, i, camSign * cam)
    end

    CurrentStance = st
end

-- ========================================================
-- Acquire network control once, then keep it warm during the session.
-- This avoids requesting control on every slider tick.
-- ========================================================
local sessionControlled = false

local function ensureSessionControl(veh)
    if sessionControlled and NetworkHasControlOfEntity(veh) then return true end
    sessionControlled = NetSafe.requestControl(veh, 1500)
    if not sessionControlled then
        lib.notify({
            type = 'error',
            description = 'Cannot control this vehicle (occupied or owned by another player)'
        })
    end
    return sessionControlled
end

local function readPayload(payload)
    return {
        wheelWidth   = clampStance(tonumber(payload.wheelWidth)  or 1.0, 'wheelWidth'),
        wheelSize    = clampStance(tonumber(payload.wheelSize)   or 1.0, 'wheelSize'),
        suspHeight   = clampStance(tonumber(payload.suspHeight)  or 0.0, 'suspHeight'),
        trackWidth   = clampStance(tonumber(payload.trackWidth)  or 0.0, 'trackWidth'),
        camberFront  = clampStance(tonumber(payload.camberFront) or 0.0, 'camberFront'),
        camberRear   = clampStance(tonumber(payload.camberRear)  or 0.0, 'camberRear'),
    }
end

RegisterNetEvent('mechanic_tablet:stancePreview', function(payload)
    local veh = Tablet.veh
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    if NetSafe.otherPlayerInside(veh) then return end
    if not ensureSessionControl(veh) then return end
    ApplyStance(veh, readPayload(payload))
end)

RegisterNetEvent('mechanic_tablet:stanceSave', function(payload)
    if not Tablet.plate then return end
    local veh = Tablet.veh
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    if not ensureSessionControl(veh) then return end
    ApplyStance(veh, readPayload(payload))
    TriggerServerEvent('mechanic_tablet:saveStance', Tablet.plate, CurrentStance)
    lib.notify({ type = 'success', description = 'Stance saved' })
end)

RegisterNetEvent('mechanic_tablet:stanceReset', function()
    local veh = Tablet.veh
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    if not ensureSessionControl(veh) then return end
    local def = {
        wheelWidth   = Config.Stance.wheelWidth.default,
        wheelSize    = Config.Stance.wheelSize.default,
        suspHeight   = Config.Stance.suspHeight.default,
        trackWidth   = Config.Stance.trackWidth.default,
        camberFront  = Config.Stance.camberFront.default,
        camberRear   = Config.Stance.camberRear.default,
    }
    ApplyStance(veh, def)
    if Tablet.plate then
        TriggerServerEvent('mechanic_tablet:saveStance', Tablet.plate, def)
    end
end)

-- Reset the session flag when tablet closes
AddEventHandler('mechanic_tablet:sessionEnded', function()
    sessionControlled = false
end)
