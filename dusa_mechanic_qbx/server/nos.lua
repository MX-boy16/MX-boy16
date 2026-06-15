-- NOS server logic

lib.callback.register('dusa_mechanic:nosInstall', function(src, plate)
    if not plate then return false end
    local row = MySQL.single.await('SELECT nos_installed FROM dusa_mechanic_vehicles WHERE plate = ?', { plate })
    if row and row.nos_installed == 1 then
        TriggerClientEvent('ox_lib:notify', src,
            { type = 'error', description = Utils.L('nos_already') })
        return false
    end
    if not ChargePlayer(src, Config.Prices.nosInstall, 'mech-nos-install') then
        TriggerClientEvent('ox_lib:notify', src,
            { type = 'error', description = Utils.L('no_money', Config.Prices.nosInstall) })
        return false
    end
    MySQL.update([[
        INSERT INTO dusa_mechanic_vehicles (plate, nos_installed, nos_fuel)
        VALUES (?, 1, ?)
        ON DUPLICATE KEY UPDATE nos_installed = 1, nos_fuel = ?
    ]], { plate, Config.NOS.maxFuel, Config.NOS.maxFuel })
    LogAction(src, 'nos_install', plate, Config.Prices.nosInstall)
    return true
end)

lib.callback.register('dusa_mechanic:nosRefill', function(src, plate)
    if not plate then return false end
    local row = MySQL.single.await('SELECT nos_installed, nos_fuel FROM dusa_mechanic_vehicles WHERE plate = ?', { plate })
    if not row or row.nos_installed ~= 1 then
        TriggerClientEvent('ox_lib:notify', src,
            { type = 'error', description = Utils.L('nos_not_installed') })
        return false
    end
    if row.nos_fuel and row.nos_fuel >= Config.NOS.maxFuel then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = Utils.L('nos_full') })
        return false
    end
    if not ChargePlayer(src, Config.Prices.nosRefill, 'mech-nos-refill') then
        TriggerClientEvent('ox_lib:notify', src,
            { type = 'error', description = Utils.L('no_money', Config.Prices.nosRefill) })
        return false
    end
    MySQL.update('UPDATE dusa_mechanic_vehicles SET nos_fuel = ? WHERE plate = ?',
        { Config.NOS.maxFuel, plate })
    LogAction(src, 'nos_refill', plate, Config.Prices.nosRefill)
    return true
end)

lib.callback.register('dusa_mechanic:nosGet', function(_, plate)
    if not plate then return nil end
    local row = MySQL.single.await('SELECT nos_installed, nos_fuel FROM dusa_mechanic_vehicles WHERE plate = ?', { plate })
    return row
end)

RegisterNetEvent('dusa_mechanic:nosUpdate', function(plate, fuel)
    if not plate or not fuel then return end
    MySQL.update('UPDATE dusa_mechanic_vehicles SET nos_fuel = ? WHERE plate = ?', { fuel, plate })
end)
