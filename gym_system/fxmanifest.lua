fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'gym_system'
author 'Emergent'
description 'Full gym progression system for QBX + ox (stamina, strength, punch power, visible muscle growth, membership, supplements & steroids)'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/stats.lua',
    'client/main.lua',
    'client/items.lua'
}

server_scripts {
    'server/main.lua',
    'server/items.lua'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'ox_target'
}
