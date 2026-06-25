-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Volume = 50
local Frequency = 0
-----------------------------------------------------------------------------------------------------------------------------------------
-- RADIO:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("radio:Open")
AddEventHandler("radio:Open",function()
	if LocalPlayer.state.Banned or LocalPlayer.state.Prison or not MumbleIsConnected() then
		return false
	end

	local Keyboard = exports.keyboard:Radio(Frequency,Volume)
	if not Keyboard then
		return false
	end

	local NumberVolume = Keyboard[2]
	local NumberFrequency = Keyboard[1]

	TriggerEvent("radio:Connect",NumberFrequency,NumberVolume)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RADIO:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("radio:Connect",function(NumberFrequency,NumberVolume,Notify)
	if NumberFrequency and NumberFrequency >= 1 and NumberFrequency <= 999 and NumberFrequency ~= Frequency and vSERVER.Frequency(NumberFrequency) then
		Frequency = NumberFrequency

		exports["pma-voice"]:removePlayerFromRadio()
		exports["pma-voice"]:setRadioChannel(Frequency)
		SendNUIMessage({ Action = "Frequency", Payload = Frequency })

		if Notify then
			TriggerEvent("mdt:Notify","Radiofrequência","Entrou na frequência <b>"..Frequency.."</b>.","verde")
		else
			TriggerEvent("Notify","Radiofrequência","Entrou na frequência <b>"..Frequency.."</b>.","verde",5000)
		end
	end

	if NumberVolume and NumberVolume ~= Volume then
		Volume = NumberVolume

		exports["pma-voice"]:setRadioVolume(Volume)
		TriggerEvent("Notify","Radiofrequência","Volume ajustado para <b>"..Volume.."%</b>.","verde",5000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RADIO:DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("radio:Disconnect",function()
	if Frequency ~= 0 then
		Frequency = 0
		SendNUIMessage({ Action = "Frequency" })
		exports["pma-voice"]:removePlayerFromRadio()
		TriggerEvent("Notify","Radiofrequência","Desconectou de todas as frequências.","amarelo",5000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RADIO:DISPLAY
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("radio:Display",function(OtherSource,Name,Enable)
	if Enable then
		SendNUIMessage({ Action = "Radio", Payload = { Source = OtherSource, Name = Name or "Desconhecido" } })
	else
		SendNUIMessage({ Action = "Radio", Payload = { Source = OtherSource } })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RADIOCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("RadioConnect",function(Data,Callback)
	TriggerEvent("radio:Connect",Data.Frequency,Volume,true)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPFREQUENCY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("UpFrequency",function()
	if Frequency ~= 0 then
		TriggerEvent("radio:Connect",Frequency + 1)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOWNFREQUENCY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("DownFrequency",function()
	if Frequency ~= 0 then
		TriggerEvent("radio:Connect",Frequency - 1)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- KEYMAPPING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterKeyMapping("UpFrequency","Aumentar frequencia do rádio.","keyboard","PRIOR")
RegisterKeyMapping("DownFrequency","Diminuir frequencia do rádio.","keyboard","PAGEDOWN")
-----------------------------------------------------------------------------------------------------------------------------------------
-- RADIO
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Radio()
	return Frequency
end