-- Adds ox_target zones to each role-gated stash so officers can interact.
-- Server gates the open and confirms via 'qbx_policeroles:openStash'.

CreateThread(function()
    if not Config.Stashes or #Config.Stashes == 0 then return end

    for _, s in ipairs(Config.Stashes) do
        if s.coords then
            exports.ox_target:addSphereZone({
                coords = s.coords,
                radius = 0.6,
                debug  = false,
                options = {
                    {
                        name   = 'qbx_policeroles_stash_' .. s.id,
                        label  = ('Open: %s'):format(s.label),
                        icon   = 'fas fa-box',
                        canInteract = function()
                            -- Hide entirely for non-police
                            return Client.data.isPolice
                        end,
                        onSelect = function()
                            TriggerServerEvent('qbx_policeroles:requestStash', s.id)
                        end,
                    },
                },
            })
        end
    end
end)

RegisterNetEvent('qbx_policeroles:openStash', function(stashId)
    -- Server already verified access; just open it via ox_inventory.
    exports.ox_inventory:openInventory('stash', stashId)
end)
