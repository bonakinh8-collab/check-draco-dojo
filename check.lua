local Config = _G.YummyConfig or {}
local player = game.Players.LocalPlayer
local commF = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 9e9):WaitForChild("CommF_", 9e9)

local function getInventoryMap()
    local success, inventory = pcall(function() return commF:InvokeServer("getInventory") end)
    local map = {}
    if success and type(inventory) == "table" then
        for _, item in pairs(inventory) do map[item.Name] = true end
    end
    return map
end

local function checkRainbowHaki()
    if player:FindFirstChild("Data") then
        for _, v in pairs(player.Data:GetDescendants()) do
            if v:IsA("StringValue") and (v.Value == "Rainbow Saviour" or v.Value == "Final Hero" or v.Name == "Rainbow Saviour") then
                return true
            end
        end
    end
    local success, titles = pcall(function() return commF:InvokeServer("getTitles") end)
    if success and type(titles) == "table" then
        for _, title in pairs(titles) do
            if title == "Final Hero" or title == "Rainbow Saviour" then return true end
        end
    end
    return false
end

local function hasMelee(meleeName)
    if player.Backpack:FindFirstChild(meleeName) or (player.Character and player.Character:FindFirstChild(meleeName)) then return true end
    local success, result = pcall(function() return commF:InvokeServer("Buy" .. meleeName, true) end)
    return (success and result and type(result) ~= "string")
end

local TargetItems = {
    { key = "Target_DaiCam", name = "Dojo Belt (Orange)", alias = "DaiCam" },
    { key = "Target_DaiDen", name = "Dojo Belt (Black)", alias = "DaiDen" },
    { key = "Target_DaiTim", name = "Dojo Belt (Purple)", alias = "DaiTim" }
}

local ExtraItems = {
    { key = "DaiCam", name = "Dojo Belt (Orange)", alias = "DaiCam" },
    { key = "DaiDen", name = "Dojo Belt (Black)", alias = "DaiDen" },
    { key = "DaiTim", name = "Dojo Belt (Purple)", alias = "DaiTim" },
    { key = "CDK", name = "Cursed Dual Katana", alias = "CDK" },
    { key = "TTK", name = "True Triple Katana", alias = "TTK" },
    { key = "SoulGuitar", name = "Soul Guitar", alias = "SG" }
}

task.spawn(function()
    while task.wait(Config.CheckInterval or 10) do
        local invMap = getInventoryMap()
        local ownsRainbow = checkRainbowHaki()
        
        local foundMainTarget = false
        local finalStatus = ""

        if Config.Target_RainbowHaki and ownsRainbow then
            foundMainTarget = true
            finalStatus = "RB"
        else
            for _, target in ipairs(TargetItems) do
                if Config[target.key] and invMap[target.name] then
                    foundMainTarget = true
                    finalStatus = target.alias
                    break 
                end
            end
        end

        if foundMainTarget then
            if not string.find(finalStatus, "RB") and ownsRainbow then
                finalStatus = finalStatus .. "_RB"
            end

            for _, extra in ipairs(ExtraItems) do
                if Config[extra.key] and invMap[extra.name] and not string.find(finalStatus, extra.alias) then
                    finalStatus = finalStatus .. "_" .. extra.alias
                end
            end
            
            if Config.Godhuman and hasMelee("Godhuman") and not string.find(finalStatus, "God") then
                finalStatus = finalStatus .. "_God"
            end

            local fileContent = (Config.Prefix or "Completed-") .. finalStatus
            local fileName = player.Name .. ".txt"
            
            if writefile then
                writefile(fileName, fileContent)
            end
            break
        end
    end
end)
