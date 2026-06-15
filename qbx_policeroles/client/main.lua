-- Client cache + notification helper + lifecycle.
Client = {
    data = {
        roles       = {},
        permissions = {},
        isPolice    = false,
        isLeader    = false,
        canManage   = false,
        onDuty      = false,
    },
}

local locale = {}

local function loadLocale()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'locales/en.json')
    if raw then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then locale = data end
    end
end

function Client.L(key, ...)
    local s = locale[key] or key
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, s, ...)
        if ok then return formatted end
    end
    return s
end

function Client.Notify(text, type_)
    if Config.Notify == 'ox' then
        lib.notify({ title = 'Police', description = text, type = type_ or 'inform' })
    else
        TriggerEvent('QBCore:Notify', text, type_ or 'primary')
    end
end

RegisterNetEvent('qbx_policeroles:sync', function(data)
    if type(data) ~= 'table' then return end
    Client.data = data
end)

RegisterNetEvent('qbx_policeroles:notify', function(key, type_)
    Client.Notify(Client.L(key), type_)
end)

RegisterNetEvent('qbx_policeroles:notifyFormat', function(key, args, type_)
    Client.Notify(Client.L(key, table.unpack(args or {})), type_)
end)

RegisterNetEvent('qbx_policeroles:showMyRoles', function()
    local d = Client.data
    if not d.isPolice then
        Client.Notify(Client.L('not_police'), 'error')
        return
    end
    local lines = { 'On Duty: ' .. (d.onDuty and 'YES' or 'NO') }
    if #(d.roles or {}) == 0 then
        lines[#lines + 1] = '*No custom roles assigned*'
    else
        for _, r in ipairs(d.roles) do lines[#lines + 1] = '• ' .. r end
    end
    lib.notify({
        title       = 'Your Police Roles',
        description = table.concat(lines, '\n'),
        type        = 'inform',
        duration    = 7000,
    })
end)

CreateThread(function()
    loadLocale()
    while not LocalPlayer.state.isLoggedIn do Wait(500) end
    TriggerServerEvent('qbx_policeroles:requestSync')
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('qbx_policeroles:requestSync')
end)

AddEventHandler('QBCore:Client:OnJobUpdate', function()
    TriggerServerEvent('qbx_policeroles:requestSync')
end)

if Config.RoleRefreshInterval and Config.RoleRefreshInterval > 0 then
    CreateThread(function()
        while true do
            Wait(Config.RoleRefreshInterval)
            TriggerServerEvent('qbx_policeroles:requestSync')
        end
    end)
end
