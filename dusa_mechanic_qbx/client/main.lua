-- =========================================================
-- dusa_mechanic_qbx :: Client Main
-- =========================================================

Mechanic = {
    activeShop   = nil,
    activeVeh    = nil,
    inMenu       = false,
    nuiOpen      = false,
    onDuty       = false,
    isMechanic   = false,
    currentLift  = nil,
}

CreateThread(function()
    -- wait until ox_lib & qbx ready
    while not exports.qbx_core or not lib do Wait(250) end

    -- Cache job state
    local pd = exports.qbx_core:GetPlayerData()
    if pd and pd.job then
        Mechanic.isMechanic = pd.job.name == Config.JobName
        Mechanic.onDuty     = pd.job.onduty
    end

    -- Blips
    for _, shop in ipairs(Config.Shops) do
        local b = AddBlipForCoord(shop.boss.x, shop.boss.y, shop.boss.z)
        SetBlipSprite(b, shop.blip.sprite or 446)
        SetBlipColour(b, shop.blip.color or 5)
        SetBlipScale(b, shop.blip.scale or 0.8)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(shop.label)
        EndTextCommandSetBlipName(b)
    end
end)

-- Sync job updates
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    Mechanic.isMechanic = job.name == Config.JobName
    Mechanic.onDuty     = job.onduty
end)
RegisterNetEvent('qbx_core:client:onJobUpdate', function(job)
    Mechanic.isMechanic = job.name == Config.JobName
    Mechanic.onDuty     = job.onduty
end)
RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    Mechanic.onDuty = duty
end)

-- =========================================================
-- ox_target: Boss / Stash / Duty zones for each shop
-- =========================================================
CreateThread(function()
    for _, shop in ipairs(Config.Shops) do
        -- Boss menu
        exports.ox_target:addSphereZone({
            coords = shop.boss,
            radius = 0.8,
            debug  = Config.Debug,
            options = {
                {
                    name   = 'dusa_boss_' .. shop.id,
                    icon   = 'fas fa-briefcase',
                    label  = Utils.L('boss_menu'),
                    canInteract = function() return Mechanic.isMechanic end,
                    onSelect = function() OpenBossMenu(shop) end,
                }
            }
        })
        -- Duty toggle
        exports.ox_target:addSphereZone({
            coords = shop.duty,
            radius = 0.8,
            debug  = Config.Debug,
            options = {
                {
                    name   = 'dusa_duty_' .. shop.id,
                    icon   = 'fas fa-clipboard-list',
                    label  = Utils.L('toggle_duty'),
                    canInteract = function() return Mechanic.isMechanic end,
                    onSelect = function() TriggerServerEvent('dusa_mechanic:toggleDuty') end,
                }
            }
        })
        -- Stash
        exports.ox_target:addSphereZone({
            coords = shop.stash,
            radius = 0.8,
            debug  = Config.Debug,
            options = {
                {
                    name   = 'dusa_stash_' .. shop.id,
                    icon   = 'fas fa-box',
                    label  = Utils.L('open_stash'),
                    canInteract = function() return Mechanic.isMechanic end,
                    onSelect = function()
                        exports.ox_inventory:openInventory('stash', 'dusa_mech_' .. shop.id)
                    end,
                }
            }
        })
    end
end)

-- =========================================================
-- Boss Menu (ox_lib context)
-- =========================================================
function OpenBossMenu(shop)
    local balance = lib.callback.await('dusa_mechanic:getSocietyBalance', false)
    lib.registerContext({
        id    = 'dusa_boss',
        title = shop.label .. ' - Boss',
        options = {
            { title = ('Society Balance: $%s'):format(balance), icon = 'sack-dollar', disabled = true },
            {
                title = 'Deposit money', icon = 'arrow-down', description = 'Add to society',
                onSelect = function()
                    local input = lib.inputDialog('Deposit', { { type = 'number', label = 'Amount', min = 1 } })
                    if input and input[1] then TriggerServerEvent('dusa_mechanic:depositSociety', input[1]) end
                end
            },
            {
                title = 'Withdraw money', icon = 'arrow-up', description = 'Boss only',
                onSelect = function()
                    local input = lib.inputDialog('Withdraw', { { type = 'number', label = 'Amount', min = 1 } })
                    if input and input[1] then TriggerServerEvent('dusa_mechanic:withdrawSociety', input[1]) end
                end
            },
            {
                title = 'Manage Employees', icon = 'users',
                onSelect = function() OpenEmployeeMenu() end
            },
            {
                title = 'Hire nearest player', icon = 'user-plus',
                onSelect = function()
                    local target, _ = GetNearestPlayer()
                    if target then
                        TriggerServerEvent('dusa_mechanic:hire', GetPlayerServerId(target))
                    else
                        lib.notify({ type = 'error', description = 'No player nearby' })
                    end
                end
            },
        }
    })
    lib.showContext('dusa_boss')
end

function OpenEmployeeMenu()
    local employees = lib.callback.await('dusa_mechanic:getEmployees', false) or {}
    local opts = {}
    for _, emp in ipairs(employees) do
        opts[#opts+1] = {
            title = emp.name,
            description = ('Grade: %s'):format(emp.gradeName),
            icon  = 'user',
            onSelect = function()
                lib.registerContext({
                    id    = 'dusa_emp_actions',
                    title = emp.name,
                    menu  = 'dusa_employees',
                    options = {
                        {
                            title = 'Fire', icon = 'user-slash',
                            onSelect = function()
                                TriggerServerEvent('dusa_mechanic:fire', emp.citizenid)
                            end
                        },
                        {
                            title = 'Promote', icon = 'arrow-up',
                            onSelect = function()
                                local input = lib.inputDialog('Promote',
                                    { { type = 'number', label = 'New Grade', min = 0, max = 10 } })
                                if input and input[1] then
                                    TriggerServerEvent('dusa_mechanic:promote', emp.citizenid, input[1])
                                end
                            end
                        },
                    }
                })
                lib.showContext('dusa_emp_actions')
            end
        }
    end
    if #opts == 0 then
        opts[1] = { title = 'No employees', disabled = true }
    end
    lib.registerContext({ id = 'dusa_employees', title = 'Employees', menu = 'dusa_boss', options = opts })
    lib.showContext('dusa_employees')
end

function GetNearestPlayer()
    local players = GetActivePlayers()
    local me = PlayerPedId()
    local myCoords = GetEntityCoords(me)
    local closest, dist = nil, 5.0
    for _, pid in ipairs(players) do
        local ped = GetPlayerPed(pid)
        if ped ~= me then
            local d = #(GetEntityCoords(ped) - myCoords)
            if d < dist then closest, dist = pid, d end
        end
    end
    return closest, dist
end

-- =========================================================
-- Helper: vehicle near player
-- =========================================================
function GetClosestVehicle(radius)
    radius = radius or 5.0
    local coords = GetEntityCoords(PlayerPedId())
    local veh = lib.getClosestVehicle(coords, radius, false)
    return veh
end

function GetVehiclePlate(veh)
    if not veh or veh == 0 then return nil end
    return string.gsub(GetVehicleNumberPlateText(veh), '%s+', '')
end

function CanWorkOnVehicle()
    if not Config.RequireJob then return true end
    if Mechanic.isMechanic and (Mechanic.onDuty or Config.AllowOffDutyRepair) then return true end
    return false
end
