--[[ gym_system - client/stats.lua
     Holds the local copy of the player's gym stats and applies them
     to the in-game character (sprint, melee, stamina & visible muscle). ]]

GymStats = { strength = 0, stamina = 0, punch = 0, muscle = 0,
             xp = { strength = 0, stamina = 0, punch = 0, muscle = 0 } }

local activeBuffs = { sprint = false, sprintUntil = 0 }

-- Level (0-100) -> normalized 0..1
local function norm(level)
    return math.min(level / Config.MaxLevel, 1.0)
end

--- Push a temporary sprint/energy buff (used by pre-workout & steroids)
function ApplySprintBuff(durationSeconds)
    activeBuffs.sprint = true
    activeBuffs.sprintUntil = GetGameTimer() + (durationSeconds * 1000)
    lib.notify({ title = 'Gym', description = 'You feel a surge of energy!', type = 'success' })
end

--- Apply every stat to the current ped. Safe to call repeatedly.
function ApplyGymStats()
    local ped = cache.ped or PlayerPedId()
    local playerId = PlayerId()

    -- STAMINA -> sprint speed + stamina stat + restore
    local stamina = norm(GymStats.stamina)
    local sprintMult = 1.0 + (Config.Effects.maxSprintMultiplier - 1.0) * stamina
    if activeBuffs.sprint and GetGameTimer() < activeBuffs.sprintUntil then
        sprintMult = Config.Effects.maxSprintMultiplier
    end
    SetRunSprintMultiplierForPlayer(playerId, math.min(sprintMult, 1.49))
    StatSetInt(`MP0_STAMINA`, math.floor(stamina * 100), true)
    RestorePlayerStamina(playerId, 1.0)

    -- STRENGTH + PUNCH -> melee / unarmed damage
    local power = math.max(norm(GymStats.strength), norm(GymStats.punch))
    local combined = (norm(GymStats.strength) + norm(GymStats.punch)) / 2
    local meleeMult = 1.0 + (Config.Effects.maxMeleeMultiplier - 1.0) * math.max(power, combined)
    SetPlayerMeleeWeaponDamageModifier(playerId, meleeMult)
    StatSetInt(`MP0_STRENGTH`, math.floor(norm(GymStats.strength) * 100), true)

    -- MUSCLE -> visible freemode body tone
    if Config.Effects.applyMuscleVisual then
        local tone = math.floor(norm(GymStats.muscle) * 100)
        StatSetInt(`MP0_MUSCLE_TONE`, tone, true)
        StatSetInt(`MP0_SHOOTING_ABILITY`, math.floor(norm(GymStats.strength) * 100), true)
        -- nudge the appearance to refresh the body mesh on freemode peds
        if IsPedModel(ped, `mp_m_freemode_01`) or IsPedModel(ped, `mp_f_freemode_01`) then
            SetPedComponentVariation(ped, 11, GetPedDrawableVariation(ped, 11),
                GetPedTextureVariation(ped, 11), GetPedPaletteVariation(ped, 11))
        end
    end
end

--- Server -> client: full sync of stats
RegisterNetEvent('gym:client:syncStats', function(stats)
    if not stats then return end
    GymStats = stats
    ApplyGymStats()
end)

-- Re-apply on (re)spawn so death / model changes never wipe the buffs.
CreateThread(function()
    local lastPed = 0
    while true do
        local ped = PlayerPedId()
        if ped ~= lastPed and not IsEntityDead(ped) then
            lastPed = ped
            Wait(500)
            ApplyGymStats()
        end
        -- expire sprint buff
        if activeBuffs.sprint and GetGameTimer() >= activeBuffs.sprintUntil then
            activeBuffs.sprint = false
            ApplyGymStats()
        end
        Wait(1000)
    end
end)

-- Request stats once the player session is ready.
RegisterNetEvent('qbx_core:client:onPlayerLoaded', function()
    Wait(1500)
    TriggerServerEvent('gym:server:requestStats')
end)

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() and LocalPlayer.state.isLoggedIn then
        Wait(1000)
        TriggerServerEvent('gym:server:requestStats')
    end
end)
