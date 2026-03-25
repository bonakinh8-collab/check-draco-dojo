local Config = _G.YummyConfig or {
    Target_RainbowHaki = true, Target_DaiCam = false, Target_DaiDen = false, Target_DaiTim = false,
    DaiCam = true, DaiDen = true, DaiTim = true, CDK = true, Godhuman = true, TTK = false, SoulGuitar = false,
    CheckInterval = 10, Prefix = "Completed-"
}

-- 1. CHỜ GAME LOAD ĐẦY ĐỦ (Chống kẹt trơ trơ)
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer

local replicatedStorage = game:GetService("ReplicatedStorage")
local commF = replicatedStorage:WaitForChild("Remotes", 9e9):WaitForChild("CommF_", 9e9)

-- 2. DANH SÁCH MỤC TIÊU
local TargetItems = {
    { key = "Target_RainbowHaki", name = "Rainbow Saviour", alias = "Rainbow" },
    { key = "Target_DaiCam", name = "Dojo Belt (Orange)", alias = "DaiCam" },
    { key = "Target_DaiDen", name = "Dojo Belt (Black)", alias = "DaiDen" },
    { key = "Target_DaiTim", name = "Dojo Belt (Purple)", alias = "DaiTim" }
}

local ExtraItems = {
    { key = "DaiCam", name = "Dojo Belt (Orange)", type = "Inv", alias = "DaiCam" },
    { key = "DaiDen", name = "Dojo Belt (Black)", type = "Inv", alias = "DaiDen" },
    { key = "DaiTim", name = "Dojo Belt (Purple)", type = "Inv", alias = "DaiTim" },
    { key = "CDK", name = "Cursed Dual Katana", type = "Inv", alias = "CDK" },
    { key = "TTK", name = "True Triple Katana", type = "Inv", alias = "TTK" },
    { key = "SoulGuitar", name = "Soul Guitar", type = "Inv", alias = "SG" },
    { key = "Godhuman", name = "Godhuman", type = "Melee", alias = "God" }
}

-- 3. CÁC HÀM QUÉT
local function getInventoryMap()
    local map = {}
    local success, inventory = pcall(function() return commF:InvokeServer("getInventory") end)
    if success and type(inventory) == "table" then
        for _, item in pairs(inventory) do map[item.Name] = true end
    end
    return map
end

local function hasMelee(meleeName)
    if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild(meleeName) then return true end
    if player.Character and player.Character:FindFirstChild(meleeName) then return true end
    local success, result = pcall(function() return commF:InvokeServer("Buy" .. meleeName, true) end)
    return (success and result and type(result) ~= "string")
end

local function checkRainbowHaki()
    -- Lưới quét Data ẩn
    local function scanFolder(folder)
        for _, v in pairs(folder:GetChildren()) do
            if v:IsA("StringValue") and (v.Value == "Rainbow Saviour" or v.Name == "Rainbow Saviour" or v.Value == "Final Hero") then
                return true
            elseif v:IsA("Folder") or v:IsA("Configuration") then
                if scanFolder(v) then return true end
            end
        end
        return false
    end
    if player:FindFirstChild("Data") and scanFolder(player.Data) then return true end
    
    -- Lưới quét Title
    local success, titles = pcall(function() return commF:InvokeServer("getTitles") end)
    if success and type(titles) == "table" then
        for _, title in pairs(titles) do
            if title == "Final Hero" or title == "Rainbow Saviour" then return true end
        end
    end
    return false
end

-- 4. BẮT ĐẦU VÒNG LẶP CHECK
task.spawn(function()
    while task.wait(Config.CheckInterval or 10) do
        local invMap = getInventoryMap()
        local ownsRainbowData = checkRainbowHaki()
        
        local foundMainTarget = false
        local finalStatusText = ""

        -- KIỂM TRA MỤC TIÊU CHÍNH (Đã fix gộp cả 3 lưới quét)
        for _, target in ipairs(TargetItems) do
            if Config[target.key] == true then
                local hasTarget = false
                
                -- Hòm đồ có là tính!
                if invMap[target.name] then hasTarget = true end
                
                -- Hoặc Data ẩn có là tính (Dành riêng cho Haki)
                if target.key == "Target_RainbowHaki" and ownsRainbowData then hasTarget = true end
                
                if hasTarget then
                    foundMainTarget = true
                    finalStatusText = target.alias
                    break
                end
            end
        end

        -- KHI TÌM THẤY MỤC TIÊU
        if foundMainTarget then
            for _, extra in ipairs(ExtraItems) do
                if Config[extra.key] == true then
                    local hasIt = false
                    if extra.key == "Target_RainbowHaki" then hasIt = ownsRainbowData or invMap["Rainbow Saviour"]
                    elseif extra.type == "Inv" and invMap[extra.name] then hasIt = true
                    elseif extra.type == "Melee" and hasMelee(extra.name) then hasIt = true end
                    
                    if hasIt and not string.find(finalStatusText, extra.alias) then 
                        finalStatusText = finalStatusText .. "_" .. extra.alias 
                    end
                end
            end

            local fileContent = (Config.Prefix or "Completed-") .. finalStatusText
            local fileName = player.Name .. ".txt"
            
            if writefile then
                writefile(fileName, fileContent)
            end
            break -- TÌM THẤY -> XUẤT FILE -> DỪNG SCRIPT -> YUMMY ĐỔI ACC!
        end
    end
end)
