---@alias AnimationAction "default" | "call" | "camera"

---@type { [string]: boolean }
local loadedDicts = {}
local phoneModel = Config.PhoneModel or `prop_amb_phone`
local rotation = Config.PhoneRotation or vector3(0.0, 0.0, 180.0)
local offset = Config.PhoneOffset or vector3(0.0, -0.005, 0.0)
local animationsDisabled = false
---@type AnimationAction?
local currentAction
---@type number?
local phoneObject
---@type number?
local phoneVariation
---@type number?
local textureVariation
---@type string?
local oldFrameColor
local phoneAnimations = {
    default = {
        onFoot = {
            open = {
                dict = "cellphone@",
                anim = "cellphone_text_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@",
                anim = "cellphone_text_read_base",
                flag = 2 | 16 | 32 ,
                blendInSpeed = 1000.0,
            },
            close = {
                dict = "cellphone@",
                anim = "cellphone_text_out",
                flag = 16 | 32
            }
        },
        inCar = {
            open = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_text_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_text_read_base",
                flag = 2 | 16 | 32 ,
                blendInSpeed = 1000.0
            },
            close = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_text_out",
                flag = 16 | 32
            }
        },
    },
    call = {
        onFoot = {
            open = {
                dict = "cellphone@",
                anim = "cellphone_call_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@",
                anim = "cellphone_call_listen_base",
                flag = 2 | 16 | 32 ,
            },
            close = {
                dict = "cellphone@",
                anim = "cellphone_call_out",
                flag = 16 | 32
            }
        },
        inCar = {
            open = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_call_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_call_listen_base",
                flag = 2 | 16 | 32 ,
            },
            close = {
                dict = "cellphone@in_car@ds",
                anim = "cellphone_call_out",
                flag = 16 | 32
            }
        },
    },
    camera = {
        onFoot = {
            open = {
                dict = "cellphone@self",
                anim = "selfie_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@self",
                anim = "selfie_in",
                flag = 2 | 16 | 32 ,
                blendInSpeed = 1000.0,
                blendOutSpeed = -1000.0,
            },
            close = {
                dict = "cellphone@self",
                anim = "selfie_out",
                flag = 16 | 32
            }
        },
        inCar = {
            open = {
                dict = "cellphone@self",
                anim = "selfie_in",
                flag = 2 | 16 | 32
            },
            base = {
                dict = "cellphone@self",
                anim = "selfie",
                flag = 2 | 16 | 32 ,
            },
            close = {
                dict = "cellphone@self",
                anim = "selfie_out",
                flag = 16 | 32
            }
        },
    }
}

CreateThread(function()
    while not loaded do
        Wait(500)
    end

    phoneModel = Config.PhoneModel or phoneModel

    if not IsModelValid(phoneModel) then
        phoneModel = `prop_amb_phone`
    end
end)

---@param dict string
local function LoadDict(dict)
    RequestAnimDict(dict)

    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end

    loadedDicts[dict] = true

    return dict
end

local handleAnimationsInterval = Interval:new(function(self)
    local playerPed = PlayerPedId()
    local inCar = IsPedInAnyVehicle(playerPed, true)

    if not self.enabled then
        return
    end

    local animData = phoneAnimations[currentAction][inCar and "inCar" or "onFoot"]

    if animData then
        local baseData = animData.base

        if not IsEntityPlayingAnim(playerPed, animData.open.dict, animData.open.anim, 3) and not IsEntityPlayingAnim(playerPed, baseData.dict, baseData.anim, 3) then
            TaskPlayAnim(playerPed, LoadDict(baseData.dict), baseData.anim, baseData.blendInSpeed or 8.0, baseData.blendOutSpeed or -8.0, -1, baseData.flag | 8 | 1048576, 0, false, false, false)
        end
    end
end, 500, false)

function handleAnimationsInterval.onStart()
    debugprint("Started phone animations interval")
end

function handleAnimationsInterval.onStop()
    debugprint("Stopped phone animations interval")
end

function RefreshAnimationsInterval()
    handleAnimationsInterval:toggle(
        (phoneOpen or (IsInCall() and not InExportCall) or IsWalkingCamEnabled())
        and not (cameraOpen and not IsWalkingCamEnabled())
        and currentAction
        and not animationsDisabled
    )
end

-- Handle phone object

---@class AttachPhoneOptions
---@field phone? number # The phone object to attach, if not provided will use the existing phone object
---@field ped? number # If not provided, will use the player ped
---@field variation? number
---@field landscape? boolean # Whether the phone is in landscape mode or not

---@param options? AttachPhoneOptions
function AttachPhone(options)
    local phone = options and options.phone
    local ped = options and options.ped
    local variation = options and options.variation
    local landscape = options and options.landscape

    if not phone then
        if not phoneObject then
            return
        end

        phone = phoneObject
    end

    if not ped then
        ped = PlayerPedId()
        variation = phoneVariation
    end

    local itemData = variation and Config.Item.Names and Config.Item.Names[variation]
    local phoneOffset = itemData and itemData.offset or Config.PhoneOffset or vector3(0.0, -0.005, 0.0)
    local phoneRotation = itemData and itemData.rotation or Config.PhoneRotation or vector3(0.0, 0.0, 180.0)

    if landscape then
        phoneOffset = itemData and itemData.landscapeOffset or Config.LandscapeOffset or vector3(-0.03, -0.005, -0.02)
        phoneRotation = itemData and itemData.landscapeRotation or Config.LandscapeRotation or vector3(0.0, 90.0, 180.0)
    end

    AttachEntityToEntity(
        phone, ped,
        GetPedBoneIndex(ped, 28422),
        phoneOffset.x, phoneOffset.y, phoneOffset.z,
        phoneRotation.x, phoneRotation.y, phoneRotation.z,
        false, false, false, false, 2, true
    )
end

local function CreatePhoneObject()
    if phoneObject and DoesEntityExist(phoneObject) then
        return
    end

    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed, false)

    if Config.PropSpawn == "server" then
        if not IsModelValid(phoneModel) then
            debugprint("phoneModel is not valid")
            return
        end

        local netId = AwaitCallback("createPhoneObject", phoneModel)

        if not netId then
            debugprint("Failed to create phone object")
            return
        end

        local entity = WaitForNetworkId(netId)

        if not entity then
            debugprint("Failed to get phone object")
            TriggerServerEvent("phone:failedControl")
            return
        end

        if not TakeControlOfEntity(entity) then
            debugprint("Failed to take control of phone object")
            TriggerServerEvent("phone:failedControl")
            return
        end

        if phoneObject then
            DeleteEntity(entity)
        else
            phoneObject = entity
        end
    else
        if not IsModelValid(phoneModel) then
            debugprint("Could not load phone model")
            return
        end

        LoadModel(phoneModel)

        local networked = Config.PropSpawn ~= "state"

        if phoneObject then
            DeleteEntity(phoneObject)
        end

        phoneObject = CreateObject(phoneModel, coords.x, coords.y, coords.z, networked, true, true)
    end

    if textureVariation then
        SetObjectTextureVariation(phoneObject, textureVariation)
    end

    SetEntityCollision(phoneObject, false, false)
    SetModelAsNoLongerNeeded(phoneModel)
    AttachPhone()

    if Config.PropSpawn ~= "state" then
        TriggerServerEvent("phone:setPhoneObject", NetworkGetNetworkIdFromEntity(phoneObject))
    end
end

local function DeletePhoneObject()
    if not phoneObject then
        return
    end

    DeleteEntity(phoneObject)

    if Config.PropSpawn ~= "state" then
        TriggerServerEvent("phone:setPhoneObject", nil)
    end

    phoneObject = nil
end

---@return number?
function GetPhoneObject()
    return phoneObject
end

local function PlayOpenAnim(action)
    local inCar = IsPedInAnyVehicle(PlayerPedId(), true)
    local animData = phoneAnimations[action][inCar and "inCar" or "onFoot"].open
    local dict = LoadDict(animData.dict)
    local anim = animData.anim
    local flag = animData.flag

    TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, -8.0, -1, flag | 8 | 1048576, 0, false, false, false)

    return GetAnimDuration(dict, anim) * 1000
end

local function CleanUpAssets()
    for dict, loaded in pairs(loadedDicts) do
        if loaded then
            RemoveAnimDict(dict)

            loadedDicts[dict] = nil
        end
    end

    SetModelAsNoLongerNeeded(phoneModel)
end

function PlayCloseAnim()
    if IsInCall() or InExportCall or (not cameraOpen and IsWalkingCamEnabled()) or not currentAction then
        return
    end

    RefreshAnimationsInterval()

    local inCar = IsPedInAnyVehicle(PlayerPedId(), true)
    local animData = phoneAnimations[currentAction][inCar and "inCar" or "onFoot"].close

    if animData then
        TaskPlayAnim(PlayerPedId(), LoadDict(animData.dict), animData.anim, 8.0, -8.0, 950, animData.flag | 1048576, 0, false, false, false)
        Wait(300)
    end

    DeletePhoneObject()
    CleanUpAssets()
end

---@param action AnimationAction
function SetPhoneAction(action)
    if (action == currentAction and not phoneOpen) or (action ~= "call" and not phoneOpen) or not phoneAnimations[action] or InExportCall then
        return
    end

    local playOpen = true

    if currentAction then
        for _, v in pairs({"inCar", "onFoot"}) do
            local currentAnim = phoneAnimations[currentAction][v]

            if IsEntityPlayingAnim(PlayerPedId(), currentAnim.open.dict, currentAnim.open.anim, 3) or IsEntityPlayingAnim(PlayerPedId(), currentAnim.base.dict, currentAnim.base.anim, 3) then
                playOpen = false
            end
        end
    end

    if not playOpen then
        currentAction = action
        RefreshAnimationsInterval()
        return
    end

    Citizen.CreateThreadNow(function()
        PlayOpenAnim(action)

        currentAction = action

        Wait(300)
        CreatePhoneObject()
        RefreshAnimationsInterval()
    end)
end

---@param enabled boolean
---@param action? AnimationAction
function TogglePhoneAnimation(enabled, action)
    animationsDisabled = enabled == false

    if enabled then
        SetPhoneAction(action or "default")
    elseif action ~= "camera" then
        PlayCloseAnim()
    end

    RefreshAnimationsInterval()
end

---@param variation number
function SetPhoneVariation(variation)
    local itemData = Config.Item.Names[variation]

    if not itemData then
        infoprint("error", "SetPhoneVariation", "Invalid phone variation: " .. tostring(variation))
        return
    end

    if phoneVariation == variation then
        if itemData.frameColor then
            SendReactMessage("setFrameColor", itemData.frameColor)
            SendReactMessage("updateConfigValue", {
                config = {
                    allowFrameColorChange = false,
                    frameColor = itemData.frameColor
                }
            })
        end

        return
    end

    phoneVariation = variation
    phoneModel = itemData.model or phoneModel
    offset = itemData.offset or Config.PhoneOffset or offset
    rotation = itemData.rotation or Config.PhoneRotation or rotation
    textureVariation = itemData.textureVariation

    debugprint("Set phone variation to " .. variation)
    LocalPlayer.state:set("lbPhoneVariation", variation, true)
    SetResourceKvpInt("phone_variation", variation)

    if itemData.frameColor then
        if settings?.display?.frameColor ~= itemData.frameColor then
            oldFrameColor = settings?.display?.frameColor
        end

        SendReactMessage("setFrameColor", itemData.frameColor)
        SendReactMessage("updateConfigValue", {
            config = {
                allowFrameColorChange = false,
                frameColor = itemData.frameColor
            }
        })
    else
        if oldFrameColor then
            SendReactMessage("setFrameColor", oldFrameColor)
        else
            SendReactMessage("setFrameColor", Config.FrameColor)
        end

        SendReactMessage("updateConfigValue", {
            config = {
                allowFrameColorChange = Config.AllowFrameColorChange,
                frameColor = Config.FrameColor
            }
        })
    end
end

exports("SetPhoneVariation", SetPhoneVariation)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        DeletePhoneObject()
    end
end)
