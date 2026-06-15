-- =========================================================
-- Repair logic (interfaces with NUI + direct ox_lib menus)
-- =========================================================

local function progress(label, duration, anim)
    return lib.progressBar({
        duration = duration,
        label    = label,
        useWhileDead = false,
        canCancel = true,
        disable   = { car = true, move = true, combat = true },
        anim      = anim or {
            scenario = 'WORLD_HUMAN_WELDING',
        }
    })
end

function RepairAction(veh, kind, label, duration, priceKey)
    if not veh or veh == 0 then return end
    local plate = GetVehiclePlate(veh)
    -- progress
    if not progress(label, duration) then
        lib.notify({ type = 'error', description = Utils.L('cancelled') })
        return
    end
    -- charge server-side
    local ok = lib.callback.await('dusa_mechanic:repair', false, { kind = kind, plate = plate })
    if not ok then return end
    -- apply repair to vehicle
    if kind == 'tire' then
        for i = 0, 7 do
            if IsVehicleTyreBurst(veh, i, false) then
                SetVehicleTyreFixed(veh, i)
            end
        end
    elseif kind == 'window' then
        for i = 0, 7 do FixVehicleWindow(veh, i) end
    elseif kind == 'body' then
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
    elseif kind == 'engine' then
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleUndriveable(veh, false)
        SetVehicleEngineOn(veh, true, true, false)
    elseif kind == 'full' then
        SetVehicleFixed(veh)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehicleDeformationFixed(veh)
        SetVehicleUndriveable(veh, false)
        SetVehiclePetrolTankHealth(veh, 1000.0)
        SetVehicleDirtLevel(veh, 0.0)
        SetVehicleEngineOn(veh, true, true, false)
    elseif kind == 'clean' then
        SetVehicleDirtLevel(veh, 0.0)
    end
    lib.notify({ type = 'success', description = Utils.L('success') })
end

-- Triggered from NUI
RegisterNetEvent('dusa_mechanic:repairFromNui', function(kind)
    local veh = Mechanic.activeVeh or GetClosestVehicle(5.0)
    if not veh or veh == 0 then return end
    local map = {
        tire   = { Utils.L('repairing'), Config.Durations.repairTire },
        window = { Utils.L('repairing'), Config.Durations.repairWindow },
        body   = { Utils.L('repairing'), Config.Durations.repairBody },
        engine = { Utils.L('repairing'), Config.Durations.repairEngine },
        full   = { Utils.L('repairing'), Config.Durations.fullRepair },
        clean  = { Utils.L('cleaning'),  Config.Durations.cleaning },
    }
    local m = map[kind]
    if not m then return end
    RepairAction(veh, kind, m[1], m[2])
end)
