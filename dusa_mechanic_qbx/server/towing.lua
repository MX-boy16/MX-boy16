-- Towing server logic

lib.callback.register('dusa_mechanic:towPayout', function(src)
    if not IsOnDuty(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = Utils.L('not_on_duty') })
        return false
    end
    local amount = math.random(Config.Prices.towPayout.min, Config.Prices.towPayout.max)
    PayPlayer(src, amount, 'mech-tow')
    LogAction(src, 'tow_deliver', nil, amount)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = Utils.L('tow_paid', amount) })
    return amount
end)
