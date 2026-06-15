-- Cosmetics server logic
local CostMap = {
    primaryColor   = 'primaryColor',
    secondaryColor = 'secondaryColor',
    pearlColor     = 'pearlColor',
    wheelColor     = 'wheelColor',
    wheels         = 'wheels',
    neons          = 'neons',
    xenons         = 'xenons',
    smoke          = 'smoke',
    plateIndex     = 'plateIndex',
}

lib.callback.register('dusa_mechanic:cosmetic', function(src, data)
    if not data or not data.kind then return false end
    local key = CostMap[data.kind]
    local price = key and Config.Prices[key]
    if not price then return false end
    if not ChargePlayer(src, price, 'mech-cosm-' .. data.kind) then
        TriggerClientEvent('ox_lib:notify', src,
            { type = 'error', description = Utils.L('no_money', price) })
        return false
    end
    LogAction(src, 'cosm_' .. data.kind, data.plate, price, data)
    return true
end)
