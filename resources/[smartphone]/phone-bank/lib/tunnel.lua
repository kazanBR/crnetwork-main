Tunnel = module('vrp', 'lib/Tunnel')
Proxy = module('vrp', 'lib/Proxy')
vRP = Proxy.getInterface('vRP')

identifier = 'capital-bank'
phone_resource = 'lb-phone'

oxmysql = exports.oxmysql

if (IsDuplicityVersion()) then
    srv = {}
    Tunnel.bindInterface(GetCurrentResourceName(), srv)
    vCLIENT = Tunnel.getInterface(GetCurrentResourceName())

    vRPclient = Tunnel.getInterface('vRP')
else
    cli = {}
    Tunnel.bindInterface(GetCurrentResourceName(), cli)
    vSERVER = Tunnel.getInterface(GetCurrentResourceName())

    vRPserver = Tunnel.getInterface('vRP')
end