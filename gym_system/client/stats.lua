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

    -- MUSCLE -> visible freemode body growth (more jacked the more you train)
    if Config.Muscle.enabled then
        ApplyMuscle(ped)
    end
end

--- Apply the visible muscle/body growth to a freemode ped.
function ApplyMuscle(ped)
    ped = ped or cache.ped
    local mNorm = math.min(GymStats.muscle / Config.Muscle.fullAtLevel, 1.0)
    local tone = math.floor(mNorm * Config.Muscle.maxTone)

    -- muscle tone + strength stats drive the body shape
    StatSetInt(`MP0_MUSCLE_TONE`, tone, true)
    StatSetInt(`MP0_STRENGTH`, math.floor(norm(GymStats.strength) * 100), true)
    StatSetInt(`MP0_SHOOTING_ABILITY`, tone, true)
    StatSetInt(`MP0_STAMINA`, math.floor(norm(GymStats.stamina) * 100), true)

    if not (IsPedModel(ped, `mp_m_freemode_01`) or IsPedModel(ped, `mp_f_freemode_01`)) then
        return -- body morph only works on freemode peds
    end

    -- Push the heritage "muscle" body morph slider toward max as muscle grows.
    -- _SET_PED_HEAD_BLEND_DATA shape/skin blend; muscle uses the body via face feature is N/A,
    -- so we re-assert the torso/legs components which forces the engine to re-evaluate the
    -- muscle morph applied from the stat above.
    if Config.Muscle.applyBodyMorph then
        SetPedComponentVariation(ped, 3, GetPedDrawableVariation(ped, 3), GetPedTextureVariation(ped, 3), GetPedPaletteVariation(ped, 3)) -- arms/torso
        SetPedComponentVariation(ped, 4, GetPedDrawableVariation(ped, 4), GetPedTextureVariation(ped, 4), GetPedPaletteVariation(ped, 4)) -- legs
        SetPedComponentVariation(ped, 11, GetPedDrawableVariation(ped, 11), GetPedTextureVariation(ped, 11), GetPedPaletteVariation(ped, 11)) -- jacket/top
    end
    -- ensure the muscle stat is actually committed to the ped
    UpdatePedVariation(ped, false, true, true, true, false)
end

--- Server -> client: full sync of stats
RegisterNetEvent('gym:client:syncStats', function(stats)
    if not stats then return end
    GymStats = stats
    ApplyGymStats()
end)

-- Re-apply on (re)spawn so death / model changes never wipe the buffs,
-- and periodically re-assert the muscle so clothing/skin menus can't erase it.
CreateThread(function()
    local lastPed = 0
    local lastMuscle = 0
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
        -- periodic muscle re-assert
        if Config.Muscle.enabled and (GetGameTimer() - lastMuscle) >= Config.Muscle.reapplyMs then
            lastMuscle = GetGameTimer()
            if not IsEntityDead(ped) then ApplyMuscle(ped) end
        end
        Wait(1000)
    end
end)

-- Re-apply muscle after popular clothing / appearance resources reload the skin
-- (otherwise changing clothes resets the body to default).
for _, ev in ipairs({
    'illenium-appearance:client:reloadSkin',
    'qb-clothing:client:loadPlayerClothing',
    'qbx_clothing:client:loadPlayerClothes',
    'fivem-appearance:reload',
    'skinchanger:loadSkin',
    'clothing:client:reloadSkin',
}) do
    AddEventHandler(ev, function()
        SetTimeout(800, function() ApplyGymStats() end)
    end)
end

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
