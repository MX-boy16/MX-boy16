-- Repair server logic
-- All charges validated server-side

local function chargeAndLog(src, amount, action, plate, meta)
    if not ChargePlayer(src, amount, 'mech-' .. action) then
        TriggerClientEvent('ox_lib:notify', src,
            { type = 'error', description = Utils.L('no_money', amount) })
        return false
    end
    LogAction(src, action, plate, amount, meta)
    return true
end

lib.callback.register('dusa_mechanic:repair', function(src, data)
    if not data or not data.kind or not data.plate then return false end
    local price = 0
    if data.kind == 'tire' then
        price = Config.Prices.tire
    elseif data.kind == 'window' then
        price = Config.Prices.window
    elseif data.kind == 'body' then
        price = Config.Prices.body
    elseif data.kind == 'engine' then
        price = Config.Prices.engine
    elseif data.kind == 'full' then
        price = Config.Prices.fullRepair
    elseif data.kind == 'clean' then
        price = Config.Prices.fullClean
    else
        return false
    end
    if not chargeAndLog(src, price, 'repair_' .. data.kind, data.plate, data) then
        return false
    end
    -- reset wear on full repair
    if data.kind == 'full' then
        MySQL.update([[
            INSERT INTO dusa_mechanic_vehicles (plate, engine_wear, brake_wear, last_service)
            VALUES (?, 0, 0, CURRENT_TIMESTAMP)
            ON DUPLICATE KEY UPDATE engine_wear = 0, brake_wear = 0, last_service = CURRENT_TIMESTAMP
        ]], { data.plate })
    end
    return true
end)
