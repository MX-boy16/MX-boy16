-- ========================================================
-- Server: job validation, persistence, money
-- ========================================================
local QBX = exports.qbx_core

local function getPlayer(src) return QBX:GetPlayer(src) end

local function jobAllowed(src)
    local p = getPlayer(src)
    if not p then return false end
    local jobName = p.PlayerData.job and p.PlayerData.job.name
    if not jobName then return false end
    if not Utils.has(Config.AllowedJobs, jobName) then return false end
    if Config.RequireOnDuty and not p.PlayerData.job.onduty then return false end
    return true
end

lib.callback.register('mechanic_tablet:canUse', function(src)
    return jobAllowed(src)
end)

-- =========================================================
-- Charging (if enabled)
-- =========================================================
local function chargePlayer(src, amount)
    local p = getPlayer(src)
    if not p then return false end
    local moneyType = Config.Currency
    local bal = p.PlayerData.money[moneyType] or 0
    if bal < amount then return false end
    p.Functions.RemoveMoney(moneyType, amount, 'mechanic_tablet')
    return true
end

lib.callback.register('mechanic_tablet:charge', function(src, amount)
    if not Config.ChargeForMods then return true end
    if not amount or amount <= 0 then return true end
    if not jobAllowed(src) then return false end
    return chargePlayer(src, amount)
end)

-- =========================================================
-- Persistence
-- =========================================================
lib.callback.register('mechanic_tablet:loadVehicle', function(src, plate)
    if not plate or plate == '' then return nil end
    local row = MySQL.single.await('SELECT * FROM mechanic_tablet_vehicles WHERE plate = ?', { plate })
    return row
end)

RegisterNetEvent('mechanic_tablet:saveStance', function(plate, stance)
    if not plate or not stance then return end
    if not jobAllowed(source) then return end
    MySQL.update([[
        INSERT INTO mechanic_tablet_vehicles
            (plate, wheel_width, wheel_size, susp_height, track_width, camber_front, camber_rear)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            wheel_width  = VALUES(wheel_width),
            wheel_size   = VALUES(wheel_size),
            susp_height  = VALUES(susp_height),
            track_width  = VALUES(track_width),
            camber_front = VALUES(camber_front),
            camber_rear  = VALUES(camber_rear)
    ]], {
        plate,
        stance.wheelWidth or 1.0, stance.wheelSize or 1.0,
        stance.suspHeight or 0.0, stance.trackWidth or 0.0,
        stance.camberFront or 0.0, stance.camberRear or 0.0,
    })
end)

RegisterNetEvent('mechanic_tablet:savePerformance', function(plate, perf)
    if not plate or not perf then return end
    if not jobAllowed(source) then return end
    MySQL.update([[
        INSERT INTO mechanic_tablet_vehicles (plate, engine_lvl, brake_lvl, trans_lvl, susp_lvl, turbo)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            engine_lvl = VALUES(engine_lvl),
            brake_lvl  = VALUES(brake_lvl),
            trans_lvl  = VALUES(trans_lvl),
            susp_lvl   = VALUES(susp_lvl),
            turbo      = VALUES(turbo)
    ]], {
        plate,
        perf.engine or -1, perf.brakes or -1,
        perf.trans  or -1, perf.susp   or -1,
        perf.turbo and 1 or 0,
    })
end)

RegisterNetEvent('mechanic_tablet:saveLooks', function(plate, looks)
    if not plate or not looks then return end
    if not jobAllowed(source) then return end
    MySQL.update([[
        INSERT INTO mechanic_tablet_vehicles
            (plate, primary_r, primary_g, primary_b, secondary_r, secondary_g, secondary_b,
             neon_r, neon_g, neon_b, xenon_idx, plate_idx, wheel_type, wheel_mod)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            primary_r=VALUES(primary_r), primary_g=VALUES(primary_g), primary_b=VALUES(primary_b),
            secondary_r=VALUES(secondary_r), secondary_g=VALUES(secondary_g), secondary_b=VALUES(secondary_b),
            neon_r=VALUES(neon_r), neon_g=VALUES(neon_g), neon_b=VALUES(neon_b),
            xenon_idx=VALUES(xenon_idx), plate_idx=VALUES(plate_idx),
            wheel_type=VALUES(wheel_type), wheel_mod=VALUES(wheel_mod)
    ]], {
        plate,
        (looks.primary and looks.primary.r),  (looks.primary and looks.primary.g),  (looks.primary and looks.primary.b),
        (looks.secondary and looks.secondary.r), (looks.secondary and looks.secondary.g), (looks.secondary and looks.secondary.b),
        (looks.neon and looks.neon.r), (looks.neon and looks.neon.g), (looks.neon and looks.neon.b),
        looks.xenon, looks.plate, looks.wheelType, looks.wheelMod,
    })
end)
