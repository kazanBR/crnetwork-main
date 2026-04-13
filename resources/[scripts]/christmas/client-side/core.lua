-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Alpha = {}
local Objects = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	LoadModel("prop_zira_natal_01")

	if GlobalState.Christmas then
		for Index in pairs(Locations) do
			if GlobalState["Christmas:"..Index] then
				Alpha[Index] = AddBlipForRadius(Locations[Index].xyz,25.0)
				SetBlipAlpha(Alpha[Index],255)
				SetBlipColour(Alpha[Index],81)
			end
		end
	end

	while true do
		if GlobalState.Christmas then
			local Ped = PlayerPedId()
			local Coords = GetEntityCoords(Ped)

			for Index,OtherCoords in pairs(Locations) do
				local Name = "Christmas:"..Index
				local Distance = #(Coords - OtherCoords.xyz)

				if Distance <= 100 and GlobalState[Name] then
					if not Objects[Index] then
						Objects[Index] = CreateObjectNoOffset("prop_zira_natal_01",OtherCoords.xyz,false,false,false)
						SetEntityLodDist(Objects[Index],0xFFFF)
						FreezeEntityPosition(Objects[Index],true)
						PlaceObjectOnGroundProperly(Objects[Index])
						SetEntityHeading(Objects[Index],OtherCoords.w)

						exports.target:AddBoxZone(Name,vec3(OtherCoords.x,OtherCoords.y,OtherCoords.z + 0.25),0.75,0.75,{
							name = Name,
							heading = OtherCoords.w,
							maxZ = OtherCoords.z + 0.75
						},{
							shop = Name,
							Distance = 2.0,
							options = {
								{
									event = "chest:Open",
									label = "Abrir",
									tunnel = "client",
									service = "Custom"
								}
							}
						})
					end
				elseif Objects[Index] then
					exports.target:RemCircleZone(Name)

					if DoesEntityExist(Objects[Index]) then
						DeleteEntity(Objects[Index])
					end

					Objects[Index] = nil
				end
			end
		end

		Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
for Index in pairs(Locations) do
	local Name = "Christmas:"..Index
	AddStateBagChangeHandler(Name,nil,function(_,_,Value)
		if not Value then
			TriggerEvent("inventory:Closed",Name)

			if Objects[Index] then
				exports.target:RemCircleZone(Name)

				if DoesEntityExist(Objects[Index]) then
					DeleteEntity(Objects[Index])
				end

				Objects[Index] = nil
			end

			if Alpha[Index] then
				if DoesBlipExist(Alpha[Index]) then
					RemoveBlip(Alpha[Index])
				end

				Alpha[Index] = nil
			end
		else
			Alpha[Index] = AddBlipForRadius(Locations[Index].xyz,25.0)
			SetBlipAlpha(Alpha[Index],255)
			SetBlipColour(Alpha[Index],81)
		end
	end)
end