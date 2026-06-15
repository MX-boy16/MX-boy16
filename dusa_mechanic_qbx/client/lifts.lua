-- =========================================================
-- Vehicle Lifts (3D Props + ox_target + raise/lower)
-- =========================================================

local liftEntities = {}  -- key: shopID..idx -> { prop=, veh= , raised= , coords= }

local function spawnLiftProp(coords, heading)
    local model = `prop_carlift_01`
    lib.requestModel(model, 5000)
    local p = CreateObjectNoOffset(model, coords.x, coords.y, coords.z - 0.95, false, false, false)
    SetEntityHeading(p, heading or 0.0)
    FreezeEntityPosition(p, true)
    SetEntityAsMissionEntity(p, true, true)
    return p
end

local function liftKey(shopId, idx) return shopId .. '_' .. idx end

local function moveLift(prop, raised, veh)
    -- Animate up/down by moving the prop & vehicle together
    local startZ = GetEntityCoords(prop).z
    local targetZ = raised and (startZ + 1.5) or (startZ - 1.5)
    local steps = 30
    for i = 1, steps do
        local f = i / steps
        local nz = startZ + (targetZ - startZ) * f
        SetEntityCoordsNoOffset(prop, GetEntityCoords(prop).x, GetEntityCoords(prop).y, nz, false, false, false)
        if veh and DoesEntityExist(veh) then
            FreezeEntityPosition(veh, true)
            local vc = GetEntityCoords(veh)
            SetEntityCoordsNoOffset(veh, vc.x, vc.y, vc.z + ((targetZ - startZ) / steps), false, false, false)
        end
        Wait(33)
    end
end

local function openLift(shop, idx, lift)
    local key = liftKey(shop.id, idx)
    local data = liftEntities[key]
    if not data or not data.prop then return end

    local options = {
        {
            title = data.raised and 'Lower Lift & Open Menu' or 'Raise Lift',
            icon  = 'arrow-up',
            onSelect = function()
                local veh = GetClosestVehicle(3.0) or 0
                local actualVeh = data.veh
                if not actualVeh or actualVeh == 0 or not DoesEntityExist(actualVeh) then
                    -- snap nearest vehicle onto lift
                    if veh ~= 0 then
                        local lc = lift.coords
                        SetEntityCoords(veh, lc.x, lc.y, lc.z + 0.1, false, false, false, false)
                        SetEntityHeading(veh, lift.heading)
                        actualVeh = veh
                        data.veh = veh
                    end
                end
                data.raised = not data.raised
                moveLift(data.prop, data.raised, data.veh)
                if data.raised and data.veh and DoesEntityExist(data.veh) then
                    Mechanic.activeVeh  = data.veh
                    Mechanic.activeShop = shop.id
                    Mechanic.currentLift = key
                    OpenMechanicNUI(data.veh, shop)
                end
            end,
        },
        {
            title = 'Remove Vehicle from Lift',
            icon  = 'xmark',
            canInteract = function() return data.raised or (data.veh and DoesEntityExist(data.veh)) end,
            onSelect = function()
                if data.raised then
                    data.raised = false
                    moveLift(data.prop, false, data.veh)
                end
                if data.veh and DoesEntityExist(data.veh) then
                    FreezeEntityPosition(data.veh, false)
                end
                data.veh = nil
                Mechanic.activeVeh = nil
            end
        }
    }

    lib.registerContext({
        id = 'dusa_lift_' .. key,
        title = ('Lift #%d - %s'):format(idx, shop.label),
        options = options,
    })
    lib.showContext('dusa_lift_' .. key)
end

CreateThread(function()
    -- Spawn lift props & register targets
    for _, shop in ipairs(Config.Shops) do
        for i, lift in ipairs(shop.lifts) do
            local prop = spawnLiftProp(lift.coords, lift.heading)
            liftEntities[liftKey(shop.id, i)] = { prop = prop, veh = nil, raised = false, coords = lift.coords }
            exports.ox_target:addSphereZone({
                coords = vector3(lift.coords.x, lift.coords.y, lift.coords.z + 0.5),
                radius = 2.0,
                debug  = Config.Debug,
                options = {
                    {
                        name   = 'dusa_lift_target_' .. shop.id .. '_' .. i,
                        icon   = 'fas fa-car',
                        label  = Utils.L('lift_use'),
                        canInteract = function() return CanWorkOnVehicle() end,
                        onSelect = function() openLift(shop, i, lift) end,
                    }
                }
            })
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, data in pairs(liftEntities) do
        if data.prop and DoesEntityExist(data.prop) then DeleteEntity(data.prop) end
        if data.veh and DoesEntityExist(data.veh) then FreezeEntityPosition(data.veh, false) end
    end
end)
