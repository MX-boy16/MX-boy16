-- Register role-gated stashes with ox_inventory at server startup.
-- We register each stash globally, then gate ACCESS via a server event
-- that opens the stash only after a role check passes.

local function registerStashes()
    for _, s in ipairs(Config.Stashes) do
        exports.ox_inventory:RegisterStash(
            s.id,
            s.label,
            s.slots or 50,
            s.weight or 100000,
            false, -- owner: false = shared
            nil,   -- groups: nil so anyone *passing our check* can open
            s.coords
        )
    end
    print(('^2[qbx_policeroles]^7 Registered %d role-gated stashes.'):format(#Config.Stashes))
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    -- Defer a tick so ox_inventory exports are ready
    SetTimeout(500, registerStashes)
end)

-- Server-side gated open. Client requests open, we verify, then we instruct
-- ox_inventory to force-open it for that source.
RegisterNetEvent('qbx_policeroles:requestStash', function(stashId)
    local src = source
    local cfg = Permissions.GetStashConfig(stashId)
    if not cfg then return end

    if not Permissions.HasAccess(src, cfg.required or {}) then
        TriggerClientEvent('qbx_policeroles:notify', src, 'stash_locked', 'error')
        return
    end

    if not Roles.IsOnDuty(src) then
        TriggerClientEvent('qbx_policeroles:notify', src, 'must_be_on_duty', 'error')
        return
    end

    TriggerClientEvent('qbx_policeroles:openStash', src, stashId)
end)
