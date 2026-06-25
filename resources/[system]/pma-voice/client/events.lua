isInitialized = false

function handleInitialState()
	local voiceModeData = Cfg.voiceModes[mode]
	MumbleSetTalkerProximity(voiceModeData[1] + 0.0)
	MumbleClearVoiceTarget(voiceTarget)
	MumbleSetVoiceTarget(voiceTarget)
	MumbleSetVoiceChannel(LocalPlayer.state.assignedChannel)

	while MumbleGetVoiceChannelFromServerId(playerServerId) ~= LocalPlayer.state.assignedChannel do
		Wait(100)
		MumbleSetVoiceChannel(LocalPlayer.state.assignedChannel)
	end

	isInitialized = true

	MumbleAddVoiceTargetChannel(voiceTarget,LocalPlayer.state.assignedChannel)

	addNearbyPlayers()
end

AddEventHandler("mumbleConnected",function()
	isInitialized = false

	local voiceModeData = Cfg.voiceModes[mode]
	LocalPlayer.state:set("proximity",{
		index = mode,
		distance = voiceModeData[1],
		mode = voiceModeData[2]
	},true)

	handleInitialState()

	Wait(1000)

	local Source = LocalPlayer["state"]["Source"]
	if exports["pma-voice"]:isPlayerMuted(Source) then
		TriggerEvent("pma-voice:Mute",true)
	end
end)

AddEventHandler("pma-voice:settingsCallback",function(cb)
	cb(Cfg)
end)