-- ========================================================
-- Shared client helpers: network ownership + safe apply
-- ========================================================
NetSafe = {}

-- Try to acquire network control of an entity. Returns true if successful.
function NetSafe.requestControl(entity, timeoutMs)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if NetworkHasControlOfEntity(entity) then return true end

    timeoutMs = timeoutMs or 1500
    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId and netId ~= 0 then
        SetNetworkIdCanMigrate(netId, true)
    end

    local start = GetGameTimer()
    while not NetworkHasControlOfEntity(entity) and (GetGameTimer() - start) < timeoutMs do
        NetworkRequestControlOfEntity(entity)
        Wait(50)
    end
    return NetworkHasControlOfEntity(entity)
end

-- Wrapper: run `fn` only if we are/became net owner. Notifies user otherwise.
function NetSafe.withControl(entity, fn)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        lib.notify({ type = 'error', description = 'Vehicle no longer exists' })
        return false
    end
    if not NetSafe.requestControl(entity, 1500) then
        lib.notify({
            type = 'error',
            description = 'Cannot control this vehicle (owned by another player). Ask them to step out.'
        })
        return false
    end
    -- Run guarded
    local ok, err = pcall(fn)
    if not ok and Config.Debug then
        print('[mechanic_tablet] apply error:', err)
    end
    return ok
end

-- Check whether the vehicle is occupied by another player (not us)
function NetSafe.otherPlayerInside(veh)
    if not veh or veh == 0 then return false end
    local me = PlayerPedId()
    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(veh))
    for s = -1, seats - 2 do
        local ped = GetPedInVehicleSeat(veh, s)
        if ped ~= 0 and ped ~= me and IsPedAPlayer(ped) then
            return true
        end
    end
    return false
end
