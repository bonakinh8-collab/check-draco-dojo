local Config = _G.YummyConfig or {
    Target_RainbowHaki = true, Target_DaiCam = false, Target_DaiDen = false, Target_DaiTim = false,
    DaiCam = true, DaiDen = true, DaiTim = true, CDK = true, Godhuman = true, TTK = false, SoulGuitar = false,
    CheckInterval = 10, Prefix = "Completed-"
}

-- Đợi game load tránh lỗi
if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer

local replicatedStorage = game:GetService("ReplicatedStorage")
local commF = replicatedStorage:WaitForChild("Remotes", 9e9):WaitForChild("CommF_", 9e9)

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

-- HÀM 1: Quét Túi đồ vật lý (Cho Đai, Súng, Kiếm)
local function getInventoryMap()
    local map = {}
    pcall(function()
        local inv = commF:InvokeServer("getInventory")
        if type(inv) == "table" then
            for _, item in pairs(inv) do map[item.Name] = true end
        end
    end)
    return map
end

-- HÀM 2: Quét Title/Color đặc biệt (Dành riêng cho Haki Rainbow)
local function hasRainbowHaki()
    local found = false
    -- 1. Quét qua remote Titles của game
    pcall(function()
        local titles = commF:InvokeServer("getTitles")
        if type(titles) == "table" then
            for _, t in pairs(titles) do
                if t == "Final Hero" or t == "Rainbow Saviour" then found = true; break end
            end
        end
    end)
    
    -- 2. Quét qua Data ẩn của nhân vật (Dự phòng)
    if not found and player:FindFirstChild("Data") then
        local function search(folder)
            for _, v in pairs(folder:GetChildren()) do
                if v:IsA("StringValue") and (v.Value == "Rainbow Saviour" or v.Value == "Final Hero" or v.Name == "Rainbow Saviour") then
                    return true
                elseif v:IsA("Folder") then
                    if search(v) then return true end
                end
            end
            return false
        end
        found = search(player.Data)
    end
    
    return found
end

-- HÀM 3: Quét Melee (Cho Godhuman)
local function hasMelee(meleeName)
    if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild(meleeName) then return true end
    if player.Character and player.Character:FindFirstChild(meleeName) then return true end
    local success, result = pcall(function() return commF:InvokeServer("Buy" .. meleeName, true) end)
    return (success and result and type(result) ~= "string")
end

-- VÒNG LẶP CHÍNH
task.spawn(function()
    while task.wait(Config.CheckInterval or 10) do
        local invMap = getInventoryMap()
        local ownsRainbow = hasRainbowHaki()
        
        local foundMainTarget = false
        local finalStatusText = ""

        -- KIỂM TRA MỤC TIÊU
        for _, target in ipairs(TargetItems) do
            if Config[target.key] == true then
                if (target.key == "Target_RainbowHaki" and ownsRainbow) or (target.key ~= "Target_RainbowHaki" and invMap[target.name]) then
                    foundMainTarget = true
                    finalStatusText = target.alias
                    break
                end
            end
        end

        -- XUẤT FILE NẾU ĐẠT MỤC TIÊU
        if foundMainTarget then
            for _, extra in ipairs(ExtraItems) do
                if Config[extra.key] == true then
                    local hasIt = false
                    if extra.key == "Target_RainbowHaki" then hasIt = ownsRainbow
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
            break -- Kết thúc script, chờ Yummytool nhảy acc!
        end
    end
end)
