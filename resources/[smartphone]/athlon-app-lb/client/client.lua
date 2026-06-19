local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vSERVER = Tunnel.getInterface(GetCurrentResourceName())

local currentVehicle = nil
local currentKey = nil
local tuneData = {} 
local lastCutTime = 0
local cutCooldown = 100
local lastIdlePopTime = 0

local monitoredVehicle = nil

-- =========================
-- Helpers
-- =========================

local function normalizePlate(plate)
    if not plate then return nil end
    plate = string.upper(plate)
    plate = plate:gsub("%s+", "")
    return plate
end

local function makeTuneKey(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return nil end
    local plate = normalizePlate(GetVehicleNumberPlateText(vehicle))
    local model = GetEntityModel(vehicle)
    if not plate or not model then return nil end
    return plate .. "_" .. tostring(model)
end

-- =========================
-- Registro no lb-phone
-- =========================
CreateThread(function()
    while GetResourceState("lb-phone") ~= "started" do Wait(1000) end

    exports['lb-phone']:AddCustomApp({
        identifier = 'athlon_ecu',
        name = 'Athlon ECU',
        description = 'ECU Manager',
        developer = 'Athlon',
        defaultApp = true,
        fixBlur = true,
        size = 50000,
        ui = GetCurrentResourceName() .. '/web/index.html',
        icon = 'https://3dmods.com.br/smartphone/athlon.png'
    })

    print("^2[Athlon] App registrado no lb-phone.^7")
end)

-- =========================
-- Efeitos de Pipoco Sincronizados
-- =========================
local function sendPipocoAndEffects(vehicle, intensity)
    exports["lb-phone"]:SendCustomAppMessage("athlon_ecu", { action = "pipoco",intensity = intensity or 1.0 })
   -- SendNUIMessage({ action = "pipoco", intensity = intensity or 1.0 })

    -- Envia para o servidor sincronizar com quem está perto
    if vehicle and DoesEntityExist(vehicle) then
        TriggerServerEvent("athlon:server:triggerFoguinho", VehToNet(vehicle), intensity or 1.0)
    end
end

-- =========================
-- Lógica de Corte
-- =========================
local function applyCutSequence(vehicle, limit, type)
    local limitNum = tonumber(limit) or 9500
    limitNum = math.max(4900, math.min(12000, limitNum))
    
    -- Alvo do ponteiro (0.0 a 1.0)
    local targetRpm = math.max(0.35, math.min(0.98, (limitNum / 12000)))

    for i = 1, 3 do
        SetVehicleCurrentRpm(vehicle, targetRpm)
        
        -- AQUI: Garante que o som saia para todos
        if type == "ignicao" then
            -- Ignição: Estouro alto + Fogo
            sendPipocoAndEffects(vehicle, 1.0 - (i-1)*0.2)
        elseif type == "injecao" then
            -- Injeção: Apenas "falha" motor.
            -- DICA: Para outros ouvirem o corte de injeção, podemos simular um estouro MUITO baixo ou mudo visualmente
            -- Mas por enquanto, vamos manter sem pipoco para ser realista (apenas som do motor travando)
        end

        Wait(40) 
        SetVehicleCurrentRpm(vehicle, targetRpm)
        Wait(25)
    end
end

-- =========================
-- Loop Principal
-- =========================
CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(ped, false)
        
        -- Detecta veículo atual ou o último usado (se estiver perto e ligado)
        local vehToCheck = nil
        
        if inVehicle then
            vehToCheck = GetVehiclePedIsIn(ped, false)
            monitoredVehicle = vehToCheck -- Atualiza o veículo monitorado
        else
            -- Se saiu do carro, verifica se ainda estamos perto do último monitorado e se ele está ligado
            if monitoredVehicle and DoesEntityExist(monitoredVehicle) then
                local dist = #(GetEntityCoords(ped) - GetEntityCoords(monitoredVehicle))
                if dist < 20.0 and GetIsVehicleEngineRunning(monitoredVehicle) then
                    vehToCheck = monitoredVehicle
                else
                    monitoredVehicle = nil -- Parou de monitorar (longe ou desligado)
                end
            end
        end

        if vehToCheck then
            local model = GetEntityModel(vehToCheck)
            
            -- Só processa motos
            if IsThisModelABike(model) then
                sleep = 20 -- Loop rápido para cortes e dashboard
                
                -- Se trocou de veículo, recarrega configs
                local key = makeTuneKey(vehToCheck)
                if key ~= currentKey then
                    currentKey = key
                    tuneData = {}
                    if currentKey then
                        TriggerServerEvent('athlon:server:getTune', currentKey)
                    end
                end

                -- Variáveis de telemetria
                local rawRpm = GetVehicleDashboardRpm(vehToCheck)
                local rpm = math.floor(rawRpm)
                if rpm < 10 then rpm = math.floor(GetVehicleCurrentRpm(vehToCheck) * 10000) end
                
                local tps = math.floor(GetControlNormal(0, 71) * 100) -- Isso só funciona se estiver DIRIGINDO
                
                -- Se estiver FORA da moto, TPS é 0 (ninguém acelerando)
                if not inVehicle then tps = 0 end

                local temp = math.floor(GetVehicleEngineTemperature(vehToCheck))
                if temp <= 0 and GetIsVehicleEngineRunning(vehToCheck) then temp = 65 end
                local fuel = math.floor(GetVehicleFuelLevel(vehToCheck) or 0)

            
                if inVehicle then
                      exports["lb-phone"]:SendCustomAppMessage("athlon_ecu", { action = "updateDash", data = { rpm = rpm, tps = tps, temp = temp, fuel = fuel } })
                    -- SendNUIMessage({
                    --     action = "updateDash",
                    --     data = { rpm = rpm, tps = tps, temp = temp, fuel = fuel }
                    -- })
                end

                local now = GetGameTimer()

                -- =========================
                -- CORTE DE GIRO (Só funciona se alguém estiver acelerando, ou seja, dentro)
                -- =========================
                -- Verifica se é o motorista para aplicar corte
                if inVehicle and GetPedInVehicleSeat(vehToCheck, -1) == ped then
                    if tuneData.rpmLimit and tuneData.cutType and tuneData.cutType ~= "none" then
                        if rpm >= tuneData.rpmLimit and (now - lastCutTime) >= cutCooldown then
                            applyCutSequence(vehToCheck, tuneData.rpmLimit, tuneData.cutType)
                            lastCutTime = now
                        end
                    end
                end

                -- =========================
                -- PONTO MORTO EXPLOSIVO (Idle Pop)
                -- =========================
                -- Funciona DENTRO ou FORA, desde que motor ligado e TPS 0
                if tuneData.idlePop and tuneData.idlePop == true then
                    if tps == 0 and rpm < 3800 and rpm > 800 and GetIsVehicleEngineRunning(vehToCheck) then
                        -- Lógica aleatória
                        if (now - lastIdlePopTime) > math.random(800, 2500) then
                            -- Verifica dono da rede para não duplicar eventos
                            if NetworkGetEntityOwner(vehToCheck) == PlayerId() then
                                sendPipocoAndEffects(vehToCheck, 0.4) 
                            end
                            lastIdlePopTime = now
                        end
                    end
                end

            else
                -- Não é moto
                currentKey = nil
                tuneData = {}
                sleep = 1000
            end
        else
            -- Nenhum veículo relevante
            sleep = 1000
        end

        Wait(sleep)
    end
end)

-- =========================
-- Receber tune
-- =========================
RegisterNetEvent('athlon:client:receiveTune', function(data)
    if data then
        if data.rpmLimit then
            local lim = tonumber(data.rpmLimit) or 9500
            data.rpmLimit = math.max(4900, math.min(12000, lim))
        end
        tuneData = data
      exports["lb-phone"]:SendCustomAppMessage("athlon_ecu", { action = "loadTune", data = tuneData })
      --  SendNUIMessage({ action = "loadTune", data = tuneData })
    else
        tuneData = {}
         exports["lb-phone"]:SendCustomAppMessage("athlon_ecu", { action = "loadTune", data = {} })
       -- SendNUIMessage({ action = "loadTune", data = {} })
    end
end)

-- =========================
-- Salvar
-- =========================
RegisterNUICallback("saveData", function(data, cb)
    if not currentKey then cb("error"); return end
    
    for k,v in pairs(data) do
        tuneData[k] = v
    end

    if tuneData.rpmLimit then
        local lim = tonumber(tuneData.rpmLimit) or 9500
        tuneData.rpmLimit = math.max(4900, math.min(12000, lim))
    end

    TriggerServerEvent("athlon:server:saveTune", currentKey, tuneData)
    cb("ok")
end)

-- =========================
-- Evento Visual (Foguinho + Som)
-- =========================
RegisterNetEvent("athlon:client:spawnFoguinho")
AddEventHandler("athlon:client:spawnFoguinho", function(netVeh, intensity)
    if not netVeh then return end

    local netId = tonumber(netVeh) or netVeh
    if type(netId) ~= "number" or not NetworkDoesNetworkIdExist(netId) then return end

    local veh = NetToVeh(netId)
    if not veh or not DoesEntityExist(veh) then return end

    local pos = GetEntityCoords(veh)
    local ped = PlayerPedId()
    local myPos = GetEntityCoords(ped)
    
    if #(myPos - pos) <= 50.0 then -- Aumentei raio de audição/visão
        local exhausts = { "exhaust", "exhaust_2", "exhaust_3", "exhaust_4", "exhaust_5", "exhaust_6" }
        local fxGroup = "core"
        local fxName = "veh_backfire"
        
        for _, bone in ipairs(exhausts) do
            local boneIndex = GetEntityBoneIndexByName(veh, bone)
            if boneIndex and boneIndex ~= -1 then
                UseParticleFxAssetNextCall(fxGroup)
                local startFx = StartParticleFxLoopedOnEntityBone(fxName, veh, 0.0,0.0,0.0,0.0,0.0,0.0, boneIndex, Config.flameSize or 1.2, false, false, false)
                StopParticleFxLooped(startFx, true)
            end
        end

        -- Somente o dono da rede cria a explosão física (Anti-Ban Safe)
        if NetworkGetEntityOwner(veh) == PlayerId() then
            AddExplosion(pos.x, pos.y, pos.z, 61, 0.0, true, true, 0.0, true)
        end

        -- Som via NUI para TODOS que receberam o evento (Sincronia de áudio)
        local fileIndex = tostring(math.random(1,6))
        local volume = math.max(0.5, tonumber(intensity) or 5.0)
         exports["lb-phone"]:SendCustomAppMessage("athlon_ecu", { action = "playSoundByFile",file = fileIndex, volume = volume})
      --  SendNUIMessage({ action = "playSoundByFile", file = fileIndex, volume = volume })
    end
end)