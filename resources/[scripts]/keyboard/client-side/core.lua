-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("keyboard",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Form = {}
local Results = false
local Progress = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- SUCESS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Success",function(Data,Callback)
	SetNuiFocus(false,false)
	Results = Data.Inputs
	Progress = false

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Close",function(Data,Callback)
	Results = false
	Progress = false
	SetNuiFocus(false,false)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BUTTON
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Button",function(Data,Callback)
	Results = false
	Progress = false
	SetNuiFocus(false,false)

	if Data.Event then
		TriggerEvent(Data.Event,Data.Params)
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- KEYBOARD
-----------------------------------------------------------------------------------------------------------------------------------------
function Keyboard(Rows,Title,Subtitle,Cancel)
	if Progress then
		return false
	end

	Results = {}
	Progress = true
	SetNuiFocus(true,true)
	SetCursorLocation(0.5,0.5)

	SendNUIMessage({
		Action = "Open",
		Payload = {
			Rows = Rows,
			HideCancel = Cancel,
			Title = Title or "Formulário",
			Subtitle = Subtitle or "Preencha os campos abaixo"
		}
	})

	while Progress do
		Wait(0)
	end

	if not Results or #Results == 0 then
		return false
	end

	for _,v in ipairs(Results) do
		if v == "" or v == nil then
			return false
		end
	end

	return Results
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RADIO
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Radio = function(Frequency,Volume)
	local Fields = {
		{ Mode = "number", Value = Frequency, Placeholder = "Frequência" },
		{ Mode = "slider", Value = Volume, Placeholder = "Volume", Min = 0, Max = 100 }
	}

	if Frequency > 0 then
		Fields[#Fields + 1] = { Mode = "button", Placeholder = "Desconectar", Event = "radio:Disconnect" }
	end

	return Keyboard(Fields)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PASSWORD
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Password = function(Placeholder)
	return Keyboard({
		{ Mode = "password", Placeholder = Placeholder }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PRIMARY
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Primary = function(First)
	return Keyboard({
		{ Mode = "text", Placeholder = First }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SECONDARY
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Secondary = function(First,Second)
	return Keyboard({
		{ Mode = "text", Placeholder = First },
		{ Mode = "text", Placeholder = Second }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TERTIARY
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Tertiary = function(First,Second,Third)
	return Keyboard({
		{ Mode = "text", Placeholder = First },
		{ Mode = "text", Placeholder = Second },
		{ Mode = "text", Placeholder = Third }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- QUATERNARY
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Quaternary = function(First,Second,Third,Fourth)
	return Keyboard({
		{ Mode = "text", Placeholder = First },
		{ Mode = "text", Placeholder = Second },
		{ Mode = "text", Placeholder = Third },
		{ Mode = "area", Placeholder = Fourth }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CODES
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Codes = function(First,Second,Third)
	return Keyboard({
		{ Mode = "text", Placeholder = First },
		{ Mode = "text", Placeholder = Second },
		{ Mode = "area", Placeholder = Third }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- AREA
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Area = function(First)
	return Keyboard({
		{ Mode = "area", Placeholder = First }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANNOUNCE
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Announce = function(First,Second,Third,Fourth,Fifth)
	return Keyboard({
		{ Mode = "text", Placeholder = First },
		{ Mode = "area", Placeholder = Second },
		{ Mode = "text", Placeholder = Third },
		{ Mode = "options", Placeholder = "Selecione uma opção", Options = Fourth },
		{ Mode = "options", Placeholder = "Selecione uma opção", Options = Fifth }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- COPY
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Copy = function(First,Message)
	return Keyboard({
		{ Mode = "area", Placeholder = First, Value = Message, Save = true }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INSTAGRAM
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Instagram = function(Options,Title,Subtitle)
	return Keyboard({
		{ Mode = "options", Placeholder = "Selecione uma opção", Options = Options }
	},Title,Subtitle)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- OPTIONS
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Options = function(First,Second)
	return Keyboard({
		{ Mode = "text", Placeholder = First },
		{ Mode = "options", Placeholder = "Selecione uma opção", Options = Second }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TIMESET
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Timeset = function(First,Second,Third)
	return Keyboard({
		{ Mode = "text", Placeholder = First },
		{ Mode = "text", Placeholder = Second },
		{ Mode = "options", Placeholder = "Selecione uma opção", Options = Third }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Spawn = function(First,Second,Third,Fourth)
	return Keyboard({
		{ Mode = "text", Placeholder = First },
		{ Mode = "text", Placeholder = Second },
		{ Mode = "options", Placeholder = "Selecione uma opção", Options = Third },
		{ Mode = "options", Placeholder = "Selecione uma opção", Options = Fourth }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- VEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Vehicle = function(First,Second,Third,Fourth,Fifth)
	return Keyboard({
		{ Mode = "text", Placeholder = First },
		{ Mode = "text", Placeholder = Second },
		{ Mode = "options", Placeholder = "Selecione uma opção", Options = Third },
		{ Mode = "text", Placeholder = Fourth },
		{ Mode = "options", Placeholder = "Selecione uma opção", Options = Fifth }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SKINS
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Skins = function(First,Second,Third,Fourth,Fifth)
	return Keyboard({
		{ Mode = "text", Placeholder = First },
		{ Mode = "text", Placeholder = Second },
		{ Mode = "text", Placeholder = Third },
		{ Mode = "text", Placeholder = Fourth },
		{ Mode = "options", Placeholder = "Selecione uma opção", Options = Fifth }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ITEM
-----------------------------------------------------------------------------------------------------------------------------------------
Form.Item = function(First,Second,Third,Fourth,Fifth)
	return Keyboard({
		{ Mode = "text", Placeholder = First },
		{ Mode = "text", Placeholder = Second },
		{ Mode = "text", Placeholder = Third },
		{ Mode = "options", Placeholder = "Selecione uma opção", Options = Fourth },
		{ Mode = "text", Placeholder = Fifth }
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXPORTS & BINDINGS
-----------------------------------------------------------------------------------------------------------------------------------------
for Name,v in pairs(Form) do
	Creative[Name] = v
	exports(Name,v)
end