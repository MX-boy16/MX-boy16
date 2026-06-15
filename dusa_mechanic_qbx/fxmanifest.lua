fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dusa_mechanic_qbx'
author 'Emergent E1'
description 'Dusa-like Mechanic System for QBX Core + ox_lib + ox_target + ox_inventory + oxmysql'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/en.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/main.lua',
    'client/repair.lua',
    'client/tuning.lua',
    'client/cosmetics.lua',
    'client/nos.lua',
    'client/lifts.lua',
    'client/job.lua',
    'client/towing.lua',
    'client/diagnostic.lua',
    'client/nui.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/repair.lua',
    'server/tuning.lua',
    'server/cosmetics.lua',
    'server/nos.lua',
    'server/job.lua',
    'server/towing.lua',
    'server/diagnostic.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/*.svg',
    'html/assets/*.png',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'qbx_core',
}
