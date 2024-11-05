local config = lib.require 'config'
local inRoute = false
local fruitZones = {}
local cooldowns = {}

blipFruit = AddBlipForCoord(vec4(406.12, 6526.26, 27.76, 86.78))
SetBlipSprite(blipFruit, 280)
SetBlipColour(blipFruit, 29)
SetBlipScale(blipFruit, 0.8)
SetBlipAsShortRange(blipFruit, true)
BeginTextCommandSetBlipName('STRING')
AddTextComponentSubstringPlayerName('Fruit Picking') -- Name of Blip
EndTextCommandSetBlipName(blipFruit)

local function pickFruits()
    if inRoute then
        for index, tress in pairs(config.locations) do
            local zone = lib.zones.box({
                coords = tress,
                size = vec3(2.5, 2.5, 2),
                rotation = 90,
                debug = config.debugPoly,
                inside = function()
                    if IsControlJustReleased(0, 46) and not cooldowns[index] then
                        cooldowns[index] = true
                        lib.progressCircle({
                            duration = 3000,
                            position = 'bottom',
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                                move = true,
                                combat = true,
                                sprint = true
                            },
                            anim = {
                                dict = 'missmechanic',
                                clip = 'work_in'
                            }
                        })
                        TriggerServerEvent('lonf_fruitpick:server:giveFruit')

                        Citizen.SetTimeout(config.cooldownTime, function()
                            cooldowns[index] = false
                        end)
                    end
                end,
                onEnter = function()
                    if not cooldowns[index] then
                        lib.showTextUI('[E] - Pick Fruit', {
                            position = "right-center",
                            icon = 'hand',
                            style = {
                                borderRadius = 0,
                                backgroundColor = '#48BB78',
                                color = 'white'
                            }
                        })
                    end
                end,
                onExit = function()
                    if lib.isTextUIOpen() then
                        lib.hideTextUI()
                    end
                end
            })
            table.insert(fruitZones, zone)
        end
    end
end

local function clearZones()
    for _, zone in pairs(fruitZones) do
        zone:remove()
    end
    fruitZones = {}
end

local function updateInteraction()
    exports.ox_target:removeModel(config.model)

    if not inRoute then
        exports.ox_target:addModel(config.model, {
            {
                icon = 'fa-solid fa-check',
                label = 'Start Work',
                onSelect = function()
                    inRoute = true
                    updateInteraction()
                    pickFruits()
                    lib.notify({
                        description = 'In Service',
                        type = 'info'
                    })
                end,
                distance = 1.5,
            }
        })
    else
        exports.ox_target:addModel(config.model, {
            {
                icon = 'fa-solid fa-check',
                label = 'Stop Work',
                onSelect = function()
                    inRoute = false
                    updateInteraction()
                    clearZones()
                    lib.notify({
                        description = 'Out of Service',
                        type = 'info'
                    })
                end,
                distance = 1.5,
            }
        })
    end
end

local function SpawnPeds()
    local model = GetHashKey(config.model)
    RequestModel(model)

    while not HasModelLoaded(model) do
        Wait(1)
    end

    local pedModel = CreatePed(0, model, config.coords.x, config.coords.y, config.coords.z, config.coords.w, false, false)
    SetEntityInvincible(pedModel, true)
    FreezeEntityPosition(pedModel, true)
    SetBlockingOfNonTemporaryEvents(pedModel, true)
    SetModelAsNoLongerNeeded(pedModel)
    updateInteraction()
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SpawnPeds()
    end
end)
