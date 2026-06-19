fx_version 'cerulean'
game 'gta5'

author 'zVegas'
description 'Spotfy'
version '1.0'

client_script 'module/client.lua'
server_script 'module/server.lua'
shared_scripts { '@vrp/lib/Utils.lua', 'lib/main.lua', 'module/config.lua' }

files { 'web/**/*' }

dependency 'xsound'
