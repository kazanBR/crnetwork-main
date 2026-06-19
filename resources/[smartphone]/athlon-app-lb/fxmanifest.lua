fx_version 'cerulean'
game 'gta5'

author 'kazanBR'
description 'Sistema de ECU programável integrado ao LB-Phone'
version '1.0.0'



files {
    "web/**/*",
    "web/*",
    'web/sounds/pipoco.ogg'
  }
  

shared_scripts {
  '@vrp/lib/Utils.lua',
  'server/config.lua',
  '@vrp/config/Vehicle.lua'
}

client_scripts {
  'client/client.lua'
}

server_scripts {
  'server/server.lua'
}

dependencies {
    'oxmysql'
}


