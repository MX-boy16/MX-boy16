fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mechanic_tablet'
author 'Emergent E1'
description 'Tablet-based mechanic tool for QBX + OX. In-vehicle customization for any allowed job.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/main.lua',
    'client/stance.lua',
    'client/looks.lua',
    'client/engine.lua',
    'client/nui.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/*.svg',
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql',
    'qbx_core',
}
