fx_version "cerulean"
game "gta5"
lua54 "yes"

dependency "oxmysql"

client_scripts {
  "@vrp/lib/Utils.lua",
  "client/client.lua"
}

server_scripts {
  "@vrp/lib/Utils.lua",
  "@vrp/config/Vehicle.lua",
  "server/server.lua"
}

files {
  "web/**/*",
  "web/*"
}
