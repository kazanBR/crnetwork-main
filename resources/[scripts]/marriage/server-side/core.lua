-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRPC = Tunnel.getInterface("vRP")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARRIAGE:REQUEST
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("marriage:Request")
AddEventHandler("marriage:Request",function(OtherSource)
	local source = source
	local Passport = vRP.Passport(source)
	local OtherPassport = vRP.Passport(OtherSource)
	if not Passport or not OtherPassport then
		return false
	end

	local Identity = vRP.Identity(Passport)
	local OtherIdentity = vRP.Identity(OtherPassport)
	if not Identity or not OtherIdentity then
		return false
	end

	vRPC.playAnim(source,false,{"amb@medic@standing@kneel@idle_a","idle_a"},true)
	vRPC.CreateObjects(source,"ultra@propose","propose","ultra_ringcase",49,28422,0.08,0.01,-0.055,0.0,180.0,-90.0)

	local FullName = (Identity.Name.." "..Identity.Lastname)
	local OtherFullName = (OtherIdentity.Name.." "..OtherIdentity.Lastname)
	if not vRP.Request(OtherSource,"Relacionamento","Aceitar pedido de <b>"..FullName.."</b>?") then
		TriggerClientEvent("marriage:Reject",source,OtherFullName)
		return false
	end

	if not vRP.PaymentFull(Passport,20000,true) then
		TriggerClientEvent("inventory:Notify",source,"Aviso","Dinheiro insuficiente.","amarelo")
		return false
	end

	local ItemName = "alliance"
	if vRP.TakeItem(Passport,"alliance3") then
		ItemName = "alliance2"
	end

	vRP.GenerateItem(Passport,ItemName.."-"..OtherPassport,1,true)
	vRP.GenerateItem(OtherPassport,ItemName.."-"..Passport,1,true)

	TriggerClientEvent("marriage:Accept",OtherSource,FullName)
	TriggerClientEvent("marriage:Accept",source,OtherFullName)
end)