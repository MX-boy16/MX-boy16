Config = {}

-- =========================================================
-- GENERAL
-- =========================================================
Config.Debug              = false
Config.JobName            = 'mechanic'          -- QBX job name
Config.UseSociety         = true                -- Send money to society account
Config.SocietyAccount     = 'mechanic'          -- ox_banking / qbx society id
Config.RequireJob         = true                -- Must be on duty to use lifts
Config.AllowOffDutyRepair = false               -- Can off-duty mechs use lifts?

-- Vehicle classes blocked from interacting (police etc.). Empty = allow all
Config.BlockedClasses     = { 18 } -- emergency

-- =========================================================
-- ITEMS REQUIRED (ox_inventory item names)
-- =========================================================
Config.Items = {
    repairkit  = 'repairkit',
    advrepair  = 'advancedrepairkit',
    cleankit   = 'cleaningkit',
    nos        = 'nos_bottle',
    nosrefill  = 'nos_refill',
    scanner    = 'diagnostic_scanner',
    towrope    = 'towrope',
}

-- =========================================================
-- PRICING ($)
-- =========================================================
Config.Prices = {
    -- Body parts (per 1.0 damage point, scaled)
    body            = 250,
    engine          = 400,
    -- Per tire / window
    tire            = 150,
    window          = 75,
    -- Full restore
    fullRepair      = 3500,
    fullClean       = 250,
    -- Tuning (per level)
    engineUpgrade   = { [1] = 2500, [2] = 5000, [3] = 8500, [4] = 14000 },
    brakeUpgrade    = { [1] = 1500, [2] = 3000, [3] = 6000 },
    transUpgrade    = { [1] = 2500, [2] = 5000, [3] = 9000 },
    suspUpgrade     = { [1] = 1500, [2] = 3000, [3] = 5500, [4] = 8000 },
    turbo           = 12000,
    armor           = { [1] = 1500, [2] = 3000, [3] = 4500, [4] = 6000, [5] = 9000 },
    -- Cosmetics
    primaryColor    = 300,
    secondaryColor  = 300,
    pearlColor      = 500,
    wheelColor      = 200,
    wheels          = 2500,
    neons           = 1500,
    xenons          = 600,
    smoke           = 800,
    plateIndex      = 300,
    -- NOS
    nosInstall      = 8000,
    nosRefill       = 1200,
    -- Towing
    towPayout       = { min = 250, max = 600 },
    -- Diagnostic
    scanFee         = 150,
}

-- =========================================================
-- PROGRESS DURATIONS (ms)
-- =========================================================
Config.Durations = {
    repairTire   = 6000,
    repairWindow = 3500,
    repairBody   = 8000,
    repairEngine = 12000,
    fullRepair   = 18000,
    cleaning     = 7000,
    tuning       = 10000,
    cosmetic     = 5000,
    nosInstall   = 12000,
    nosRefill    = 6000,
    scan         = 5000,
    hookTow      = 8000,
}

-- =========================================================
-- NOS SYSTEM
-- =========================================================
Config.NOS = {
    maxFuel       = 100.0,
    drainPerSec   = 12.0,           -- how fast nos depletes while boosting
    boostForce    = 90.0,
    requireItem   = true,           -- require nos_bottle to activate
    key           = 'LSHIFT',       -- activation key
    cooldown      = 600,            -- ms between bursts
}

-- =========================================================
-- MECHANIC SHOPS / LIFTS
-- =========================================================
-- Each shop has a boss zone, vehicle lifts, garage door (optional)
Config.Shops = {
    {
        id    = 'lsc_main',
        label = 'LS Customs - Strawberry',
        blip  = { sprite = 446, color = 5, scale = 0.8 },
        boss  = vector3(-347.21, -133.18, 39.01),
        stash = vector3(-340.99, -129.27, 39.01),
        duty  = vector3(-339.66, -136.06, 39.01),
        garageSpawn = vector4(-356.73, -125.10, 38.69, 250.0),
        lifts = {
            { coords = vector4(-336.10, -136.41, 39.01, 180.0), heading = 180.0 },
            { coords = vector4(-339.93, -136.41, 39.01, 180.0), heading = 180.0 },
            { coords = vector4(-345.66, -136.41, 39.01, 180.0), heading = 180.0 },
        },
        liftProp = 'prop_carlift_01',
    },
    {
        id    = 'lsc_bb',
        label = 'LS Customs - Burton',
        blip  = { sprite = 446, color = 5, scale = 0.8 },
        boss  = vector3(-1146.42, -2000.42, 13.18),
        stash = vector3(-1153.20, -2001.95, 13.18),
        duty  = vector3(-1149.50, -1992.50, 13.18),
        garageSpawn = vector4(-1166.32, -2009.39, 12.81, 132.0),
        lifts = {
            { coords = vector4(-1155.79, -2007.05, 13.18, 137.0), heading = 137.0 },
            { coords = vector4(-1159.32, -2010.21, 13.18, 137.0), heading = 137.0 },
        },
        liftProp = 'prop_carlift_01',
    },
}

-- =========================================================
-- TOW IMPOUND / JOB
-- =========================================================
Config.Tow = {
    vehicleModel = 'flatbed',
    spawnPoint   = vector4(404.31, -1622.69, 28.29, 230.0),
    impound      = vector4(409.66, -1639.32, 29.29, 320.0),
    maxDistance  = 5.0,
}

-- =========================================================
-- DIAGNOSTIC SCANNER
-- =========================================================
Config.Diagnostic = {
    showHidden = true,   -- Shows hidden engine wear, brake wear etc.
}
