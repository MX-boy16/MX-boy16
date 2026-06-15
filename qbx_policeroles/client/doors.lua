-- Hook into ox_doorlock door state changes.
--
-- ox_doorlock exposes a client-side `customCheck` only for doors created in
-- Lua/cfg with a function reference; once a door is registered in DB, that
-- isn't possible. We therefore intercept the keypress / state-change request
-- by listening to ox_doorlock's own `setState` event and re-affirming access.
--
-- We also subscribe to ox_doorlock's "useDoor" event (preferred entrypoint).

local function doorIsGated(doorId)
    for _, d in ipairs(Config.Doors) do
        if tostring(d.doorId) == tostring(doorId) then return d end
    end
    return nil
end

local function hasDoorAccess(doorId)
    return lib.callback.await('qbx_policeroles:doorAccess', false, doorId)
end

-- Listen for ox_doorlock state changes initiated by THIS player.
-- If the door is gated by us and access is denied, immediately re-lock it.
AddEventHandler('ox_doorlock:setState', function(doorId, state, source)
    local pid = GetPlayerServerId(PlayerId())
    if source ~= nil and source ~= pid then return end -- not our action

    local cfg = doorIsGated(doorId)
    if not cfg then return end

    if not Client.data.isPolice then
        Client.Notify(Client.L('not_police'), 'error')
        TriggerServerEvent('qbx_policeroles:logDoorUnlock', doorId, false)
        TriggerServerEvent('ox_doorlock:setState', doorId, 1) -- relock
        return
    end

    if state == 0 then -- attempted unlock
        local allowed = hasDoorAccess(doorId)
        if not allowed then
            Client.Notify(Client.L('door_locked'), 'error')
            TriggerServerEvent('qbx_policeroles:logDoorUnlock', doorId, false)
            TriggerServerEvent('ox_doorlock:setState', doorId, 1) -- snap back to locked
        else
            TriggerServerEvent('qbx_policeroles:logDoorUnlock', doorId, true)
        end
    end
end)

-- Listen for the "tried to use a locked door" hint event ox_doorlock fires.
AddEventHandler('ox_doorlock:usingDoor', function(doorId)
    local cfg = doorIsGated(doorId)
    if not cfg then return end
    if not Client.data.isPolice then
        Client.Notify(cfg.label .. ': ' .. Client.L('door_locked'), 'error')
        return
    end
    local allowed = hasDoorAccess(doorId)
    if not allowed then
        Client.Notify(cfg.label .. ': ' .. Client.L('door_locked'), 'error')
    end
end)
