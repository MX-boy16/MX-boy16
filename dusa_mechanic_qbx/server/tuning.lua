-- Tuning / Performance server logic

local function priceFor(kind, level)
    if kind == 'engine'  then return Config.Prices.engineUpgrade[level] end
    if kind == 'brakes'  then return Config.Prices.brakeUpgrade[level] end
    if kind == 'trans'   then return Config.Prices.transUpgrade[level] end
    if kind == 'susp'    then return Config.Prices.suspUpgrade[level] end
    if kind == 'turbo'   then return Config.Prices.turbo end
    if kind == 'armor'   then return Config.Prices.armor[level] end
end

lib.callback.register('dusa_mechanic:tuning', function(src, data)
    if not data or not data.kind then return false end
    local price = priceFor(data.kind, data.level)
    if not price or price <= 0 then return false end
    if not ChargePlayer(src, price, 'mech-tune-' .. data.kind) then
        TriggerClientEvent('ox_lib:notify', src,
            { type = 'error', description = Utils.L('no_money', price) })
        return false
    end
    LogAction(src, 'tune_' .. data.kind, data.plate, price, data)
    return true
end)
