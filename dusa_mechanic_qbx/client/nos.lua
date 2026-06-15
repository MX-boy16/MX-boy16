-- =========================================================
-- NOS System (Nitro)
-- =========================================================

NOSState = {
    plate     = nil,
    installed = false,
    fuel      = 0.0,
    active    = false,
    lastBurst = 0,
    boosting  = false,
}

local function showNOSHud(show)
    SendNUIMessage({ type = 'nosHud', show = show, fuel = NOSState.fuel, max = Config.NOS.maxFuel })
end

local function updateNOSHud()
    SendNUIMessage({ type = 'nosUpdate', fuel = NOSState.fuel, active = NOSState.boosting, max = Config.NOS.maxFuel })
end

-- Player enters/exits vehicle: pull NOS state
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local plate = GetVehiclePlate(veh)
            if plate and plate ~= NOSState.plate then
                NOSState.plate = plate
                local row = lib.callback.await('dusa_mechanic:nosGet', false, plate)
                if row and row.nos_installed == 1 then
                    NOSState.installed = true
                    NOSState.fuel = row.nos_fuel or 0
                    showNOSHud(true)
                else
                    NOSState.installed = false
                    NOSState.fuel = 0
                    showNOSHud(false)
                end
            end
        else
            if NOSState.plate then
                NOSState.plate = nil
                NOSState.installed = false
                NOSState.fuel = 0
                NOSState.boosting = false
                showNOSHud(false)
            end
        end
        Wait(800)
    end
end)

-- NOS keybind
lib.addKeybind({
    name        = 'dusa_nos',
    description = 'Activate NOS',
    defaultKey  = 'LSHIFT',
    onPressed   = function()
        if not NOSState.installed then return end
        if NOSState.fuel <= 0 then return end
        if (GetGameTimer() - NOSState.lastBurst) < Config.NOS.cooldown then return end
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return end
        NOSState.boosting = true
    end,
    onReleased  = function()
        NOSState.boosting = false
        NOSState.lastBurst = GetGameTimer()
    end,
})

-- Boost tick
CreateThread(function()
    while true do
        if NOSState.boosting and NOSState.installed and NOSState.fuel > 0 then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                local fwd = GetEntityForwardVector(veh)
                local cur = GetEntityVelocity(veh)
                local boost = Config.NOS.boostForce
                SetVehicleForwardSpeed(veh, math.min(GetEntitySpeed(veh) + 2.5, 90.0))
                ApplyForceToEntity(veh, 1,
                    fwd.x * boost, fwd.y * boost, fwd.z * boost,
                    0.0, 0.0, 0.0, 0, true, true, true, false, true)
                NOSState.fuel = math.max(0, NOSState.fuel - (Config.NOS.drainPerSec * 0.05))
                updateNOSHud()
                if NOSState.fuel <= 0 then
                    NOSState.boosting = false
                    TriggerServerEvent('dusa_mechanic:nosUpdate', NOSState.plate, 0)
                end
            end
            Wait(50)
        else
            Wait(250)
        end
    end
end)

-- Save fuel periodically
CreateThread(function()
    while true do
        Wait(15000)
        if NOSState.installed and NOSState.plate then
            TriggerServerEvent('dusa_mechanic:nosUpdate', NOSState.plate, NOSState.fuel)
        end
    end
end)

-- Install / Refill from NUI
RegisterNetEvent('dusa_mechanic:nosInstallFromNui', function()
    local veh = Mechanic.activeVeh or GetClosestVehicle(5.0)
    if not veh or veh == 0 then return end
    local plate = GetVehiclePlate(veh)
    if not lib.progressBar({
        duration = Config.Durations.nosInstall,
        label    = Utils.L('installing'),
        canCancel = true,
        disable   = { car = true, move = true, combat = true },
        anim     = { scenario = 'WORLD_HUMAN_WELDING' }
    }) then return end
    local ok = lib.callback.await('dusa_mechanic:nosInstall', false, plate)
    if ok then lib.notify({ type = 'success', description = Utils.L('success') }) end
end)

RegisterNetEvent('dusa_mechanic:nosRefillFromNui', function()
    local veh = Mechanic.activeVeh or GetClosestVehicle(5.0)
    if not veh or veh == 0 then return end
    local plate = GetVehiclePlate(veh)
    if not lib.progressBar({
        duration = Config.Durations.nosRefill,
        label    = Utils.L('installing'),
        canCancel = true,
        disable   = { car = true, move = true, combat = true },
        anim     = { scenario = 'WORLD_HUMAN_WELDING' }
    }) then return end
    local ok = lib.callback.await('dusa_mechanic:nosRefill', false, plate)
    if ok then
        NOSState.fuel = Config.NOS.maxFuel
        updateNOSHud()
        lib.notify({ type = 'success', description = Utils.L('success') })
    end
end)
