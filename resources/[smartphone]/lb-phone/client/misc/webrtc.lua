-- Receives WebRTC actions from the React UI and relays them to the server.
RegisterNUICallback("WebRTC", function(data, cb)
    local action = data.action

    if action == "createdPeer" then
        TriggerServerEvent("phone:webrtc:createdPeer", data.peerId)

    elseif action == "deletedPeer" then
        TriggerServerEvent("phone:webrtc:deletedPeer", data.peerId)

    elseif action == "signal" then
        TriggerServerEvent("phone:webrtc:signal", data.from, data.target, data.signalData)

    else
        debugprint("Unknown WebRTC action:", action)
    end

    cb("ok")
end)

-- ─── Server → NUI ──────────────────────────────────────────────────────────────
-- Forwards an incoming WebRTC signal from the server down to the React UI.
RegisterNetEvent("phone:webrtc:signal")
AddEventHandler("phone:webrtc:signal", function(signalPayload)
    SendReactMessage("webrtc:signal", signalPayload)
end)

-- Notifies the React UI that the remote peer has ended the call.
RegisterNetEvent("phone:webrtc:endCall")
AddEventHandler("phone:webrtc:endCall", function(fromPeer)
    SendReactMessage("webrtc:endCall", { from = fromPeer })
end)