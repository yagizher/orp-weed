ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local PlantsLoaded = false


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        if PlantsLoaded then
            TriggerClientEvent('orp:weed:client:updateWeedData', -1, Config.Plants)
        end
    end
end)

Citizen.CreateThread(function()
    TriggerEvent('orp:weed:server:getWeedPlants')
    print('PLANTS HAVE BEEN LOADED CUNT')
    PlantsLoaded = true
end)

ESX.RegisterUsableItem('weed_og-kush_seed', function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    TriggerClientEvent('orp:weed:client:plantNewSeed', src, 'og_kush')
    xPlayer.removeInventoryItem('weed_og-kush_seed', 1)
end)

ESX.RegisterUsableItem('weed_bananakush_seed', function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    TriggerClientEvent('orp:weed:client:plantNewSeed', src, 'banana_kush')
    xPlayer.removeInventoryItem('weed_bananakush_seed', 1)
end)

ESX.RegisterUsableItem('weed_bluedream_seed', function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    TriggerClientEvent('orp:weed:client:plantNewSeed', src, 'blue_dream')
    xPlayer.removeInventoryItem('weed_bluedream_seed', 1)
end)

ESX.RegisterUsableItem('weed_purple-haze_seed', function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    TriggerClientEvent('orp:weed:client:plantNewSeed', src, 'purplehaze')
    xPlayer.removeInventoryItem('weed_purple-haze_seed', 1)
end)

RegisterServerEvent('orp:weed:server:saveWeedPlant')
AddEventHandler('orp:weed:server:saveWeedPlant', function(data)
    local data = json.encode(data)
    
    MySQL.Async.execute('INSERT INTO weed_plants (properties) VALUES (@properties)', {
        ['@properties'] = data,
    }, function ()
    end)
end)

RegisterServerEvent('orp:server:checkPlayerHasThisItem')
AddEventHandler('orp:server:checkPlayerHasThisItem', function(item, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer.getInventoryItem(item).count > 0 then
        TriggerClientEvent(cb, src)
    else
        TriggerClientEvent('orp:weed:client:notify', src, 'You are missing ' .. item)
    end
end)

RegisterServerEvent('orp:weed:server:giveShittySeed')
AddEventHandler('orp:weed:server:giveShittySeed', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    xPlayer.addInventoryItem(Config.BadSeedReward, math.random(1, 2))
end)

RegisterServerEvent('orp:weed:server:plantNewSeed')
AddEventHandler('orp:weed:server:plantNewSeed', function(type, location)
    local src = source
    local plantId = math.random(111111, 999999)
    local xPlayer = ESX.GetPlayerFromId(src)
    local SeedData = {id = plantId, type = type, x = location.x, y = location.y, z = location.z, hunger = Config.StartingHunger, thirst = Config.StartingThirst, growth = 0.0, quality = 100.0, stage = 1, grace = true, beingHarvested = false, planter = xPlayer.identifier}

    local PlantCount = 0

    for k, v in pairs(Config.Plants) do
        if v.planter == xPlayer.identifier then
            PlantCount = PlantCount + 1
        end
    end

    if PlantCount >= Config.MaxPlantCount then
        TriggerClientEvent('orp:weed:client:notify', src, 'You already have ' .. Config.MaxPlantCount .. ' plants down')
    else
        table.insert(Config.Plants, SeedData)
        TriggerClientEvent('orp:weed:client:plantSeedConfirm', src)
        TriggerEvent('orp:weed:server:saveWeedPlant', SeedData)
        TriggerEvent('orp:weed:server:updatePlants')
    end
end)

RegisterServerEvent('orp:weed:plantHasBeenHarvested')
AddEventHandler('orp:weed:plantHasBeenHarvested', function(plantId)
    for k, v in pairs(Config.Plants) do
        if v.id == plantId then
            v.beingHarvested = true
        end
    end

    TriggerEvent('orp:weed:server:updatePlants')
end)

RegisterServerEvent('orp:weed:destroyPlant')
AddEventHandler('orp:weed:destroyPlant', function(plantId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    for k, v in pairs(Config.Plants) do
        if v.id == plantId then
            table.remove(Config.Plants, k)
        end
    end

    TriggerClientEvent('orp:weed:client:removeWeedObject', -1, plantId)
    TriggerEvent('orp:weed:server:weedPlantRemoved', plantId)
    TriggerEvent('orp:weed:server:updatePlants')
    TriggerClientEvent('orp:weed:client:notify', src, 'You destroy the weed plant')
end)

RegisterServerEvent('orp:weed:harvestWeed')
AddEventHandler('orp:weed:harvestWeed', function(plantId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local amount
    local label
    local item
    local goodQuality = false
    local hasFound = false

    for k, v in pairs(Config.Plants) do
        if v.id == plantId then
            for y = 1, #Config.YieldRewards do
                if v.type == Config.YieldRewards[y].type then
                    label = Config.YieldRewards[y].label
                    item = Config.YieldRewards[y].item
                    amount = math.random(Config.YieldRewards[y].rewardMin, Config.YieldRewards[y].rewardMax)
                    local quality = math.ceil(v.quality)
                    hasFound = true
                    table.remove(Config.Plants, k)
                    if quality > 94 then
                        goodQuality = true
                    end
                    amount = math.ceil(amount * (quality / 35))
                end
            end
        end
    end

    if hasFound then
        TriggerClientEvent('orp:weed:client:removeWeedObject', -1, plantId)
        TriggerEvent('orp:weed:server:weedPlantRemoved', plantId)
        TriggerEvent('orp:weed:server:updatePlants')
        if label ~= nil then
            TriggerClientEvent('orp:weed:client:notify', src, 'You harvest x' .. amount .. ' ' .. label)
        end
        xPlayer.addInventoryItem(item, amount)
        if goodQuality then
            if math.random(1, 10) > 3 then
                local seed = math.random(1, #Config.GoodSeedRewards)
                xPlayer.addInventoryItem(Config.GoodSeedRewards[seed], math.random(2, 4))
            end
        else
            xPlayer.addInventoryItem(Config.BadSeedRewards, math.random(1, 2))
        end
    else
        print('did not find')
    end
end)

RegisterServerEvent('orp:weed:server:updatePlants')
AddEventHandler('orp:weed:server:updatePlants', function()
    TriggerClientEvent('orp:weed:client:updateWeedData', -1, Config.Plants)
end)

RegisterServerEvent('orp:weed:server:waterPlant')
AddEventHandler('orp:weed:server:waterPlant', function(plantId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    for k, v in pairs(Config.Plants) do
        if v.id == plantId then
            Config.Plants[k].thirst = Config.Plants[k].thirst + Config.ThirstIncrease
            if Config.Plants[k].thirst > 100.0 then
                Config.Plants[k].thirst = 100.0
            end
        end
    end

    xPlayer.removeInventoryItem('water', 1)
    TriggerEvent('orp:weed:server:updatePlants')
end)

RegisterServerEvent('orp:weed:server:feedPlant')
AddEventHandler('orp:weed:server:feedPlant', function(plantId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    for k, v in pairs(Config.Plants) do
        if v.id == plantId then
            Config.Plants[k].hunger = Config.Plants[k].hunger + Config.HungerIncrease
            if Config.Plants[k].hunger > 100.0 then
                Config.Plants[k].hunger = 100.0
            end
        end
    end

    xPlayer.removeInventoryItem('fertilizer', 1)
    TriggerEvent('orp:weed:server:updatePlants')
end)

RegisterServerEvent('orp:weed:server:updateWeedPlant')
AddEventHandler('orp:weed:server:updateWeedPlant', function(id, data)
    local result = MySQL.Sync.fetchAll('SELECT * FROM weed_plants')

    if result[1] then
        for i = 1, #result do
            local plantData = json.decode(result[i].properties)
            if plantData.id == id then
                local newData = json.encode(data)
                MySQL.Async.execute('UPDATE weed_plants SET properties = @properties WHERE id = @id', {
                    ['@properties'] = newData,
                    ['@id'] = result[i].id,
                }, function ()
                end)
            end
        end
    end
end)

RegisterServerEvent('orp:weed:server:weedPlantRemoved')
AddEventHandler('orp:weed:server:weedPlantRemoved', function(plantId)
    local result = MySQL.Sync.fetchAll('SELECT * FROM weed_plants')

    if result then
        for i = 1, #result do
            local plantData = json.decode(result[i].properties)
            if plantData.id == plantId then

                MySQL.Async.execute('DELETE FROM weed_plants WHERE id = @id', {
                    ['@id'] = result[i].id
                })

                for k, v in pairs(Config.Plants) do
                    if v.id == plantId then
                        table.remove(Config.Plants, k)
                    end
                end
            end
        end
    end
end)

RegisterServerEvent('orp:weed:server:getWeedPlants')
AddEventHandler('orp:weed:server:getWeedPlants', function()
    local data = {}
    local result = MySQL.Sync.fetchAll('SELECT * FROM weed_plants')

    if result[1] then
        for i = 1, #result do
            local plantData = json.decode(result[i].properties)
            print(plantData.id)
            table.insert(Config.Plants, plantData)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        -- Citizen.Wait(math.random(65000, 75000))
        Citizen.Wait(math.random(20000, 25000))
        -- Citizen.Wait(300)
        for i = 1, #Config.Plants do
            if Config.Plants[i].growth < 100 then
                if Config.Plants[i].grace then
                    Config.Plants[i].grace = false
                else
                    Config.Plants[i].thirst = Config.Plants[i].thirst - math.random(Config.Degrade.min, Config.Degrade.max) / 10
                    Config.Plants[i].hunger = Config.Plants[i].hunger - math.random(Config.Degrade.min, Config.Degrade.max) / 10
                    Config.Plants[i].growth = Config.Plants[i].growth + math.random(Config.GrowthIncrease.min, Config.GrowthIncrease.max) / 10

                    if Config.Plants[i].growth > 100 then
                        Config.Plants[i].growth = 100
                    end

                    if Config.Plants[i].hunger < 0 then
                        Config.Plants[i].hunger = 0
                    end

                    if Config.Plants[i].thirst < 0 then
                        Config.Plants[i].thirst = 0
                    end

                    if Config.Plants[i].quality < 25 then
                        Config.Plants[i].quality = 25
                    end

                    if Config.Plants[i].thirst < 75 or Config.Plants[i].hunger < 75 then
                        Config.Plants[i].quality = Config.Plants[i].quality - math.random(Config.QualityDegrade.min, Config.QualityDegrade.max) / 10
                    end

                    if Config.Plants[i].stage == 1 and Config.Plants[i].growth >= 55 then
                        Config.Plants[i].stage = 2
                    elseif Config.Plants[i].stage == 2 and Config.Plants[i].growth >= 90 then
                        Config.Plants[i].stage = 3
                    end
                end
            end
            TriggerEvent('orp:weed:server:updateWeedPlant', Config.Plants[i].id, Config.Plants[i])
        end
        TriggerEvent('orp:weed:server:updatePlants')
    end
end)
