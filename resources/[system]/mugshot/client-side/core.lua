-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Answers = {}
local Mugshot = nil
local CurrentPromise = nil
local IsTakingMugshot = false
local RequestId = 0
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAFEUNREGISTER
-----------------------------------------------------------------------------------------------------------------------------------------
local function SafeUnregister()
	if Mugshot and Mugshot ~= -1 then
		UnregisterPedheadshot(Mugshot)
		Mugshot = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WAITPEDREADY
-----------------------------------------------------------------------------------------------------------------------------------------
local function WaitPedReady(Ped)
	local Timeout = GetGameTimer() + 4000

	while GetGameTimer() < Timeout do
		if DoesEntityExist(Ped) and not IsEntityDead(Ped) then
			if HasPedHeadBlendFinished(Ped) then
				return true
			end
		end

		Wait(50)
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETMUGSHOTBASE64
-----------------------------------------------------------------------------------------------------------------------------------------
function GetMugShotBase64()
	if IsTakingMugshot then
		return false
	end

	IsTakingMugshot = true

	local Ped = PlayerPedId()
	if not WaitPedReady(Ped) then
		IsTakingMugshot = false
		return false
	end

	SafeUnregister()

	local Handle = RegisterPedheadshot(Ped)
	if not Handle or Handle == -1 then
		IsTakingMugshot = false
		return false
	end

	local Timeout = GetGameTimer() + 3000
	while GetGameTimer() < Timeout do
		if IsPedheadshotReady(Handle) and IsPedheadshotValid(Handle) then
			break
		end

		Wait(10)
	end

	if not IsPedheadshotReady(Handle) or not IsPedheadshotValid(Handle) then
		UnregisterPedheadshot(Handle)
		IsTakingMugshot = false
		return false
	end

	Mugshot = Handle
	local Texture = GetPedheadshotTxdString(Handle)

	RequestId = RequestId + 1
	local id = RequestId

	SendNUIMessage({
		id = id,
		type = "convert",
		pMugShotTxd = Texture,
		removeImageBackGround = false
	})

	CurrentPromise = promise.new()
	Answers[id] = CurrentPromise

	local Result = Citizen.Await(CurrentPromise)

	SafeUnregister()

	IsTakingMugshot = false

	return Result
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANSWER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Answer",function(Data,Callback)
	local id = Data.Id
	local p = Answers[id]

	if p then
		p:resolve(Data.Answer)
		Answers[id] = nil
	end

	SafeUnregister()

	if Callback then
		Callback("Ok")
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- AVATAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Avatar",function(Data,Callback)
	local Result = GetMugShotBase64()

	if Callback then
		Callback(Result)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ONRESOURCESTOP
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("onResourceStop",function(Resource)
	if Resource == GetCurrentResourceName() then
		SafeUnregister()
		Answers = {}
	end
end)