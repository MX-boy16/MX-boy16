-----------------------------------------------------------------------
-- gym_system :: ox_inventory item definitions
-- COPY each of these entries into:  ox_inventory/data/items.lua
-- (paste inside the existing `return { ... }` table)
--
-- consume = 0  -> ox_inventory will NOT auto-remove the item; the gym
--                 resource removes it itself AFTER the animation finishes.
-----------------------------------------------------------------------

['protein_choco'] = {
    label = 'Protein (Chocolate)',
    weight = 500,
    stack = true,
    close = true,
    consume = 0,
    description = 'Chocolate whey protein. Builds muscle & strength.',
    client = { status = { hunger = 50000 } },
},

['protein_vanilla'] = {
    label = 'Protein (Vanilla)',
    weight = 500,
    stack = true,
    close = true,
    consume = 0,
    description = 'Vanilla whey protein. Builds muscle & strength.',
    client = { status = { hunger = 50000 } },
},

['protein_strawberry'] = {
    label = 'Protein (Strawberry)',
    weight = 500,
    stack = true,
    close = true,
    consume = 0,
    description = 'Strawberry whey protein. Builds muscle & strength.',
    client = { status = { hunger = 50000 } },
},

['preworkout_choco'] = {
    label = 'Pre-Workout (Chocolate)',
    weight = 300,
    stack = true,
    close = true,
    consume = 0,
    description = 'Chocolate pre-workout. Boosts stamina & energy.',
},

['preworkout_vanilla'] = {
    label = 'Pre-Workout (Vanilla)',
    weight = 300,
    stack = true,
    close = true,
    consume = 0,
    description = 'Vanilla pre-workout. Boosts stamina & energy.',
},

['preworkout_strawberry'] = {
    label = 'Pre-Workout (Strawberry)',
    weight = 300,
    stack = true,
    close = true,
    consume = 0,
    description = 'Strawberry pre-workout. Boosts stamina & energy.',
},

['creatine'] = {
    label = 'Creatine',
    weight = 300,
    stack = true,
    close = true,
    consume = 0,
    description = 'Creatine monohydrate. Boosts strength & muscle.',
},

['steroids'] = {
    label = 'Injectable Steroids',
    weight = 200,
    stack = true,
    close = true,
    consume = 0,
    description = 'Injectable anabolic steroids. Massive gains, small health cost.',
},

['gym_membercard'] = {
    label = 'Gym Membership Card',
    weight = 50,
    stack = false,
    close = true,
    consume = 0,
    description = 'Premium gym membership card. Use it to activate access.',
},
