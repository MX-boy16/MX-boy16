-----------------------------------------------------------------------
-- gym_system :: ox_inventory item definitions  (v2 - export method)
-- COPY each of these entries into:  ox_inventory/data/items.lua
-- (paste inside the existing `return { ... }` table)
--
-- IMPORTANT: This version uses ox_inventory's NATIVE client export so the
-- "Use" action actually fires. If you pasted the old version, REPLACE it.
--   consume = 1  -> ox_inventory removes one item when used.
--   client.export -> runs gym_system's handler on use.
-----------------------------------------------------------------------

['protein_choco'] = {
    label = 'Protein (Chocolate)',
    weight = 500,
    stack = true,
    close = true,
    consume = 1,
    description = 'Chocolate whey protein. Builds muscle & strength.',
    client = { export = 'gym_system.useGymItem' },
},

['protein_vanilla'] = {
    label = 'Protein (Vanilla)',
    weight = 500,
    stack = true,
    close = true,
    consume = 1,
    description = 'Vanilla whey protein. Builds muscle & strength.',
    client = { export = 'gym_system.useGymItem' },
},

['protein_strawberry'] = {
    label = 'Protein (Strawberry)',
    weight = 500,
    stack = true,
    close = true,
    consume = 1,
    description = 'Strawberry whey protein. Builds muscle & strength.',
    client = { export = 'gym_system.useGymItem' },
},

['preworkout_choco'] = {
    label = 'Pre-Workout (Chocolate)',
    weight = 300,
    stack = true,
    close = true,
    consume = 1,
    description = 'Chocolate pre-workout. Boosts stamina & energy.',
    client = { export = 'gym_system.useGymItem' },
},

['preworkout_vanilla'] = {
    label = 'Pre-Workout (Vanilla)',
    weight = 300,
    stack = true,
    close = true,
    consume = 1,
    description = 'Vanilla pre-workout. Boosts stamina & energy.',
    client = { export = 'gym_system.useGymItem' },
},

['preworkout_strawberry'] = {
    label = 'Pre-Workout (Strawberry)',
    weight = 300,
    stack = true,
    close = true,
    consume = 1,
    description = 'Strawberry pre-workout. Boosts stamina & energy.',
    client = { export = 'gym_system.useGymItem' },
},

['creatine'] = {
    label = 'Creatine',
    weight = 300,
    stack = true,
    close = true,
    consume = 1,
    description = 'Creatine monohydrate. Boosts strength & muscle.',
    client = { export = 'gym_system.useGymItem' },
},

['steroids'] = {
    label = 'Injectable Steroids',
    weight = 200,
    stack = true,
    close = true,
    consume = 1,
    description = 'Injectable anabolic steroids. Massive gains, small health cost.',
    client = { export = 'gym_system.useGymItem' },
},

['gym_membercard'] = {
    label = 'Gym Membership Card',
    weight = 50,
    stack = false,
    close = true,
    consume = 1,
    description = 'Premium gym membership card. Use it to activate access.',
    client = { export = 'gym_system.useGymCard' },
},
