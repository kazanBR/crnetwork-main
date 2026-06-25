-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Displays = {}
local Active = false
local Payload = nil
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADFY
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local Ped = PlayerPedId()
		local Coords = GetEntityCoords(Ped)

		if not Active then
			if LocalPlayer.state.Route == 0 then
				for Index,v in pairs(Displays) do
					if #(Coords - v.Coords) <= v.Distance then
						Active = Index
						Payload = { Key = v.Key, Title = v.Title, Legend = v.Legend }
						SendNUIMessage({ Action = "Show", Payload = Payload })

						break
					end
				end
			end
		else
			local Display = Displays[Active]
			if not Display or #(Coords - Display.Coords) > Display.Distance then
				SendNUIMessage({ Action = "Hide" })
				Active = false
				Payload = nil
			end
		end

		Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HOVERFY:INSERT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hoverfy:Insert")
AddEventHandler("hoverfy:Insert",function(Data)
	for i = 1,#Data do
		local Entry = Data[i]
		Displays[#Displays + 1] = {
			Coords = Entry[1],
			Distance = Entry[2],
			Key = Entry[3],
			Title = Entry[4],
			Legend = Entry[5]
		}
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Hoverfy",("player:%s"):format(LocalPlayer.state.Source),function(_,_,Value)
	if Active and Displays[Active] then
		SendNUIMessage({
			Action = Value and "Show" or "Hide",
			Payload = Payload
		})
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HOVERFY:SHOW
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hoverfy:Show",function(Data)
    SendNUIMessage({ Action = "Show", Payload = Data })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HOVERFY:HIDE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("hoverfy:Hide",function()
    SendNUIMessage({ Action = "Hide" })
end)