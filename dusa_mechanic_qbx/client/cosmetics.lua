-- =========================================================
-- Cosmetics
-- =========================================================

local function cosmProgress()
    return lib.progressBar({
        duration = Config.Durations.cosmetic,
        label    = Utils.L('installing'),
        useWhileDead = false,
        canCancel = true,
        disable   = { car = true, move = true, combat = true },
        anim      = { scenario = 'WORLD_HUMAN_WELDING' }
    })
end

local function applyCosmetic(veh, kind, value, value2)
    SetVehicleModKit(veh, 0)
    local pr, pg, pb = GetVehicleCustomPrimaryColour(veh)
    local sr, sg, sb = GetVehicleCustomSecondaryColour(veh)
    if kind == 'primaryColor' then
        SetVehicleCustomPrimaryColour(veh, value.r or 0, value.g or 0, value.b or 0)
    elseif kind == 'secondaryColor' then
        SetVehicleCustomSecondaryColour(veh, value.r or 0, value.g or 0, value.b or 0)
    elseif kind == 'pearlColor' then
        SetVehicleExtraColours(veh, value or 0, 0)
    elseif kind == 'wheelColor' then
        local p1, p2 = GetVehicleExtraColours(veh)
        SetVehicleExtraColours(veh, p1, value or 0)
    elseif kind == 'wheels' then
        SetVehicleWheelType(veh, value or 0)
        SetVehicleMod(veh, 23, value2 or 0, false)
    elseif kind == 'neons' then
        for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, true) end
        SetVehicleNeonLightsColour(veh, value.r or 255, value.g or 0, value.b or 255)
    elseif kind == 'xenons' then
        ToggleVehicleMod(veh, 22, true)
        SetVehicleXenonLightsColor(veh, value or 0)
    elseif kind == 'smoke' then
        ToggleVehicleMod(veh, 20, true)
        SetVehicleTyreSmokeColor(veh, value.r or 255, value.g or 255, value.b or 255)
    elseif kind == 'plateIndex' then
        SetVehicleNumberPlateTextIndex(veh, value or 0)
    end
end

RegisterNetEvent('dusa_mechanic:cosmFromNui', function(payload)
    local veh = Mechanic.activeVeh or GetClosestVehicle(5.0)
    if not veh or veh == 0 then return end
    if not cosmProgress() then
        lib.notify({ type = 'error', description = Utils.L('cancelled') })
        return
    end
    local plate = GetVehiclePlate(veh)
    local ok = lib.callback.await('dusa_mechanic:cosmetic', false, { kind = payload.kind, plate = plate })
    if not ok then return end
    applyCosmetic(veh, payload.kind, payload.value, payload.value2)
    lib.notify({ type = 'success', description = Utils.L('success') })
end)
