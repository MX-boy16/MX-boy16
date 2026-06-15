-- =========================================================
-- Tuning / Performance
-- =========================================================

-- Mod indexes (GTA V Vehicle Mods)
-- 11 = engine, 12 = brakes, 13 = transmission, 15 = suspension, 16 = armor, 18 = turbo

local function applyMod(veh, modType, modIndex, isToggle)
    SetVehicleModKit(veh, 0)
    if isToggle then
        ToggleVehicleMod(veh, modType, true)
    else
        SetVehicleMod(veh, modType, modIndex, false)
    end
end

local function tuneProgress(label)
    return lib.progressBar({
        duration = Config.Durations.tuning,
        label    = label,
        useWhileDead = false,
        canCancel = true,
        disable   = { car = true, move = true, combat = true },
        anim      = { scenario = 'WORLD_HUMAN_WELDING' }
    })
end

function ApplyTuning(veh, kind, level)
    if not veh or veh == 0 then return end
    local plate = GetVehiclePlate(veh)
    if not tuneProgress(Utils.L('installing')) then
        lib.notify({ type = 'error', description = Utils.L('cancelled') })
        return
    end
    local ok = lib.callback.await('dusa_mechanic:tuning', false, { kind = kind, level = level, plate = plate })
    if not ok then return end
    SetVehicleModKit(veh, 0)
    if kind == 'engine'  then applyMod(veh, 11, level - 1)
    elseif kind == 'brakes'  then applyMod(veh, 12, level - 1)
    elseif kind == 'trans'   then applyMod(veh, 13, level - 1)
    elseif kind == 'susp'    then applyMod(veh, 15, level - 1)
    elseif kind == 'turbo'   then applyMod(veh, 18, nil, true)
    elseif kind == 'armor'   then applyMod(veh, 16, level - 1)
    end
    lib.notify({ type = 'success', description = Utils.L('success') })
end

RegisterNetEvent('dusa_mechanic:tuneFromNui', function(payload)
    local veh = Mechanic.activeVeh or GetClosestVehicle(5.0)
    if not veh or veh == 0 then return end
    ApplyTuning(veh, payload.kind, payload.level or 1)
end)
