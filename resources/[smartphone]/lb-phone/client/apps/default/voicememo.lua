-- NUI callback: dispatch VoiceMemo UI actions to the appropriate server callback
RegisterNUICallback("VoiceMemo", function(data, cb)
    if not currentPhone then
        return
    end

    local action = data.action
    debugprint("VoiceMemo:", action or "")

    if action == "upload" then
        TriggerCallback("voiceMemo:saveRecording", cb, data.data)

    elseif action == "get" then
        TriggerCallback("voiceMemo:getMemos", cb)

    elseif action == "delete" then
        TriggerCallback("voiceMemo:deleteMemo", cb, data.id)

    elseif action == "rename" then
        TriggerCallback("voiceMemo:renameMemo", cb, data.id, data.title)
    end
end)