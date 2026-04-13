-- Warn repeatedly if the resource has been renamed, as it will not function correctly
if GetCurrentResourceName() ~= "lb-phone" then
    Citizen.CreateThreadNow(function()
        while true do
            infoprint("error", "The resource name is not ^2lb-phone^7. The resource will not work properly. Please change the resource name to ^2lb-phone^7.")
            Wait(5000)
        end
    end)
end

-- Determine the correct resource identifier for the version endpoint
local resourceIdentifier = IS_BETA_VERSION and "lb-phone-beta" or "phone"

-- Read the version from the resource manifest, defaulting to 0.0.0 if absent
local resourceVersion = GetResourceMetadata(GetCurrentResourceName(), "version", 0) or "0.0.0"

-- POST version info to the loaf-scripts version tracking endpoint
local payload = json.encode({
    resource = resourceIdentifier,
    version  = resourceVersion,
})

PerformHttpRequest(
    "https://loaf-scripts.com/versions/",
    function(_, responseBody)
        if responseBody then print(responseBody) end
    end,
    "POST",
    payload,
    { ["Content-Type"] = "application/json" }
)