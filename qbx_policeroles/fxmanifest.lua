fx_version 'cerulean'
game 'gta5'

name 'qbx_policeroles'
description 'Dynamic police roles & permissions for qbox + ox (doorlock / inventory / target)'
author 'Emergent'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/roles.lua',
}

client_scripts {
    'client/main.lua',
    'client/menu.lua',
    'client/doors.lua',
    'client/stashes.lua',
    'client/mdt.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/roles.lua',
    'server/permissions.lua',
    'server/doors.lua',
    'server/stashes.lua',
    'server/licenses.lua',
    'server/mdt.lua',
    'server/hooks.lua',
    'server/commands.lua',
    'server/events.lua',
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory',
    'ox_doorlock',
    'ox_target',
    'oxmysql',
}

files {
    'locales/en.json',
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

ui_page 'html/index.html'

provides {
    'qbx_policeroles',
}
