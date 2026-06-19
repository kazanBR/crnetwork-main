fx_version "adamant"
game "gta5"
description "App iFood no LB Phone"
author "kazanBR"
version "1.0.0"
lua54 "yes"

shared_script {
    "@vrp/lib/utils.lua",
    "lib/lib.lua",
    "lib/config.lua"
}
client_script "client.lua"

server_script {
    "@oxmysql/lib/MySQL.lua",
    "server.lua"
}

files {
    "ui/*",
    "ui/**/*"
}
ui_page "ui/index.html"

dependencies {
    'vrp',
    'lb-phone'
}
