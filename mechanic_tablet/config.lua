Config = {}

-- =========================================================
-- TABLET ITEM
-- =========================================================
Config.TabletItem = 'mechanic_tablet'      -- ox_inventory item name
Config.ConsumeOnUse = false                -- destroy item after use? usually false

-- =========================================================
-- JOB GATING (extensible)
-- Players whose qbx job name is in this list can use the tablet.
-- To allow more jobs later, just add their names here.
-- =========================================================
Config.AllowedJobs = {
    'mechanic',
    -- 'tuner',
    -- 'lscustoms',
}

-- Optional: require player to be ON DUTY
Config.RequireOnDuty = false

-- If true, players NOT in an allowed job get a "fake" error animation
-- (tablet seems to "fail" gracefully instead of just not opening)
Config.FakeFailForOthers = true

-- =========================================================
-- WHERE CAN THE TABLET BE USED
-- =========================================================
Config.MustBeInVehicle = true              -- must sit in a car
Config.MustBeDriver    = true              -- must be in driver seat
Config.MustBeStopped   = true              -- car must not be moving > Config.StopSpeed
Config.StopSpeed       = 1.0               -- m/s
Config.BlockedClasses  = { 13, 14, 15, 16, 21 }  -- bicycles/boats/heli/plane/train

-- =========================================================
-- OPTIONAL CHARGING (off by default - mechanics tune for free)
-- =========================================================
Config.ChargeForMods   = false
Config.Currency        = 'cash'             -- 'cash' or 'bank'
Config.Prices = {
    looksPaint   = 200,
    looksNeons   = 1000,
    looksXenons  = 500,
    looksWheels  = 1500,
    looksPlate   = 250,
    enginePerLvl = { [1] = 2500, [2] = 5000, [3] = 8500, [4] = 14000 },
    brakePerLvl  = { [1] = 1500, [2] = 3000, [3] = 6000 },
    transPerLvl  = { [1] = 2500, [2] = 5000, [3] = 9000 },
    turbo        = 12000,
    -- Stance is always free in this system
}

-- =========================================================
-- STANCE LIMITS (advanced tuning sliders)
-- =========================================================
Config.Stance = {
    -- Tire width: multiplier on wheel width
    wheelWidth    = { min = 0.3,  max = 2.0,  default = 1.0, step = 0.05 },
    -- Wheel size: rim/tire overall diameter
    wheelSize     = { min = 0.5,  max = 1.5,  default = 1.0, step = 0.05 },
    -- Suspension height (lower = slammed). Negative is lower.
    suspHeight    = { min = -0.25, max = 0.15, default = 0.0,  step = 0.005 },
    -- Track width (X offset per wheel). Positive = wheels stick out.
    trackWidth    = { min = -0.15, max = 0.30, default = 0.0,  step = 0.01 },
    -- Camber angle (Z rotation per wheel). Negative = top tilted in.
    camberFront   = { min = -0.6,  max = 0.6,  default = 0.0,  step = 0.02 },
    camberRear    = { min = -0.6,  max = 0.6,  default = 0.0,  step = 0.02 },
}

-- =========================================================
-- PERFORMANCE LIMITS
-- =========================================================
Config.Performance = {
    engineMax = 4,    -- levels 0..3 (engine has 4 levels in GTAV)
    brakeMax  = 3,
    transMax  = 3,
    suspMax   = 4,
    -- Allow turbo install via tablet?
    allowTurbo = true,
}

-- =========================================================
-- PERSISTENCE
-- =========================================================
-- Stance values are stored per-plate. They re-apply automatically
-- when a vehicle is entered by anyone.
Config.PersistStance = true

-- =========================================================
-- ANIMATION
-- =========================================================
Config.UseTabletProp = true                                  -- show prop in hand
Config.TabletProp    = 'prop_cs_tablet'
Config.OpenAnim      = { dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base', clip = 'base' }

-- =========================================================
-- DEBUG
-- =========================================================
Config.Debug = false
