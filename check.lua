local Config = _G.YummyConfig or {
    Target_RainbowHaki = false, Target_DaiCam = false, Target_DaiDen = false, Target_DaiTim = false,
    DaiCam = true, DaiDen = true, DaiTim = true, CDK = true, Godhuman = true, TTK = false, SoulGuitar = false,
    CheckInterval = 10, Prefix = "Completed-"
}

-- 1. CHỜ GAME TẢI XONG ĐỂ KHÔNG BỊ LỖI "NIL"
local Players = game:GetService("Players")
repeat task.wait(1) until Players.LocalPlayer
local player = Players.LocalPlayer

local replicatedStorage = game:GetService("ReplicatedStorage")
local commF = nil
repeat 
    task.wait(1)
    if replicatedStorage:FindFirstChild("Remotes") then
        commF = replicatedStorage.Remotes:FindFirstChild("CommF_")
    end
until commF

-- 2. DANH SÁCH ITEM CẦN QUÉT
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

-- 3. CÁC HÀM QUÉT DỮ LIỆU ĐƯỢC BẢO VỆ CHỐNG LỖI
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
    if player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild(meleeName) then return true end
    if player.Character and player.Character:FindFirstChild(meleeName) then return true end
    if commF then
        local success, result = pcall(function() return commF:InvokeServer("Buy" .. meleeName, true) end)
        return (success and result and type(result) ~= "string")
    end
    return false
end

local function checkRainbowHaki()
    local hasRainbow = false
    
    -- Check qua Title (Bảo mật qua pcall)
    if commF then
        pcall(function()
            local titles = commF:InvokeServer("getTitles")
            if type(titles) == "table" then
                for _, title in pairs(titles) do
                    if title == "Final Hero" then hasRainbow = true; break end
                end
            end
        end)
    end
    
    -- Check qua Data (Có bảo vệ chống nil)
    if not hasRainbow then
        local data = player:FindFirstChild("Data")
        if data then
            for _, child in pairs(data:GetChildren()) do
                if (child:IsA("StringValue") and (child.Value == "Rainbow Saviour" or child.Value == "Final Hero")) 
                or child.Name == "Rainbow Saviour" then
                    hasRainbow = true; break
                end
            end
        end
    end
    
    return hasRainbow
end

-- 4. VÒNG LẶP XỬ LÝ CHÍNH
task.spawn(function()
    while task.wait(Config.CheckInterval or 10) do
        local invMap = getInventoryMap()
        local ownsRainbow = checkRainbowHaki()
        
        local foundMainTarget = false
        local finalStatusText = ""

        for _, target in ipairs(TargetItems) do
            if Config[target.key] == true then
                if (target.key == "Target_RainbowHaki" and ownsRainbow) or (target.key ~= "Target_RainbowHaki" and invMap[target.name]) then
                    foundMainTarget = true
                    finalStatusText = target.alias
                    break
                end
            end
        end

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
                print("THANH CONG! Đã báo cho Yummytool file:", fileContent)
            end
            break -- Đã tìm thấy, dừng script để change acc!
        end
    end
end)
