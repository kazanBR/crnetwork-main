-- Forward declarations for module-level functions
local addVoiceLink, removeVoiceLink

-- addVoiceLink(listenerSource, speakerSource, playFromSource)
-- Connects two players' voice targets so they can hear each other.
-- If playFromSource is provided, audio plays from that entity's position.
function addVoiceLink(listenerSource, speakerSource, playFromSource)
    local proxySuffix = playFromSource and (" (playing from %s)"):format(DebugPlayerName(playFromSource)) or ""
    debugprint(DebugPlayerName(speakerSource) .. " is now speaking to " .. DebugPlayerName(listenerSource) .. proxySuffix)

    -- Let the listener hear the speaker
    TriggerClientEvent("phone:phone:addVoiceTarget", speakerSource, {
        sources = listenerSource
    })

    -- Let the speaker hear the listener, with phone call audio settings
    TriggerClientEvent("phone:phone:addVoiceTarget", listenerSource, {
        sources      = speakerSource,
        audio        = true,
        phoneCall    = true,
        playFromSource = playFromSource
    })
end

-- removeVoiceLink(listenerSource, speakerSource)
-- Disconnects two players' voice targets.
function removeVoiceLink(listenerSource, speakerSource)
    debugprint(DebugPlayerName(speakerSource) .. " stopped speaking to " .. DebugPlayerName(listenerSource))

    TriggerClientEvent("phone:phone:removeVoiceTarget", speakerSource, listenerSource, true)
    TriggerClientEvent("phone:phone:removeVoiceTarget", listenerSource, speakerSource, true)
end

-- ─── toggleMute ────────────────────────────────────────────────────────────────
-- Triggered by a client to mute/unmute themselves during an active call.
-- Updates player state and notifies all nearby listeners of the audibility change.
RegisterNetEvent("phone:phone:toggleMute")
AddEventHandler("phone:phone:toggleMute", function(isMuted)
    local playerSource = source
    local _, _, callData = IsInCall(playerSource)
    if not callData then return end

    -- Determine which side of the call we are, and get both nearby lists + other participant
    local isCaller    = callData.caller.source == playerSource
    local myNearby    = isCaller and callData.caller.nearby    or callData.callee.nearby
    local otherNearby = isCaller and callData.callee.nearby    or callData.caller.nearby
    local otherSource = isCaller and callData.callee.source    or callData.caller.source

    -- Update this player's mute state
    isMuted = isMuted == true
    Player(playerSource).state.mutedCall = isMuted

    if not callData.answered then return end

    -- Build full listener lists (nearby + the direct participant)
    local myListeners    = table.clone(myNearby)
    myListeners[#myListeners + 1]    = playerSource

    local otherListeners = table.clone(otherNearby)
    otherListeners[#otherListeners + 1] = otherSource

    -- Notify each person on the other side whether they can hear this player
    for _, listenerSource in ipairs(otherListeners) do
        local muteLabel = isMuted and "not " or ""
        debugprint(DebugPlayerName(listenerSource), "set " .. muteLabel .. "audible for", myListeners)
        TriggerClientEvent("phone:phone:setTargetsAudible", listenerSource, myListeners, not isMuted)
    end
end)

-- ─── toggleSpeaker ─────────────────────────────────────────────────────────────
-- Triggered by a client to turn speakerphone on or off.
RegisterNetEvent("phone:phone:toggleSpeaker")
AddEventHandler("phone:phone:toggleSpeaker", function(isEnabled)
    Player(source).state.speakerphone = isEnabled == true
end)

-- ─── enteredCallProximity ──────────────────────────────────────────────────────
-- Triggered when a bystander walks into range of a phone call participant.
-- If that participant has speakerphone on, connect the bystander to the call audio.
RegisterNetEvent("phone:phone:enteredCallProximity")
AddEventHandler("phone:phone:enteredCallProximity", function(callParticipantSource)
    local bystanderSource = source
    local _, _, callData  = IsInCall(callParticipantSource)

    debugprint("phone:phone:enteredCallProximity:", DebugPlayerName(bystanderSource), "entered the proximity of", DebugPlayerName(callParticipantSource))

    if not callData then
        debugprint(DebugPlayerName(callParticipantSource), "is not in a call")
        return
    end

    if not callData.answered then
        debugprint("call not answered yet")
        return
    end

    -- Determine call sides relative to the participant we're near
    local isCaller    = callData.caller.source == callParticipantSource
    local myNearby    = isCaller and callData.caller.nearby    or callData.callee.nearby
    local otherNearby = isCaller and callData.callee.nearby    or callData.caller.nearby
    local otherSource = isCaller and callData.callee.source    or callData.caller.source

    local participantState = Player(callParticipantSource).state

    if not participantState.speakerphone then
        debugprint(DebugPlayerName(callParticipantSource), "does not have speakerphone on")
        return
    end

    if not otherSource then
        debugprint("other call participant not found")
        return
    end

    local otherState = Player(otherSource).state

    -- Connect the bystander to the call if neither side is muted
    if not participantState.mutedCall then
        addVoiceLink(otherSource, bystanderSource, otherSource)
    end
    if not otherState.mutedCall then
        addVoiceLink(bystanderSource, otherSource, callParticipantSource)
    end

    -- Also connect any other nearby bystanders on the other side
    for _, nearbySource in ipairs(otherNearby) do
        if otherState.speakerphone then
            if not participantState.mutedCall then
                addVoiceLink(nearbySource, bystanderSource, otherSource)
            end
            if not otherState.mutedCall then
                addVoiceLink(bystanderSource, nearbySource, callParticipantSource)
            end
        end
    end

    -- Track this bystander in the nearby list if not already present
    if not table.contains(myNearby, bystanderSource) then
        myNearby[#myNearby + 1] = bystanderSource
    end
end)

-- ─── leftCallProximity ─────────────────────────────────────────────────────────
-- Triggered when a bystander walks out of range of a phone call participant.
-- Disconnects the bystander from the call audio.
RegisterNetEvent("phone:phone:leftCallProximity")
AddEventHandler("phone:phone:leftCallProximity", function(callParticipantSource)
    local bystanderSource = source
    local _, _, callData  = IsInCall(callParticipantSource)

    if not callData or not callData.answered then return end

    local isCaller  = callData.caller.source == callParticipantSource
    local myNearby  = isCaller and callData.caller.nearby or callData.callee.nearby

    -- Only proceed if this bystander is tracked in the nearby list
    local found, idx = table.contains(myNearby, bystanderSource)
    if not found then return end

    local otherSource = isCaller and callData.callee.source or callData.caller.source
    if not otherSource then return end

    debugprint("phone:phone:leftCallProximity", DebugPlayerName(bystanderSource), DebugPlayerName(callParticipantSource))

    -- Disconnect bystander from the other call participant
    removeVoiceLink(otherSource, bystanderSource)
    table.remove(myNearby, idx)

    -- Disconnect bystander from all nearby listeners on the other side
    local otherNearby = isCaller and callData.callee.nearby or callData.caller.nearby
    for _, nearbySource in ipairs(otherNearby) do
        removeVoiceLink(nearbySource, bystanderSource)
    end
end)

-- ─── callEnded ─────────────────────────────────────────────────────────────────
-- Fired when a call ends. Cleans up all voice targets for any nearby bystanders
-- who were connected to the call via speakerphone.
AddEventHandler("lb-phone:callEnded", function(callData)
    local callerSource  = callData.caller.source
    local calleeSource  = callData.callee.source

    -- Clone nearby lists before the call data is cleaned up
    local callerNearby = callData.caller.nearby and table.clone(callData.caller.nearby) or nil
    local calleeNearby = callData.callee.nearby and table.clone(callData.callee.nearby) or nil

    -- Helper: remove all voice links between a nearby group and a participant
    local function cleanupNearby(nearbyList, participantSource, crossList)
        if not nearbyList or #nearbyList == 0 then return end

        TriggerClientEvent("phone:phone:removeVoiceTarget", participantSource, nearbyList, true)

        for _, nearbySource in ipairs(nearbyList) do
            TriggerClientEvent("phone:phone:removeVoiceTarget", nearbySource, participantSource, true)

            -- Also disconnect from the cross-side nearby list if present
            if crossList and #crossList > 0 then
                TriggerClientEvent("phone:phone:removeVoiceTarget", nearbySource, crossList, true)
            end
        end
    end

    if callerNearby and calleeSource then
        cleanupNearby(callerNearby, calleeSource, calleeNearby)
    end

    if calleeNearby and callerSource then
        cleanupNearby(calleeNearby, callerSource, callerNearby)
    end
end)