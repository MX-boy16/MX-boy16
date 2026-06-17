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

function ApplyStance(veh, st)
    if not veh or veh == 0 then return end
    SetVehicleModKit(veh, 0)

    -- Tire width + wheel size
    if SetVehicleWheelWidth then
        SetVehicleWheelWidth(veh, st.wheelWidth or 1.0)
    end
    if SetVehicleWheelSize then
        SetVehicleWheelSize(veh, st.wheelSize or 1.0)
    end

    -- Suspension height
    if SetVehicleSuspensionHeight then
        SetVehicleSuspensionHeight(veh, st.suspHeight or 0.0)
    end

    -- Track width + camber per wheel
    local wheelCount = GetVehicleNumberOfWheels(veh)
    for i = 0, wheelCount - 1 do
        -- X offset (track width): left wheels negative, right wheels positive
        local sign = (i % 2 == 0) and -1.0 or 1.0
        SetVehicleWheelXOffset(veh, i, sign * (st.trackWidth or 0.0))

        -- Camber: front wheels = i 0,1; rear wheels = the rest
        local isFront = (i == 0 or i == 1)
        local cam     = isFront and (st.camberFront or 0.0) or (st.camberRear or 0.0)
        -- Sign flip per side so wheel tops tilt inward when negative
        local camSign = (i % 2 == 0) and 1.0 or -1.0
        SetVehicleWheelYRotation(veh, i, camSign * cam)
    end

    CurrentStance = st
end

-- ========================================================
-- NUI events for sliders
-- ========================================================
RegisterNetEvent('mechanic_tablet:stancePreview', function(payload)
    if not Tablet.veh or not DoesEntityExist(Tablet.veh) then return end
    local st = {
        wheelWidth   = clampStance(tonumber(payload.wheelWidth)  or 1.0, 'wheelWidth'),
        wheelSize    = clampStance(tonumber(payload.wheelSize)   or 1.0, 'wheelSize'),
        suspHeight   = clampStance(tonumber(payload.suspHeight)  or 0.0, 'suspHeight'),
        trackWidth   = clampStance(tonumber(payload.trackWidth)  or 0.0, 'trackWidth'),
        camberFront  = clampStance(tonumber(payload.camberFront) or 0.0, 'camberFront'),
        camberRear   = clampStance(tonumber(payload.camberRear)  or 0.0, 'camberRear'),
    }
    ApplyStance(Tablet.veh, st)
end)

RegisterNetEvent('mechanic_tablet:stanceSave', function(payload)
    if not Tablet.plate then return end
    TriggerEvent('mechanic_tablet:stancePreview', payload)
    TriggerServerEvent('mechanic_tablet:saveStance', Tablet.plate, CurrentStance)
    lib.notify({ type = 'success', description = 'Stance saved' })
end)

RegisterNetEvent('mechanic_tablet:stanceReset', function()
    local def = {
        wheelWidth   = Config.Stance.wheelWidth.default,
        wheelSize    = Config.Stance.wheelSize.default,
        suspHeight   = Config.Stance.suspHeight.default,
        trackWidth   = Config.Stance.trackWidth.default,
        camberFront  = Config.Stance.camberFront.default,
        camberRear   = Config.Stance.camberRear.default,
    }
    ApplyStance(Tablet.veh, def)
    if Tablet.plate then
        TriggerServerEvent('mechanic_tablet:saveStance', Tablet.plate, def)
    end
end)
