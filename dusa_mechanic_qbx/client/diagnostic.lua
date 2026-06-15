-- =========================================================
-- Diagnostic Scanner (uses scanner item)
-- =========================================================

local function bodyPercent(veh)
    return Utils.round((GetVehicleBodyHealth(veh) / 1000.0) * 100, 1)
end

local function enginePercent(veh)
    return Utils.round((GetVehicleEngineHealth(veh) / 1000.0) * 100, 1)
end

local function tiresStatus(veh)
    local status = {}
    for i = 0, 5 do
        if IsVehicleTyreBurst(veh, i, false) then
            status[#status+1] = ('Tire %d: BURST'):format(i)
        end
    end
    return status
end

RegisterNetEvent('dusa_mechanic:scanFromMenu', function()
    local veh = Mechanic.activeVeh or GetClosestVehicle(5.0)
    if not veh or veh == 0 then
        lib.notify({ type = 'error', description = 'No vehicle' })
        return
    end
    if not lib.progressBar({
        duration = Config.Durations.scan,
        label    = Utils.L('scanning'),
        canCancel = true,
        disable  = { car = true, move = true, combat = true },
        anim     = { scenario = 'WORLD_HUMAN_CLIPBOARD' }
    }) then return end
    local plate = GetVehiclePlate(veh)
    local data = lib.callback.await('dusa_mechanic:scan', false, plate)
    if not data then return end

    local tires = tiresStatus(veh)
    local lines = {
        ('Plate:      %s'):format(plate),
        ('Body:       %s%%'):format(bodyPercent(veh)),
        ('Engine:     %s%%'):format(enginePercent(veh)),
        ('Engine Wear:%s%%'):format(Utils.round(data.engine_wear or 0, 1)),
        ('Brake Wear: %s%%'):format(Utils.round(data.brake_wear or 0, 1)),
        ('Fuel Tank:  %s%%'):format(Utils.round((GetVehiclePetrolTankHealth(veh)/1000)*100, 1)),
        ('NOS:        %s'):format(data.nos_installed == 1 and ('Installed (%s%%)'):format(Utils.round(data.nos_fuel or 0, 1)) or 'Not installed'),
    }
    for _, t in ipairs(tires) do lines[#lines+1] = t end

    lib.alertDialog({
        header  = Utils.L('scan_title'),
        content = table.concat(lines, '\n'),
        size    = 'md',
    })
end)

-- ox_inventory item use
exports('useDiagnosticScanner', function()
    TriggerEvent('dusa_mechanic:scanFromMenu')
end)
