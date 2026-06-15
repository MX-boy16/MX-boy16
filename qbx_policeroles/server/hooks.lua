-- ox_inventory hook: block weapon (and optionally ammo) purchases from any
-- shop (ammunation, vendors, etc.) unless the buyer holds the matching
-- weapon license class.
--
-- 'buyItem' hook fires when a player buys from an ox_inventory shop.
-- Returning false cancels the transaction.

local function buildItemFilter()
    local filter = {}
    for itemName, class in pairs(Config.WeaponClasses or {}) do
        local isAmmo = itemName:sub(1, 5):lower() == 'ammo-'
        if not isAmmo or Config.GateAmmo then
            -- ox_inventory normalises item names to lowercase; include all variants.
            filter[itemName]         = true
            filter[itemName:lower()] = true
            filter[itemName:upper()] = true
            _ = class
        end
    end
    return filter
end

CreateThread(function()
    -- Defer slightly so ox_inventory is loaded
    Wait(1000)

    local itemFilter = buildItemFilter()

    local hookId = exports.ox_inventory:registerHook('buyItem', function(payload)
        local src = payload.source
        if not src then return end

        local itemName = (payload.itemName or ''):upper() ~= '' and payload.itemName or nil
        if not itemName then return end

        local class = Config.WeaponClasses[itemName] or Config.WeaponClasses[itemName:upper()] or Config.WeaponClasses[itemName:lower()]
        if not class then return end -- not a gated item

        local p = exports.qbx_core:GetPlayer(src)
        if not p then return false end

        -- On-duty police bypass the license check at shops (configurable).
        if Config.PoliceBypassLicense and Roles.IsPolice(src) and Roles.IsOnDuty(src) then
            return
        end

        if Licenses.HasActive(p.PlayerData.citizenid, class) then
            return -- allow
        end

        local label = (Config.LicenseClasses[class] and Config.LicenseClasses[class].label) or ('Class ' .. tostring(class))
        TriggerClientEvent('ox_lib:notify', src, {
            title       = 'Purchase Denied',
            description = ('You need a %s to purchase this. Visit the police MDT.'):format(label),
            type        = 'error',
            duration    = 6000,
            position    = 'top',
            icon        = 'gun',
        })

        return false
    end, {
        itemFilter = itemFilter,
    })

    if not hookId then
        print('^1[qbx_policeroles]^7 Failed to register ox_inventory buyItem hook.')
    else
        local n = 0
        for _ in pairs(itemFilter) do n = n + 1 end
        print(('^2[qbx_policeroles]^7 Weapon license hook armed — gating %d items.'):format(n))
    end
end)
