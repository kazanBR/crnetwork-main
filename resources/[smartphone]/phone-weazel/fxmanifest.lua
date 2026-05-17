
fx_version 'cerulean'
game 'gta5'

author 'Dev-Store'
description 'Weazel'
version '2.8'

ui_page 'web/index.html'

client_script 'module/client.lua'
server_script 'module/server.lua'
shared_scripts { '@vrp/lib/Utils.lua', 'lib/main.lua', 'module/config.lua' }

files { 'web/**/*' }              