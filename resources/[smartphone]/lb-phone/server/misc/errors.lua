-- Receive a client-side UI crash report and log it server-side
RegisterNetEvent("phone:logError")
AddEventHandler("phone:logError", function(errorMsg, stack, componentStack)
  local version = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
  print(("[lb-phone] UI Error (v%s) | %s\nStack: %s\nComponent Stack: %s"):format(
    version,
    errorMsg,
    (stack or ""):sub(1, 800),
    (componentStack or ""):sub(1, 800)
  ))
end)