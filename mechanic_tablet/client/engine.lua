-- ========================================================
-- Engine / Performance via tablet
-- ========================================================
local PerfState = {}

local function chargePerf(price)
    if not Config.ChargeForMods or not price or price <= 0 then return true end
    local ok = lib.callback.await('mechanic_tablet:charge', false, price)
    if not ok then lib.notify({ type = 'error', description = 'Cannot afford ($' .. price .. ')' }) end
    return ok
end

local function applyPerfNative(veh, kind, level)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    SetVehicleModKit(veh, 0)
    if kind == 'engine' then
        SetVehicleMod(veh, 11, level, false)
    elseif kind == 'brakes' then
        SetVehicleMod(veh, 12, level, false)
    elseif kind == 'trans' then
        SetVehicleMod(veh, 13, level, false)
    elseif kind == 'susp' then
        SetVehicleMod(veh, 15, level, false)
    elseif kind == 'turbo' then
        ToggleVehicleMod(veh, 18, true)
    end
end

Mechanic = Mechanic or {}
Mechanic.applyPerfNative = applyPerfNative

RegisterNetEvent('mechanic_tablet:applyPerf', function(payload)
    CreateThread(function()
        local veh = Tablet.veh
        if not veh or veh == 0 or not DoesEntityExist(veh) then
            lib.notify({ type = 'error', description = 'Vehicle no longer exists' })
            return
        end

        local kind  = payload.kind
        local level = tonumber(payload.level) or 0
        local price

        if kind == 'engine' then
            if level < 0 or level > Config.Performance.engineMax - 1 then return end
            price = (Config.Prices.enginePerLvl or {})[level + 1]
        elseif kind == 'brakes' then
            if level < 0 or level > Config.Performance.brakeMax - 1 then return end
            price = (Config.Prices.brakePerLvl or {})[level + 1]
        elseif kind == 'trans' then
            if level < 0 or level > Config.Performance.transMax - 1 then return end
            price = (Config.Prices.transPerLvl or {})[level + 1]
        elseif kind == 'susp' then
            if level < 0 or level > Config.Performance.suspMax - 1 then return end
        elseif kind == 'turbo' then
            if not Config.Performance.allowTurbo then return end
            price = Config.Prices.turbo
        else
            return
        end

        if not chargePerf(price) then return end

        -- Track local state
        if kind == 'engine' then PerfState.engine = level
        elseif kind == 'brakes' then PerfState.brakes = level
        elseif kind == 'trans'  then PerfState.trans  = level
        elseif kind == 'susp'   then PerfState.susp   = level
        elseif kind == 'turbo'  then PerfState.turbo  = true end

        -- Apply locally if we can, otherwise relay via server to the net owner.
        local hasControl = NetworkHasControlOfEntity(veh)
        if not hasControl and not NetSafe.otherPlayerInside(veh) then
            hasControl = NetSafe.requestControl(veh, 800)
        end

        if hasControl then
            applyPerfNative(veh, kind, level)
        else
            local netId = VehToNet(veh)
            if netId and netId ~= 0 then
                TriggerServerEvent('mechanic_tablet:relay', netId, 'perf',
                    { kind = kind, level = level })
                lib.notify({ description = 'Applied via remote sync', duration = 1500 })
            end
        end

        if Tablet.plate then
            TriggerServerEvent('mechanic_tablet:savePerformance', Tablet.plate, PerfState)
        end
    end)
end)
