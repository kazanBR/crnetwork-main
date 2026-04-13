local alreadyDead = false

local function JustDied()
    alreadyDead = true

    if OnDeath then
        OnDeath()
    else
        -- OnDeath not yet available (load order race); close phone manually
        if phoneOpen then
            ToggleOpen(false)
        end
    end

    while IsPedDeadOrDying(PlayerPedId(), false) or ESX?.PlayerData?.dead do
        Wait(500)
    end

    alreadyDead = false
end

AddEventHandler("CEventDeath", function(entities, entity, data)
    if entities[1] == PlayerPedId() and not alreadyDead then
        JustDied()
    end
end)

AddEventHandler("CEventEntityDamaged", function()
    if IsPedDeadOrDying(PlayerPedId(), false) and not alreadyDead then
        JustDied()
    end
end)
