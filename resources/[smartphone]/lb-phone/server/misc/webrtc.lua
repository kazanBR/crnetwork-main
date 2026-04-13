local peerOwner  = {}
local playerPeers = {}
local peerLinks  = {}

-- ─── disconnectPeers ───────────────────────────────────────────────────────────
-- Ends the WebRTC connection between two peers and clears their link entry.
local function disconnectPeers(peerA, peerB)
    if not (peerLinks[peerA] and peerLinks[peerA][peerB]) then return end

    -- Notify peerA's owner that the call ended
    local ownerA = peerOwner[peerB]
    if ownerA then
        TriggerClientEvent("phone:webrtc:endCall", ownerA, peerA)
    end

    peerLinks[peerA][peerB] = nil
    peerLinks[peerB][peerA] = nil
end

-- ─── cleanupPlayer ─────────────────────────────────────────────────────────────
-- Removes all peers and connections belonging to a player source.
local function cleanupPlayer(playerSource)
    if not peerOwner[playerSource] then return end

    -- Disconnect all active peer links for this player's peers
    local playerPeerLinks = peerLinks[playerSource]
    if playerPeerLinks then
        for linkedPeer in pairs(playerPeerLinks) do
            disconnectPeers(playerSource, linkedPeer)
        end
        peerLinks[playerSource] = nil
    end

    -- Remove this player from their owner's peer list
    local ownerSource = peerOwner[playerSource]
    local ownerList   = playerPeers[ownerSource]
    if ownerList then
        for i, peerId in ipairs(ownerList) do
            if peerId == playerSource then
                table.remove(ownerList, i)
                break
            end
        end
        -- Clean up the owner entry entirely if no peers remain
        if #ownerList == 0 then
            playerPeers[ownerSource] = nil
        end
    end

    peerOwner[playerSource] = nil
end

-- ─── createdPeer ───────────────────────────────────────────────────────────────
-- Fired by a client when it creates a new WebRTC peer.
-- Registers the peer and associates it with the calling player.
RegisterNetEvent("phone:webrtc:createdPeer")
AddEventHandler("phone:webrtc:createdPeer", function(peerId)
    local playerSource = source

    -- Ignore if this peer ID is already registered
    if peerOwner[peerId] then return end

    peerOwner[peerId] = playerSource

    -- Add to the owner's peer list, creating it if needed
    if not playerPeers[playerSource] then
        playerPeers[playerSource] = {}
    end
    table.insert(playerPeers[playerSource], peerId)
end)

-- ─── deletedPeer ───────────────────────────────────────────────────────────────
-- Fired by a client when it destroys one of its WebRTC peers.
-- Only the peer's actual owner may delete it.
RegisterNetEvent("phone:webrtc:deletedPeer")
AddEventHandler("phone:webrtc:deletedPeer", function(peerId)
    local playerSource = source

    -- Reject if the caller doesn't own this peer
    if peerOwner[peerId] ~= playerSource then return end

    cleanupPlayer(peerId)
end)

-- ─── signal ────────────────────────────────────────────────────────────────────
-- Routes a WebRTC signal (offer, answer, ICE candidate, etc.) from one peer to another.
-- Both peers must exist and the sender must own the source peer.
RegisterNetEvent("phone:webrtc:signal")
AddEventHandler("phone:webrtc:signal", function(fromPeer, toPeer, signalData)
    local playerSource = source

    -- Validate: fromPeer must exist and be owned by the sender
    if not (peerOwner[fromPeer] and peerOwner[fromPeer] == playerSource) then return end

    -- Validate: toPeer must exist and fromPeer must still be owned by the sender
    if not (peerOwner[toPeer] and peerOwner[fromPeer] == playerSource) then return end

    -- If this is an offer, establish a bidirectional link between the two peers
    if signalData.type == "offer" then
        if not peerLinks[fromPeer] then peerLinks[fromPeer] = {} end
        if not peerLinks[toPeer]   then peerLinks[toPeer]   = {} end
        peerLinks[fromPeer][toPeer] = true
        peerLinks[toPeer][fromPeer] = true
    end

    -- Forward the signal to the target peer's owner
    TriggerClientEvent("phone:webrtc:signal", peerOwner[toPeer], {
        signalData = signalData,
        from       = fromPeer,
        target     = toPeer,
    })
end)

-- ─── playerDropped ─────────────────────────────────────────────────────────────
-- When a player disconnects, clean up all of their peers.
AddEventHandler("playerDropped", function()
    local playerSource = source

    local peers = playerPeers[playerSource]
    if not peers then return end

    -- Clone the list since cleanupPlayer mutates it during iteration
    local peersSnapshot = table.clone(peers)
    for _, peerId in ipairs(peersSnapshot) do
        cleanupPlayer(peerId)
    end

    playerPeers[playerSource] = nil
end)