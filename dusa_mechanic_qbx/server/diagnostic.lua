-- Diagnostic scanner server logic

lib.callback.register('dusa_mechanic:scan', function(src, plate)
    if not plate then return nil end
    if not ChargePlayer(src, Config.Prices.scanFee, 'mech-scan') then
        TriggerClientEvent('ox_lib:notify', src,
            { type = 'error', description = Utils.L('no_money', Config.Prices.scanFee) })
        return nil
    end
    local row = MySQL.single.await('SELECT engine_wear, brake_wear, nos_installed, nos_fuel, last_service FROM dusa_mechanic_vehicles WHERE plate = ?', { plate })
    LogAction(src, 'scan', plate, Config.Prices.scanFee)
    return row or { engine_wear = 0, brake_wear = 0, nos_installed = 0, nos_fuel = 0 }
end)

-- Increase wear over time (client triggers this periodically)
RegisterNetEvent('dusa_mechanic:reportWear', function(plate, engineDelta, brakeDelta)
    if not plate then return end
    MySQL.update([[
        INSERT INTO dusa_mechanic_vehicles (plate, engine_wear, brake_wear)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            engine_wear = LEAST(100, engine_wear + VALUES(engine_wear)),
            brake_wear  = LEAST(100, brake_wear  + VALUES(brake_wear))
    ]], { plate, engineDelta or 0, brakeDelta or 0 })
end)
