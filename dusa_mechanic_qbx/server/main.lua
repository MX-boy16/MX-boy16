local QBX = exports.qbx_core

-- ========== HELPERS ==========
function GetPlayer(src)
    return QBX:GetPlayer(src)
end

function HasJob(src)
    local player = GetPlayer(src)
    if not player then return false end
    return player.PlayerData.job and player.PlayerData.job.name == Config.JobName
end

function IsOnDuty(src)
    local player = GetPlayer(src)
    if not player then return false end
    return player.PlayerData.job and player.PlayerData.job.name == Config.JobName
        and player.PlayerData.job.onduty
end

function ChargePlayer(src, amount, reason)
    local player = GetPlayer(src)
    if not player then return false end
    local cash = player.PlayerData.money.cash or 0
    local bank = player.PlayerData.money.bank or 0
    if cash >= amount then
        player.Functions.RemoveMoney('cash', amount, reason or 'mechanic')
    elseif bank >= amount then
        player.Functions.RemoveMoney('bank', amount, reason or 'mechanic')
    else
        return false
    end
    if Config.UseSociety then
        MySQL.update('UPDATE dusa_mechanic_society SET balance = balance + ? WHERE name = ?',
            { amount, Config.SocietyAccount })
    end
    return true
end

function PayPlayer(src, amount, reason)
    local player = GetPlayer(src)
    if not player then return false end
    player.Functions.AddMoney('cash', amount, reason or 'mechanic-pay')
    return true
end

function HasItem(src, item, count)
    local inv = exports.ox_inventory:Search(src, 'count', item)
    return (inv or 0) >= (count or 1)
end

function RemoveItem(src, item, count)
    return exports.ox_inventory:RemoveItem(src, item, count or 1)
end

function GiveItem(src, item, count)
    return exports.ox_inventory:AddItem(src, item, count or 1)
end

function LogAction(src, action, plate, amount, meta)
    local player = GetPlayer(src)
    if not player then return end
    MySQL.insert('INSERT INTO dusa_mechanic_logs (citizenid, action, plate, amount, meta) VALUES (?, ?, ?, ?, ?)',
        { player.PlayerData.citizenid, action, plate or '', amount or 0, meta and json.encode(meta) or nil })
end

-- ========== SHARED CALLBACKS ==========
lib.callback.register('dusa_mechanic:isOnDuty', function(src)
    return IsOnDuty(src)
end)

lib.callback.register('dusa_mechanic:hasJob', function(src)
    return HasJob(src)
end)

-- Charge wrapper for client requests
lib.callback.register('dusa_mechanic:charge', function(src, amount, reason)
    if not IsOnDuty(src) and Config.RequireJob then
        -- Customers pay the mechanic; if no mech on duty, can still self-service from client menu
        -- but we still validate amount > 0
    end
    if not amount or amount <= 0 then return false end
    return ChargePlayer(src, amount, reason)
end)

RegisterNetEvent('dusa_mechanic:log', function(action, plate, amount, meta)
    LogAction(source, action, plate, amount, meta)
end)

-- Toggle duty (called from client menu)
RegisterNetEvent('dusa_mechanic:toggleDuty', function()
    local src = source
    local player = GetPlayer(src)
    if not player or player.PlayerData.job.name ~= Config.JobName then
        TriggerClientEvent('ox_lib:notify', src,
            { type = 'error', description = Utils.L('not_mechanic') })
        return
    end
    player.Functions.SetJobDuty(not player.PlayerData.job.onduty)
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = player.PlayerData.job.onduty and Utils.L('on_duty') or Utils.L('off_duty')
    })
end)

-- Society stash registration on resource start
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, shop in ipairs(Config.Shops) do
        exports.ox_inventory:RegisterStash('dusa_mech_' .. shop.id, shop.label .. ' Stash', 60, 200000, false,
            { [Config.JobName] = 0 })
    end
end)

-- Boss menu data
lib.callback.register('dusa_mechanic:getSocietyBalance', function(src)
    if not HasJob(src) then return 0 end
    local r = MySQL.scalar.await('SELECT balance FROM dusa_mechanic_society WHERE name = ?', { Config.SocietyAccount })
    return r or 0
end)

RegisterNetEvent('dusa_mechanic:withdrawSociety', function(amount)
    local src = source
    if not HasJob(src) then return end
    local player = GetPlayer(src)
    if not player.PlayerData.job.isboss then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only boss can withdraw' })
        return
    end
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    local bal = MySQL.scalar.await('SELECT balance FROM dusa_mechanic_society WHERE name = ?', { Config.SocietyAccount }) or 0
    if amount > bal then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Not enough funds' })
        return
    end
    MySQL.update('UPDATE dusa_mechanic_society SET balance = balance - ? WHERE name = ?',
        { amount, Config.SocietyAccount })
    player.Functions.AddMoney('cash', amount, 'mech-society-withdraw')
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Withdrew $%s'):format(amount) })
    LogAction(src, 'society_withdraw', nil, amount)
end)

RegisterNetEvent('dusa_mechanic:depositSociety', function(amount)
    local src = source
    if not HasJob(src) then return end
    local player = GetPlayer(src)
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    if (player.PlayerData.money.cash or 0) < amount then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = Utils.L('no_money', amount) })
        return
    end
    player.Functions.RemoveMoney('cash', amount, 'mech-society-deposit')
    MySQL.update('UPDATE dusa_mechanic_society SET balance = balance + ? WHERE name = ?',
        { amount, Config.SocietyAccount })
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Deposited $%s'):format(amount) })
    LogAction(src, 'society_deposit', nil, amount)
end)
