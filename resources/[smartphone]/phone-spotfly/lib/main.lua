Tunnel = module('vrp', 'lib/Tunnel')
Proxy = module('vrp', 'lib/Proxy')
vRP = Proxy.getInterface('vRP')

identifier = 'phone-spotfly'

if IsDuplicityVersion() then
    srv = {}
    Tunnel.bindInterface(GetCurrentResourceName(), srv)
    vCLIENT = Tunnel.getInterface(GetCurrentResourceName())
else
    cli = {}
    Tunnel.bindInterface(GetCurrentResourceName(), cli)
    vSERVER = Tunnel.getInterface(GetCurrentResourceName())
end
