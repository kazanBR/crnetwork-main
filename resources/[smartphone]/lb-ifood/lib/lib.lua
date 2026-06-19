local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

src = {}
local resourceName = GetCurrentResourceName()
local SERVER = IsDuplicityVersion()

if SERVER then
    Tunnel.bindInterface(resourceName, src)
    vRPclient = Tunnel.getInterface("vRP")
    vCLIENT = Tunnel.getInterface(resourceName)
else
    Tunnel.bindInterface(resourceName, src)
    vRPserver = Tunnel.getInterface("vRP", resourceName)
    vSERVER = Tunnel.getInterface(resourceName)
end
