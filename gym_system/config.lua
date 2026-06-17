Config = {}

-----------------------------------------------------------------------
-- GENERAL
-----------------------------------------------------------------------
Config.Debug = false                 -- draw zone markers + extra prints
Config.Account = 'bank'              -- 'bank' or 'cash' for all gym purchases
Config.MaxLevel = 100               -- max level for every stat (0-100)

-- Notifications use ox_lib (lib.notify) automatically.

-----------------------------------------------------------------------
-- MEMBERSHIP
-- Access to the gym equipment requires either:
--   * an active paid membership (bought at the front desk ped), OR
--   * owning / having redeemed the gym membership CARD item.
-----------------------------------------------------------------------
Config.Membership = {
    -- Membership lasts this many real-time days. The user asked for
    -- "30 in-game days" -> set to 30. Change freely.
    durationDays = 30,
    price = 5000,                   -- price of a 30 day membership at the desk

    -- Gym membership CARD item (a premium perk).
    cardItem = 'gym_membercard',
    cardPrice = 50000,              -- price if you also sell the card at the desk
    sellCardAtDesk = true,          -- allow buying the card from the desk ped
    -- When the card is REDEEMED (used from inventory):
    cardGrantsLifetime = true,      -- true = permanent membership, false = grants durationDays
    -- Simply OWNING the card in inventory also grants access (no redeem needed):
    ownershipGrantsAccess = true,
}

-----------------------------------------------------------------------
-- FRONT DESK CLERK (membership ped)
-- Set ped coords to a spot inside YOUR gym MLO.
-----------------------------------------------------------------------
Config.Clerk = {
    enabled = true,
    model = 's_m_y_dealer_01',
    coords = vector4(-1204.43, -1568.12, 4.66, 124.0), -- Muscle Sands desk (CHANGE to your MLO)
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    blip = {
        enabled = true,
        sprite = 311,
        color = 2,
        scale = 0.8,
        label = 'Gym'
    }
}

-----------------------------------------------------------------------
-- PROGRESSION
-- Each stat is leveled 0 -> Config.MaxLevel by gaining XP.
-- xpPerLevel scales: needed = baseXp + (level * levelStep)
-----------------------------------------------------------------------
Config.Progress = {
    baseXp = 100,
    levelStep = 25,
    sessionCooldown = 2000,         -- ms between training reps (anti-spam)
}

-- How the levels translate to in-game power (at MAX level).
Config.Effects = {
    -- Sprint run speed multiplier from STAMINA (native cap is 1.49).
    maxSprintMultiplier = 1.49,
    -- Melee/unarmed damage multiplier from STRENGTH + PUNCH at max.
    maxMeleeMultiplier = 4.0,
    -- Visible freemode muscle tone (0-100). Driven by MUSCLE stat.
    applyMuscleVisual = true,
}

-----------------------------------------------------------------------
-- EQUIPMENT
-- Add as many stations as your MLO has. type drives which stat grows.
-- types: 'stamina' | 'strength' | 'punch' | 'muscle'
-- Coords are box-zone centers; tweak size/rotation per prop.
-----------------------------------------------------------------------
Config.Equipment = {
    {
        label = 'Treadmill',
        type = 'stamina',
        icon = 'fa-solid fa-person-running',
        coords = vector3(-1201.95, -1567.0, 4.66),
        size = vec3(1.2, 1.6, 2.0),
        rotation = 305.0,
        anim = { dict = 'amb@world_human_jog_standing@male@base', clip = 'base' },
        xp = 15,
    },
    {
        label = 'Bench Press',
        type = 'strength',
        icon = 'fa-solid fa-dumbbell',
        coords = vector3(-1198.0, -1570.0, 4.66),
        size = vec3(1.6, 2.0, 1.5),
        rotation = 35.0,
        anim = { dict = 'amb@world_human_muscle_free_weights@male@barbell@base', clip = 'base' },
        xp = 18,
    },
    {
        label = 'Punching Bag',
        type = 'punch',
        icon = 'fa-solid fa-hand-fist',
        coords = vector3(-1206.0, -1571.0, 4.66),
        size = vec3(1.2, 1.2, 2.2),
        rotation = 35.0,
        anim = { dict = 'melee@large_wpn@streamed_core', clip = 'ground_attack_on_spot' },
        skillcheck = true,             -- punching bag uses an ox_lib skill check
        xp = 20,
    },
    {
        label = 'Pull-Up Bar',
        type = 'muscle',
        icon = 'fa-solid fa-person',
        coords = vector3(-1209.0, -1567.0, 4.66),
        size = vec3(1.4, 1.4, 2.4),
        rotation = 35.0,
        anim = { dict = 'amb@world_human_sit_ups@male@base', clip = 'base' },
        xp = 16,
    },
}

-----------------------------------------------------------------------
-- CONSUMABLE SUPPLEMENTS & STEROIDS
-- Each item grants permanent XP to stats + optional temporary buffs.
-- All values are XP unless noted.
-----------------------------------------------------------------------
Config.Items = {
    -- PROTEIN POWDER (3 flavours) -> muscle + strength growth
    ['protein_choco']      = { label = 'Protein (Chocolate)',  grant = { muscle = 40, strength = 20 } },
    ['protein_vanilla']    = { label = 'Protein (Vanilla)',    grant = { muscle = 40, strength = 20 } },
    ['protein_strawberry'] = { label = 'Protein (Strawberry)', grant = { muscle = 40, strength = 20 } },

    -- PRE-WORKOUT (3 flavours) -> stamina growth + temporary sprint/energy buff
    ['preworkout_choco']      = { label = 'Pre-Workout (Chocolate)',  grant = { stamina = 35 }, buff = { sprint = true, duration = 180 } },
    ['preworkout_vanilla']    = { label = 'Pre-Workout (Vanilla)',    grant = { stamina = 35 }, buff = { sprint = true, duration = 180 } },
    ['preworkout_strawberry'] = { label = 'Pre-Workout (Strawberry)', grant = { stamina = 35 }, buff = { sprint = true, duration = 180 } },

    -- CREATINE -> strength + muscle growth
    ['creatine']           = { label = 'Creatine', grant = { strength = 45, muscle = 25 } },

    -- INJECTABLE STEROIDS -> huge gains, with a small health drawback
    ['steroids']           = {
        label = 'Injectable Steroids',
        grant = { strength = 120, muscle = 90, punch = 60 },
        buff = { sprint = true, duration = 120 },
        sideEffect = { healthDrain = 15 }, -- HP lost on inject (risk/reward)
        injectAnim = true,
    },
}

-- Eat/inject animation timing (ms)
Config.ConsumeTime = 5000

-----------------------------------------------------------------------
-- SUPPLEMENT MIXING SYSTEM
-- Protein / Pre-Workout / Creatine now come as BAGS (start at 100%).
-- You mix a bag + water into a GYM BOTTLE, then drink it for a boost.
-----------------------------------------------------------------------
Config.Mix = {
    waterItem = 'water',        -- existing ox_inventory water item name
    startPercent = 100,          -- a fresh bag starts at 100%
    boostDuration = 120,         -- drink boost length in seconds (2 min)
    boostMultiplier = 2.0,       -- training XP multiplier while boosted

    -- Empty gym bottles you can mix into.
    bottles = {
        gym_bottle_small = { label = 'Small Gym Bottle', water = 1, productPct = 10 },
        gym_bottle_big   = { label = 'Big Gym Bottle',   water = 2, productPct = 20 },
    },

    -- Bags that can be mixed (these are the supplement powders).
    bags = {
        protein_choco = true, protein_vanilla = true, protein_strawberry = true,
        preworkout_choco = true, preworkout_vanilla = true, preworkout_strawberry = true,
        creatine = true,
    },
}

-----------------------------------------------------------------------
-- FRONT DESK SHOP
-- Sold at the clerk ped. Bags are added with 100% (durability metadata).
-----------------------------------------------------------------------
Config.Shop = {
    { item = 'protein_choco',         label = 'Protein Bag (Chocolate)',     price = 800,  bag = true },
    { item = 'protein_vanilla',       label = 'Protein Bag (Vanilla)',       price = 800,  bag = true },
    { item = 'protein_strawberry',    label = 'Protein Bag (Strawberry)',    price = 800,  bag = true },
    { item = 'preworkout_choco',      label = 'Pre-Workout Bag (Chocolate)', price = 1000, bag = true },
    { item = 'preworkout_vanilla',    label = 'Pre-Workout Bag (Vanilla)',   price = 1000, bag = true },
    { item = 'preworkout_strawberry', label = 'Pre-Workout Bag (Strawberry)',price = 1000, bag = true },
    { item = 'creatine',              label = 'Creatine Bag',                price = 1200, bag = true },
    { item = 'gym_bottle_small',      label = 'Small Gym Bottle',            price = 250 },
    { item = 'gym_bottle_big',        label = 'Big Gym Bottle',              price = 400 },
    { item = 'steroids',              label = 'Injectable Steroids',         price = 5000 },
}
