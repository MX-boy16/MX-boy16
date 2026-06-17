-- ========================================================
-- NUI Bridge for the tablet UI
-- ========================================================

local function buildSnapshot(veh)
    if not veh or veh == 0 then return nil end
    SetVehicleModKit(veh, 0)
    local snap = {
        plate     = (veh and string.gsub(GetVehicleNumberPlateText(veh), '%s+', '')) or 'NO-PLATE',
        modelName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh))),
        rawName   = GetDisplayNameFromVehicleModel(GetEntityModel(veh)),
        body      = math.floor((GetVehicleBodyHealth(veh) / 1000.0) * 100),
        engine    = math.floor((GetVehicleEngineHealth(veh) / 1000.0) * 100),
        wheelCount= GetVehicleNumberOfWheels(veh),
        mods = {
            engine = GetVehicleMod(veh, 11),
            brakes = GetVehicleMod(veh, 12),
            trans  = GetVehicleMod(veh, 13),
            susp   = GetVehicleMod(veh, 15),
            turbo  = IsToggleModOn(veh, 18),
            wheelType = GetVehicleWheelType(veh),
            wheelMod  = GetVehicleMod(veh, 23),
        },
        maxMods = {
            engine = Config.Performance.engineMax,
            brakes = Config.Performance.brakeMax,
            trans  = Config.Performance.transMax,
            susp   = Config.Performance.suspMax,
        },
    }
    return snap
end

function OpenTabletNUI()
    SetNuiFocus(true, true)
    SendNUIMessage({
        type    = 'open',
        vehicle = Tablet.veh and buildSnapshot(Tablet.veh) or nil,
        config  = {
            stance      = Config.Stance,
            charge      = Config.ChargeForMods,
            currency    = Config.Currency,
            prices      = Config.Prices,
            performance = Config.Performance,
            allowedJobs = Config.AllowedJobs,
        },
    })
end

function CloseTabletNUI()
    Tablet.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
    if Tablet.prop and DoesEntityExist(Tablet.prop) then DeleteEntity(Tablet.prop) end
    Tablet.prop = nil
    ClearPedTasks(PlayerPedId())
    Tablet.veh = nil
    Tablet.plate = nil
    TriggerEvent('mechanic_tablet:sessionEnded')
end

RegisterNUICallback('close', function(_, cb)
    CloseTabletNUI()
    cb({ ok = true })
end)

RegisterNUICallback('stance', function(data, cb)
    -- mode = 'preview' | 'save' | 'reset'
    if data.mode == 'save' then
        TriggerEvent('mechanic_tablet:stanceSave', data)
    elseif data.mode == 'reset' then
        TriggerEvent('mechanic_tablet:stanceReset')
    else
        TriggerEvent('mechanic_tablet:stancePreview', data)
    end
    cb({ ok = true })
end)

RegisterNUICallback('looks', function(data, cb)
    TriggerEvent('mechanic_tablet:applyLooks', data)
    cb({ ok = true })
end)

RegisterNUICallback('perf', function(data, cb)
    TriggerEvent('mechanic_tablet:applyPerf', data)
    cb({ ok = true })
end)
