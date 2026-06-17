-- ========================================================
-- Client: main entry, tablet item use, job check, NUI bridge
-- ========================================================
Tablet = {
    open       = false,
    veh        = nil,
    plate      = nil,
    prop       = nil,
    canUseCache= nil,
    cacheTime  = 0,
}

local function currentVehicle()
    local ped = PlayerPedId()
    if not Config.MustBeInVehicle then
        return GetVehiclePedIsIn(ped, false)
    end
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return 0 end
    if Config.MustBeDriver and GetPedInVehicleSeat(veh, -1) ~= ped then return 0 end
    return veh
end

local function vehiclePlate(veh)
    if not veh or veh == 0 then return nil end
    return string.gsub(GetVehicleNumberPlateText(veh), '%s+', '')
end

local function isBlockedClass(veh)
    local c = GetVehicleClass(veh)
    return Utils.has(Config.BlockedClasses, c)
end

local function jobCheck()
    -- 5s cache to avoid spamming callback
    if Tablet.canUseCache ~= nil and GetGameTimer() - Tablet.cacheTime < 5000 then
        return Tablet.canUseCache
    end
    local ok = lib.callback.await('mechanic_tablet:canUse', false)
    Tablet.canUseCache = ok and true or false
    Tablet.cacheTime   = GetGameTimer()
    return Tablet.canUseCache
end

local function fakeFailAnim()
    -- shake the screen briefly with a notify
    lib.notify({ type = 'error', title = 'TABLET', description = 'ERROR · Unauthorized device' })
    local ped = PlayerPedId()
    RequestAnimDict('mp_player_intupperface_palm')
    Wait(150)
    if HasAnimDictLoaded('mp_player_intupperface_palm') then
        TaskPlayAnim(ped, 'mp_player_intupperface_palm', 'face_palm', 4.0, -4.0, 1200, 0, 0, false, false, false)
    end
end

local function attachTablet(ped)
    if not Config.UseTabletProp then return end
    local model = joaat(Config.TabletProp)
    lib.requestModel(model, 5000)
    local prop = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422),
        0.0, 0.0, 0.03, 10.0, 160.0, 0.0,
        true, true, false, true, 1, true)
    Tablet.prop = prop
    RequestAnimDict(Config.OpenAnim.dict)
    local t = GetGameTimer()
    while not HasAnimDictLoaded(Config.OpenAnim.dict) and GetGameTimer() - t < 1500 do Wait(50) end
    if HasAnimDictLoaded(Config.OpenAnim.dict) then
        TaskPlayAnim(ped, Config.OpenAnim.dict, Config.OpenAnim.clip,
            8.0, -8.0, -1, 49, 0, false, false, false)
    end
end

local function removeTablet()
    if Tablet.prop and DoesEntityExist(Tablet.prop) then
        DeleteEntity(Tablet.prop)
    end
    Tablet.prop = nil
    ClearPedTasks(PlayerPedId())
end

-- ========================================================
-- Entry point: item is used from ox_inventory
-- ========================================================
local function useTablet()
    if Tablet.open then return end
    local veh = currentVehicle()
    if Config.MustBeInVehicle and (not veh or veh == 0) then
        lib.notify({ type = 'error', description = 'Get inside a vehicle first' })
        return
    end
    if veh ~= 0 and isBlockedClass(veh) then
        lib.notify({ type = 'error', description = 'Tablet doesn\'t work on this vehicle type' })
        return
    end
    if Config.MustBeStopped and veh ~= 0 and GetEntitySpeed(veh) > Config.StopSpeed then
        lib.notify({ type = 'error', description = 'Stop the vehicle first' })
        return
    end

    if not jobCheck() then
        if Config.FakeFailForOthers then
            fakeFailAnim()
        else
            lib.notify({ type = 'error', description = 'You can\'t use this tablet' })
        end
        return
    end

    -- Pre-check: warn if the vehicle is occupied by another player (we won't
    -- be able to take network control of it cleanly while they're inside).
    if veh ~= 0 and NetSafe and NetSafe.otherPlayerInside(veh) then
        lib.notify({
            type = 'error',
            description = 'Another player is inside this vehicle — they must step out first.',
            duration = 6000,
        })
        return
    end

    -- Pre-warm network control so the first edit doesn't hitch.
    if veh ~= 0 and NetSafe then
        CreateThread(function()
            if not NetSafe.requestControl(veh, 1500) then
                lib.notify({
                    type = 'warning',
                    description = 'Network sync slow on this vehicle — changes may take a moment.',
                    duration = 4500,
                })
            end
        end)
    end

    Tablet.veh   = veh ~= 0 and veh or nil
    Tablet.plate = Tablet.veh and vehiclePlate(Tablet.veh) or nil
    Tablet.open  = true

    attachTablet(PlayerPedId())
    OpenTabletNUI()
end

-- ox_inventory item registration
exports('useMechanicTablet', useTablet)
RegisterNetEvent('mechanic_tablet:useFromEvent', useTablet)
RegisterCommand('mechtab', useTablet, false)

-- ========================================================
-- Vehicle entered/state restore
-- ========================================================
AddEventHandler('gameEventTriggered', function(name, data)
    if name ~= 'CEventNetworkPlayerEnteredVehicle' then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end
    local plate = vehiclePlate(veh)
    if not plate then return end
    SetTimeout(800, function()
        local row = lib.callback.await('mechanic_tablet:loadVehicle', false, plate)
        if row then
            ApplyStored(veh, row)
        end
    end)
end)

function ApplyStored(veh, row)
    if not veh or veh == 0 or not row then return end
    SetVehicleModKit(veh, 0)
    -- stance
    if Config.PersistStance then
        ApplyStance(veh, {
            wheelWidth   = row.wheel_width  or 1.0,
            wheelSize    = row.wheel_size   or 1.0,
            suspHeight   = row.susp_height  or 0.0,
            trackWidth   = row.track_width  or 0.0,
            camberFront  = row.camber_front or 0.0,
            camberRear   = row.camber_rear  or 0.0,
        })
    end
    -- performance
    if row.engine_lvl and row.engine_lvl >= 0 then SetVehicleMod(veh, 11, row.engine_lvl, false) end
    if row.brake_lvl  and row.brake_lvl  >= 0 then SetVehicleMod(veh, 12, row.brake_lvl, false)  end
    if row.trans_lvl  and row.trans_lvl  >= 0 then SetVehicleMod(veh, 13, row.trans_lvl, false)  end
    if row.susp_lvl   and row.susp_lvl   >= 0 then SetVehicleMod(veh, 15, row.susp_lvl, false)   end
    if row.turbo and row.turbo == 1 then ToggleVehicleMod(veh, 18, true) end
    -- looks
    if row.primary_r ~= nil then SetVehicleCustomPrimaryColour(veh, row.primary_r or 0, row.primary_g or 0, row.primary_b or 0) end
    if row.secondary_r ~= nil then SetVehicleCustomSecondaryColour(veh, row.secondary_r or 0, row.secondary_g or 0, row.secondary_b or 0) end
    if row.neon_r ~= nil then
        for i = 0, 3 do SetVehicleNeonLightEnabled(veh, i, true) end
        SetVehicleNeonLightsColour(veh, row.neon_r, row.neon_g, row.neon_b)
    end
    if row.xenon_idx and row.xenon_idx >= 0 then
        ToggleVehicleMod(veh, 22, true)
        SetVehicleXenonLightsColor(veh, row.xenon_idx)
    end
    if row.plate_idx and row.plate_idx >= 0 then SetVehicleNumberPlateTextIndex(veh, row.plate_idx) end
    if row.wheel_type and row.wheel_type >= 0 then SetVehicleWheelType(veh, row.wheel_type) end
    if row.wheel_mod  and row.wheel_mod  >= 0 then SetVehicleMod(veh, 23, row.wheel_mod, false) end
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    removeTablet()
end)
