-- =========================================================
-- Towing system (flatbed truck)
-- =========================================================

TowState = {
    truck = nil,
    hooked = nil,
}

local function spawnFlatbed()
    local model = joaat(Config.Tow.vehicleModel)
    lib.requestModel(model, 5000)
    local sp = Config.Tow.spawnPoint
    local veh = CreateVehicle(model, sp.x, sp.y, sp.z, sp.w, true, false)
    SetVehicleNumberPlateText(veh, ('TOW%d'):format(math.random(100, 999)))
    SetEntityAsMissionEntity(veh, true, true)
    return veh
end

RegisterCommand('mechtow', function()
    if not Mechanic.isMechanic then
        lib.notify({ type = 'error', description = Utils.L('not_mechanic') })
        return
    end
    if not Mechanic.onDuty then
        lib.notify({ type = 'error', description = Utils.L('not_on_duty') })
        return
    end
    if TowState.truck and DoesEntityExist(TowState.truck) then
        lib.notify({ description = 'Tow truck already spawned' })
        return
    end
    TowState.truck = spawnFlatbed()
end, false)

-- Hook a vehicle to tow truck
RegisterCommand('mechhook', function()
    if not TowState.truck or not DoesEntityExist(TowState.truck) then
        lib.notify({ type = 'error', description = 'No tow truck' })
        return
    end
    if TowState.hooked then
        AttachEntityToEntity(TowState.hooked, TowState.truck, 20, 0, 0, 0, 0, 0, 0,
            true, true, false, false, 20, true)
        TowState.hooked = nil
        lib.notify({ description = Utils.L('tow_unhook') })
        return
    end
    local veh = GetClosestVehicle(8.0)
    if not veh or veh == 0 then
        lib.notify({ type = 'error', description = 'No vehicle nearby' })
        return
    end
    local d = #(GetEntityCoords(veh) - GetEntityCoords(TowState.truck))
    if d > Config.Tow.maxDistance + 4.0 then
        lib.notify({ type = 'error', description = Utils.L('tow_too_far') })
        return
    end
    if not lib.progressBar({
        duration = Config.Durations.hookTow,
        label    = 'Hooking vehicle...',
        canCancel = true,
        disable  = { car = true, move = true, combat = true },
    }) then return end
    AttachEntityToEntity(veh, TowState.truck, 20,
        0.0, -5.0, 1.0, 0.0, 0.0, 0.0,
        false, false, false, false, 20, true)
    TowState.hooked = veh
    lib.notify({ type = 'success', description = Utils.L('tow_hook') })
end, false)

-- Deliver
CreateThread(function()
    local imp = Config.Tow.impound
    while true do
        local wait = 1500
        if TowState.hooked and TowState.truck and DoesEntityExist(TowState.truck) then
            local dist = #(GetEntityCoords(TowState.truck) - vector3(imp.x, imp.y, imp.z))
            if dist < 12.0 then
                wait = 50
                lib.showTextUI('[E] - ' .. Utils.L('tow_deliver'), { icon = 'truck' })
                if IsControlJustPressed(0, 38) then
                    DetachEntity(TowState.hooked, true, true)
                    DeleteEntity(TowState.hooked)
                    TowState.hooked = nil
                    lib.hideTextUI()
                    lib.callback.await('dusa_mechanic:towPayout', false)
                end
            else
                lib.hideTextUI()
            end
        end
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if TowState.truck and DoesEntityExist(TowState.truck) then DeleteEntity(TowState.truck) end
    if TowState.hooked and DoesEntityExist(TowState.hooked) then DetachEntity(TowState.hooked, true, true) end
end)
