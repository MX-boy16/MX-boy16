--[[ gym_system - client/main.lua
     Clerk ped, membership menu, equipment targets & training logic. ]]

local clerkPed = nil
local lastRep = 0

-----------------------------------------------------------------------
-- HELPERS
-----------------------------------------------------------------------
local function fmtMoney(n)
    return ('$%s'):format(tostring(n):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', ''))
end

local function xpNeeded(level)
    return Config.Progress.baseXp + (level * Config.Progress.levelStep)
end

-----------------------------------------------------------------------
-- STATS MENU
-----------------------------------------------------------------------
local function showStatsMenu()
    local function row(name, level, xp)
        return ('**%s** — Level %d/%d  (%d/%d XP)'):format(name, level, Config.MaxLevel, xp or 0, xpNeeded(level))
    end
    lib.registerContext({
        id = 'gym_stats_menu',
        title = 'My Gym Stats',
        options = {
            { title = 'Strength',     description = row('Strength', GymStats.strength, GymStats.xp.strength), icon = 'dumbbell', readOnly = true,
              progress = math.floor((GymStats.strength / Config.MaxLevel) * 100) },
            { title = 'Stamina',      description = row('Stamina', GymStats.stamina, GymStats.xp.stamina), icon = 'person-running', readOnly = true,
              progress = math.floor((GymStats.stamina / Config.MaxLevel) * 100) },
            { title = 'Punch Power',  description = row('Punch Power', GymStats.punch, GymStats.xp.punch), icon = 'hand-fist', readOnly = true,
              progress = math.floor((GymStats.punch / Config.MaxLevel) * 100) },
            { title = 'Muscle',       description = row('Muscle', GymStats.muscle, GymStats.xp.muscle), icon = 'person', readOnly = true,
              progress = math.floor((GymStats.muscle / Config.MaxLevel) * 100) },
        }
    })
    lib.showContext('gym_stats_menu')
end

-----------------------------------------------------------------------
-- MEMBERSHIP MENU
-----------------------------------------------------------------------
local function showShopMenu()
    local options = {}
    for _, entry in ipairs(Config.Shop) do
        options[#options + 1] = {
            title = ('%s — %s'):format(entry.label, fmtMoney(entry.price)),
            description = entry.bag and 'Comes as a 100% bag — mix with water in a gym bottle' or nil,
            icon = entry.bag and 'fa-solid fa-bag-shopping' or 'fa-solid fa-bottle-water',
            onSelect = function()
                local ok = lib.callback.await('gym:server:buyShopItem', false, entry.item)
                if ok == true then
                    lib.notify({ title = 'Gym', description = ('Bought %s'):format(entry.label), type = 'success' })
                elseif ok == 'broke' then
                    lib.notify({ title = 'Gym', description = 'You cannot afford this.', type = 'error' })
                elseif ok == 'full' then
                    lib.notify({ title = 'Gym', description = 'Your inventory is full.', type = 'error' })
                else
                    lib.notify({ title = 'Gym', description = 'Purchase failed.', type = 'error' })
                end
            end,
        }
    end
    lib.registerContext({ id = 'gym_shop_menu', title = 'Supplement Shop', menu = 'gym_membership_menu', options = options })
    lib.showContext('gym_shop_menu')
end

local function openMembershipMenu()
    local status = lib.callback.await('gym:server:membershipStatus', false)
    local statusText
    if status.lifetime then
        statusText = 'Active — LIFETIME (membership card)'
    elseif status.active then
        statusText = ('Active — expires in %d day(s)'):format(status.daysLeft)
    else
        statusText = 'No active membership'
    end

    local options = {
        { title = 'Membership Status', description = statusText, icon = 'id-card', readOnly = true },
        { title = ('Buy 30-Day Membership (%s)'):format(fmtMoney(Config.Membership.price)),
          description = 'Unlimited gym access for 30 days', icon = 'cart-shopping',
          onSelect = function()
            local ok = lib.callback.await('gym:server:buyMembership', false)
            if ok == true then
                lib.notify({ title = 'Gym', description = 'Membership purchased! Enjoy your training.', type = 'success' })
            elseif ok == 'broke' then
                lib.notify({ title = 'Gym', description = 'You cannot afford this.', type = 'error' })
            else
                lib.notify({ title = 'Gym', description = 'Purchase failed.', type = 'error' })
            end
          end },
        { title = 'My Gym Stats', description = 'View your progression', icon = 'chart-simple',
          onSelect = showStatsMenu },
        { title = 'Supplement Shop', description = 'Buy protein/pre-workout/creatine bags, bottles & steroids', icon = 'bottle-water',
          onSelect = showShopMenu },
    }

    if Config.Membership.sellCardAtDesk then
        options[#options + 1] = {
            title = ('Buy Membership Card (%s)'):format(fmtMoney(Config.Membership.cardPrice)),
            description = Config.Membership.cardGrantsLifetime and 'Premium card — redeem for LIFETIME access' or 'Premium card — free 30-day access',
            icon = 'star',
            onSelect = function()
                local ok = lib.callback.await('gym:server:buyCard', false)
                if ok == true then
                    lib.notify({ title = 'Gym', description = 'Membership card purchased! Use it from your inventory.', type = 'success' })
                elseif ok == 'broke' then
                    lib.notify({ title = 'Gym', description = 'You cannot afford this.', type = 'error' })
                elseif ok == 'full' then
                    lib.notify({ title = 'Gym', description = 'Your inventory is full.', type = 'error' })
                else
                    lib.notify({ title = 'Gym', description = 'Purchase failed.', type = 'error' })
                end
            end }
    end

    lib.registerContext({ id = 'gym_membership_menu', title = 'Gym Front Desk', options = options })
    lib.showContext('gym_membership_menu')
end

-----------------------------------------------------------------------
-- TRAINING
-----------------------------------------------------------------------
local function doTraining(station)
    if GetGameTimer() - lastRep < Config.Progress.sessionCooldown then
        lib.notify({ title = 'Gym', description = 'Catch your breath first.', type = 'error' })
        return
    end

    local access = lib.callback.await('gym:server:hasAccess', false)
    if not access then
        lib.notify({ title = 'Gym', description = 'You need a membership. Talk to the front desk.', type = 'error' })
        return
    end

    lastRep = GetGameTimer()
    local ped = cache.ped

    if station.anim then
        lib.requestAnimDict(station.anim.dict, 5000)
        TaskPlayAnim(ped, station.anim.dict, station.anim.clip, 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    local success = true
    if station.skillcheck then
        success = lib.skillCheck({ 'easy', 'easy', 'medium' }, { 'w', 'a', 's', 'd' })
    else
        success = lib.progressBar({
            duration = 6000,
            label = ('Training %s...'):format(station.label),
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, combat = true },
        })
    end

    ClearPedTasks(ped)

    if success then
        TriggerServerEvent('gym:server:gainXp', station.type, station.xp)
    else
        lib.notify({ title = 'Gym', description = 'Set cancelled.', type = 'inform' })
    end
end

-----------------------------------------------------------------------
-- SETUP: clerk ped + targets + equipment zones
-----------------------------------------------------------------------
local function spawnClerk()
    if not Config.Clerk.enabled then return end
    lib.requestModel(Config.Clerk.model, 10000)
    clerkPed = CreatePed(4, joaat(Config.Clerk.model), Config.Clerk.coords.x, Config.Clerk.coords.y,
        Config.Clerk.coords.z - 1.0, Config.Clerk.coords.w, false, true)
    SetEntityInvincible(clerkPed, true)
    FreezeEntityPosition(clerkPed, true)
    SetBlockingOfNonTemporaryEvents(clerkPed, true)
    if Config.Clerk.scenario then TaskStartScenarioInPlace(clerkPed, Config.Clerk.scenario, 0, true) end

    exports.ox_target:addLocalEntity(clerkPed, {
        {
            name = 'gym_clerk_membership',
            label = 'Gym Front Desk',
            icon = 'fa-solid fa-dumbbell',
            onSelect = openMembershipMenu,
        }
    })

    if Config.Clerk.blip.enabled then
        local blip = AddBlipForCoord(Config.Clerk.coords.x, Config.Clerk.coords.y, Config.Clerk.coords.z)
        SetBlipSprite(blip, Config.Clerk.blip.sprite)
        SetBlipColour(blip, Config.Clerk.blip.color)
        SetBlipScale(blip, Config.Clerk.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Clerk.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end

local function setupEquipment()
    for i, station in ipairs(Config.Equipment) do
        exports.ox_target:addBoxZone({
            coords = station.coords,
            size = station.size or vec3(1.5, 1.5, 2.0),
            rotation = station.rotation or 0.0,
            debug = Config.Debug,
            options = {
                {
                    name = ('gym_equip_%d'):format(i),
                    label = ('Use %s'):format(station.label),
                    icon = station.icon or 'fa-solid fa-dumbbell',
                    onSelect = function() doTraining(station) end,
                }
            }
        })
    end
end

CreateThread(function()
    spawnClerk()
    setupEquipment()
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and clerkPed and DoesEntityExist(clerkPed) then
        DeleteEntity(clerkPed)
    end
end)

-- expose stats menu for items.lua
exports('showStatsMenu', showStatsMenu)
