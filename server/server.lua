local items = {
    "orange",   -- 1
    "lime",     -- 2
    "blueberry" -- 3
}

RegisterNetEvent('lonf_fruitpick:server:giveFruit', function()
    local src = source
    local reward = math.random(1, 5) -- Random Quantity of items
    local randomItem = math.random(1, #items)

    exports.ox_inventory:AddItem(src, items[randomItem], reward)
end)
