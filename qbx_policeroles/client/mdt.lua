-- NUI bridge for the MDT tablet UI.
-- Opens the HTML tablet, forwards NUI calls to ox_lib server callbacks.

local cb = lib.callback.await
local isOpen = false

local function openTablet()
    if isOpen then return end
    local self = cb('qbx_policeroles:mdt:openSelf', false)
    if not self then
        Client.Notify(Client.L('not_police'), 'error')
        return
    end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', self = self })
end

local function closeTablet()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNetEvent('qbx_policeroles:openMDT', openTablet)

-- ESC handling is done client-side in JS via NUI callback below.

-- ---------------- NUI callbacks ----------------

RegisterNUICallback('close', function(_, resp)
    closeTablet(); resp({ ok = true })
end)

RegisterNUICallback('toggleDuty', function(_, resp)
    TriggerServerEvent('qbx_policeroles:requestSync')
    ExecuteCommand(Config.DutyCommand or 'duty')
    resp({ ok = true })
end)

local function wrap(cbName, ...)
    local args = { ... }
    return function(data, resp)
        -- merge data into args list
        local res = lib.callback.await(cbName, false, table.unpack(args), data)
        resp(res)
    end
end

RegisterNUICallback('searchCitizens', function(data, resp)
    resp(cb('qbx_policeroles:mdt:searchCitizens', false, data.q))
end)

RegisterNUICallback('citizenDossier', function(data, resp)
    resp(cb('qbx_policeroles:mdt:citizenDossier', false, data.cid))
end)

RegisterNUICallback('searchVehicles', function(data, resp)
    resp(cb('qbx_policeroles:mdt:searchVehicles', false, data.q))
end)

RegisterNUICallback('issueLicense', function(data, resp)
    local ok, err = cb('qbx_policeroles:mdt:issueLicense', false, data.cid, data.class)
    resp({ ok = ok, err = err })
end)

RegisterNUICallback('revokeLicense', function(data, resp)
    local ok = cb('qbx_policeroles:mdt:revokeLicense', false, data.cid, data.class)
    resp({ ok = ok })
end)

RegisterNUICallback('createRecord', function(data, resp)
    local ok, err, penalty = cb('qbx_policeroles:mdt:createRecord', false, data)
    resp({ ok = ok, err = err, penalty = penalty })
end)

RegisterNUICallback('resolveRecord', function(data, resp)
    resp({ ok = cb('qbx_policeroles:mdt:resolveRecord', false, data.id) })
end)

RegisterNUICallback('listBolos', function(_, resp)
    resp(cb('qbx_policeroles:mdt:listBolos', false))
end)

RegisterNUICallback('createBolo', function(data, resp)
    resp({ ok = cb('qbx_policeroles:mdt:createBolo', false, data) })
end)

RegisterNUICallback('clearBolo', function(data, resp)
    resp({ ok = cb('qbx_policeroles:mdt:clearBolo', false, data.id) })
end)

-- Role management (bridged from the same callbacks that /policeadmin uses)
RegisterNUICallback('getRoleDefinitions', function(_, resp)
    resp(cb('qbx_policeroles:getRoleDefinitions', false))
end)

RegisterNUICallback('getOnlineOfficers', function(_, resp)
    resp(cb('qbx_policeroles:getOnlineOfficers', false))
end)

RegisterNUICallback('assignRole', function(data, resp)
    local ok, err = cb('qbx_policeroles:assignRole', false, data.target, data.role)
    resp({ ok = ok, err = err })
end)

RegisterNUICallback('removeRole', function(data, resp)
    resp({ ok = cb('qbx_policeroles:removeRole', false, data.target, data.role) })
end)

RegisterNUICallback('createRole', function(data, resp)
    local ok, err = cb('qbx_policeroles:createRole', false, data)
    resp({ ok = ok, err = err })
end)

RegisterNUICallback('deleteRole', function(data, resp)
    local ok, err = cb('qbx_policeroles:deleteRole', false, data.name)
    resp({ ok = ok, err = err })
end)

-- Allow ESC to close
RegisterCommand('+mdtClose', closeTablet, false)
RegisterKeyMapping('+mdtClose', 'Close MDT tablet', 'keyboard', 'ESCAPE')

_ = wrap -- silence luac
