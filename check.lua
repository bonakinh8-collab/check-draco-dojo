local Config = _G.YummyConfig or {
    Target_RainbowHaki = true, Target_DaiCam = false, Target_DaiDen = false, Target_DaiTim = false,
    DaiCam = true, DaiDen = true, DaiTim = true,
    CDK = true, Godhuman = true, TTK = false, SoulGuitar = false,
    CheckInterval = 10, Prefix = "Completed-"
}

local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local commF = replicatedStorage:FindFirstChild("Remotes") and replicatedStorage.Remotes:FindFirstChild("CommF_")

-- Đưa Rainbow Haki lên làm Target
local TargetItems = {
    { key = "Target_RainbowHaki", name = "Rainbow Saviour", alias = "Rainbow" },
    { key = "Target_DaiCam", name = "Dojo Belt (Orange)", alias = "DaiCam" },
    { key = "Target_DaiDen", name = "Dojo Belt (Black)", alias = "DaiDen" },
    { key = "Target_DaiTim", name = "Dojo Belt (Purple)", alias = "DaiTim" }
}

-- Đưa các Đai xuống làm mục kiểm tra thêm (Extra) để ghi kèm vào file
local ExtraItems = {
    { key = "DaiCam", name = "Dojo Belt (Orange)", type = "Inv", alias = "DaiCam" },
    { key = "DaiDen", name = "Dojo Belt (Black)", type = "Inv", alias = "DaiDen" },
    { key = "DaiTim", name = "Dojo Belt (Purple)", type = "Inv", alias = "DaiTim" },
    { key = "CDK", name = "Cursed Dual Katana", type = "Inv", alias = "CDK" },
    { key = "TTK", name = "True Triple Katana", type = "Inv", alias = "TTK" },
    { key = "SoulGuitar", name = "Soul Guitar", type = "Inv", alias = "SG" },
    { key = "Godhuman", name = "Godhuman", type = "Melee", alias = "God" }
}

local function getInventoryMap()
    if not commF then return {} end
    local success, inventory = pcall(function() return commF:InvokeServer("getInventory") end)
    local map = {}
    if success and type(inventory) == "table" then
        for _, item in pairs(inventory) do map[item.Name] = true end
    end
    return map
end

local function hasMelee(meleeName)
    if player.Backpack:FindFirstChild(meleeName) or (player.Character and player.Character:FindFirstChild(meleeName)) then return true end
    if commF then
        local success, result = pcall(function() return commF:InvokeServer("Buy" .. meleeName, true) end)
        return (success and result and type(result) ~= "string")
    end
    return false
end

task.spawn(function()
    while task.wait(Config.CheckInterval or 10) do
        local invMap = getInventoryMap()
        local foundMainTarget = false
        local finalStatusText = ""

        for _, target in ipairs(TargetItems) do
            if Config[target.key] == true and invMap[target.name] then
                foundMainTarget = true
                finalStatusText = target.alias
                break 
            end
        end

        if foundMainTarget then
            for _, extra in ipairs(ExtraItems) do
                if Config[extra.key] == true then
                    local hasIt = false
                    if extra.type == "Inv" and invMap[extra.name] then hasIt = true
                    elseif extra.type == "Melee" and hasMelee(extra.name) then hasIt = true end
                    if hasIt then finalStatusText = finalStatusText .. "_" .. extra.alias end
                end
            end

            local fileContent = (Config.Prefix or "Completed-") .. finalStatusText
            local fileName = player.Name .. ".txt"
            
            if writefile then
                writefile(fileName, fileContent)
            end
            break 
        end
    end
end)
