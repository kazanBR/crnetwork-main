fx_version "cerulean"
game "gta5"
lua54 "yes"

client_scripts {
  "@vrp/lib/Utils.lua",
  "utils/*.lua",
  "client/client.lua"
}

server_scripts {
  "@vrp/lib/Utils.lua",
  "@vrp/config/Vehicle.lua",
  "utils/*.lua",
  "server/server.lua"
}

files {
  "web/**/*",
  "web/*"
}