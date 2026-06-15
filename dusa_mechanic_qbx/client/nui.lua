-- =========================================================
-- NUI Bridge (opens HTML/CSS/JS UI for the mechanic menu)
-- =========================================================

local function vehicleSnapshot(veh)
    SetVehicleModKit(veh, 0)
    local snap = {
        plate    = GetVehiclePlate(veh),
        model    = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh))),
        modelName= GetDisplayNameFromVehicleModel(GetEntityModel(veh)),
        body     = math.floor((GetVehicleBodyHealth(veh) / 1000.0) * 100),
        engine   = math.floor((GetVehicleEngineHealth(veh) / 1000.0) * 100),
        tires    = {},
        windows  = {},
        mods = {
            engine = GetVehicleMod(veh, 11),
            brakes = GetVehicleMod(veh, 12),
            trans  = GetVehicleMod(veh, 13),
            susp   = GetVehicleMod(veh, 15),
            armor  = GetVehicleMod(veh, 16),
            turbo  = IsToggleModOn(veh, 18),
        },
        maxMods = {
            engine = GetNumVehicleMods(veh, 11),
            brakes = GetNumVehicleMods(veh, 12),
            trans  = GetNumVehicleMods(veh, 13),
            susp   = GetNumVehicleMods(veh, 15),
            armor  = GetNumVehicleMods(veh, 16),
        },
    }
    for i = 0, 5 do snap.tires[i+1] = not IsVehicleTyreBurst(veh, i, false) end
    return snap
end

function OpenMechanicNUI(veh, shop)
    if Mechanic.nuiOpen then return end
    local snap = vehicleSnapshot(veh)
    Mechanic.nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type    = 'open',
        shop    = { id = shop.id, label = shop.label },
        vehicle = snap,
        prices  = Config.Prices,
        canWork = CanWorkOnVehicle(),
    })
end

function CloseMechanicNUI()
    Mechanic.nuiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    CloseMechanicNUI()
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    if Mechanic.activeVeh and DoesEntityExist(Mechanic.activeVeh) then
        cb({ vehicle = vehicleSnapshot(Mechanic.activeVeh) })
    else
        cb({ vehicle = nil })
    end
end)

RegisterNUICallback('action', function(data, cb)
    local kind = data.kind
    if kind == 'repair' then
        TriggerEvent('dusa_mechanic:repairFromNui', data.what)
    elseif kind == 'tune' then
        TriggerEvent('dusa_mechanic:tuneFromNui', { kind = data.what, level = data.level })
    elseif kind == 'cosm' then
        TriggerEvent('dusa_mechanic:cosmFromNui', { kind = data.what, value = data.value, value2 = data.value2 })
    elseif kind == 'nosInstall' then
        TriggerEvent('dusa_mechanic:nosInstallFromNui')
    elseif kind == 'nosRefill' then
        TriggerEvent('dusa_mechanic:nosRefillFromNui')
    elseif kind == 'scan' then
        TriggerEvent('dusa_mechanic:scanFromMenu')
    end
    -- delay then send fresh snapshot
    SetTimeout(500, function()
        if Mechanic.activeVeh and DoesEntityExist(Mechanic.activeVeh) then
            SendNUIMessage({ type = 'updateVehicle', vehicle = vehicleSnapshot(Mechanic.activeVeh) })
        end
    end)
    cb({ ok = true })
end)

-- ESC key auto-close
RegisterNUICallback('escape', function(_, cb) CloseMechanicNUI() cb({ ok = true }) end)

-- Command for testing
RegisterCommand('mechmenu', function()
    local veh = GetClosestVehicle(8.0)
    if not veh or veh == 0 then
        lib.notify({ type = 'error', description = 'No vehicle nearby' })
        return
    end
    Mechanic.activeVeh = veh
    OpenMechanicNUI(veh, Config.Shops[1])
end, false)
