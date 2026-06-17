-----------------------------------------------------------------------
-- gym_system :: ox_inventory item definitions  (v3 - mixing system)
-- COPY each of these entries into:  ox_inventory/data/items.lua
-- (paste inside the existing `return { ... }` table)
--
-- NOTE: requires a `water` item to already exist in ox_inventory (default).
--   * Bags (protein/preworkout/creatine) carry a `durability` % bar and are
--     mixed into bottles (NOT used directly).
--   * Gym bottles (small/big) are reusable: mix -> drink -> empty.
--   * consume = 0 on bags/bottles -> the gym resource manages amounts itself.
-----------------------------------------------------------------------

-- ============ SUPPLEMENT BAGS (mixable, start at 100%) ============
['protein_choco'] = {
    label = 'Protein Bag (Chocolate)',
    weight = 800, stack = true, close = true, consume = 0,
    description = 'Chocolate whey protein powder. Mix in a gym bottle.',
    client = { export = 'gym_system.useGymItem' },
},
['protein_vanilla'] = {
    label = 'Protein Bag (Vanilla)',
    weight = 800, stack = true, close = true, consume = 0,
    description = 'Vanilla whey protein powder. Mix in a gym bottle.',
    client = { export = 'gym_system.useGymItem' },
},
['protein_strawberry'] = {
    label = 'Protein Bag (Strawberry)',
    weight = 800, stack = true, close = true, consume = 0,
    description = 'Strawberry whey protein powder. Mix in a gym bottle.',
    client = { export = 'gym_system.useGymItem' },
},
['preworkout_choco'] = {
    label = 'Pre-Workout Bag (Chocolate)',
    weight = 600, stack = true, close = true, consume = 0,
    description = 'Chocolate pre-workout powder. Mix in a gym bottle.',
    client = { export = 'gym_system.useGymItem' },
},
['preworkout_vanilla'] = {
    label = 'Pre-Workout Bag (Vanilla)',
    weight = 600, stack = true, close = true, consume = 0,
    description = 'Vanilla pre-workout powder. Mix in a gym bottle.',
    client = { export = 'gym_system.useGymItem' },
},
['preworkout_strawberry'] = {
    label = 'Pre-Workout Bag (Strawberry)',
    weight = 600, stack = true, close = true, consume = 0,
    description = 'Strawberry pre-workout powder. Mix in a gym bottle.',
    client = { export = 'gym_system.useGymItem' },
},
['creatine'] = {
    label = 'Creatine Bag',
    weight = 600, stack = true, close = true, consume = 0,
    description = 'Creatine monohydrate powder. Mix in a gym bottle.',
    client = { export = 'gym_system.useGymItem' },
},

-- ============ GYM BOTTLES (reusable shakers) ============
['gym_bottle_small'] = {
    label = 'Small Gym Bottle',
    weight = 200, stack = false, close = true, consume = 0,
    description = 'Small shaker — uses 1 water + 10% powder. Mix, then drink.',
    client = { export = 'gym_system.useGymBottle' },
},
['gym_bottle_big'] = {
    label = 'Big Gym Bottle',
    weight = 350, stack = false, close = true, consume = 0,
    description = 'Big shaker — uses 2 water + 20% powder. Mix, then drink.',
    client = { export = 'gym_system.useGymBottle' },
},

-- ============ INJECTABLE STEROIDS (used directly) ============
['steroids'] = {
    label = 'Injectable Steroids',
    weight = 200, stack = true, close = true, consume = 1,
    description = 'Injectable anabolic steroids. Massive gains, small health cost.',
    client = { export = 'gym_system.useGymItem' },
},

-- ============ MEMBERSHIP CARD ============
['gym_membercard'] = {
    label = 'Gym Membership Card',
    weight = 50, stack = false, close = true, consume = 1,
    description = 'Premium gym membership card. Use it to activate access.',
    client = { export = 'gym_system.useGymCard' },
},
