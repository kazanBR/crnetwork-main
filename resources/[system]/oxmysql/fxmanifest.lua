fx_version "cerulean"
game "common"
use_experimental_fxv2_oal "yes"
lua54 "yes"

version "2.14.1"

dependencies {
	"/server:12913"
}

server_script "server-side/server.js"

provide "mysql-async"