local Config = _G.YummyConfig or {
    Target_RainbowHaki = false, Target_DaiCam = false, Target_DaiDen = false, Target_DaiTim = false,
    DaiCam = true, DaiDen = true, DaiTim = true, CDK = true, Godhuman = true, TTK = false, SoulGuitar = false,
    CheckInterval = 10, Prefix = "Completed-"
}

local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local commF = replicatedStorage:FindFirstChild("Remotes") and replicatedStorage.Remotes:FindFirstChild("CommF_")

-- Danh sách Target chính (để kích hoạt việc đổi acc)
local TargetItems = {
    { key = "Target_RainbowHaki", name = "Rainbow Saviour", alias = "Rainbow" },
    { key = "Target_DaiCam", name = "Dojo Belt (Orange)", alias = "DaiCam" },
    { key = "Target_DaiDen", name = "Dojo Belt (Black)", alias = "DaiDen" },
    { key = "Target_DaiTim", name = "Dojo Belt (Purple)", alias = "DaiTim" }
}

-- Danh sách kiểm tra kèm theo (để ghi thêm vào file txt)
local ExtraItems = {
    { key = "DaiCam", name = "Dojo Belt (Orange)", type = "Inv", alias = "DaiCam" },
    { key = "DaiDen", name = "Dojo Belt (Black)", type = "Inv", alias = "DaiDen" },
    { key = "DaiTim", name = "Dojo Belt (Purple)", type = "Inv", alias = "DaiTim" },
    { key = "CDK", name = "Cursed Dual Katana", type = "Inv", alias = "CDK" },
    { key = "TTK", name = "True Triple Katana", type = "Inv", alias = "TTK" },
    { key = "SoulGuitar", name = "Soul Guitar", type = "Inv", alias = "SG" },
    { key = "Godhuman", name = "Godhuman", type = "Melee", alias = "God" }
}

-- 1. Hàm quét hòm đồ (Kiếm, Súng, Phụ kiện)
local function getInventoryMap()
    if not commF then return {} end
    local success, inventory = pcall(function() return commF:InvokeServer("getInventory") end)
    local map = {}
    if success and type(inventory) == "table" then
        for _, item in pairs(inventory) do map[item.Name] = true end
    end
    return map
end

-- 2. Hàm quét Melee
local function hasMelee(meleeName)
    if player.Backpack:FindFirstChild(meleeName) or (player.Character and player.Character:FindFirstChild(meleeName)) then return true end
    if commF then
        local success, result = pcall(function() return commF:InvokeServer("Buy" .. meleeName, true) end)
        return (success and result and type(result) ~= "string")
    end
    return false
end

-- 3. Hàm quét Haki Rainbow (Từ Data gốc của game)
local function checkRainbowHaki()
    local playerData = player:FindFirstChild("Data")
    if playerData then
        local colorsFolder = playerData:FindFirstChild("Colors")
        if colorsFolder then
            for _, color in pairs(colorsFolder:GetChildren()) do
                if color.Name == "Rainbow Saviour" or color.Value == "Rainbow Saviour" then return true end
            end
        end
        for _, val in pairs(playerData:GetChildren()) do
            if val:IsA("StringValue") and (val.Value:match("Rainbow") or val.Name:match("Rainbow")) then return true end
        end
    end
    return false
end

-- VÒNG LẶP XỬ LÝ CHÍNH
task.spawn(function()
    while task.wait(Config.CheckInterval or 10) do
        local invMap = getInventoryMap()
        local ownsRainbow = checkRainbowHaki()
        
        local foundMainTarget = false
        local finalStatusText = ""

        -- Kiểm tra xem có đạt Mục tiêu (Target) nào đang bật True không
        for _, target in ipairs(TargetItems) do
            if Config[target.key] == true then
                if (target.key == "Target_RainbowHaki" and ownsRainbow) or (target.key ~= "Target_RainbowHaki" and invMap[target.name]) then
                    foundMainTarget = true
                    finalStatusText = target.alias
                    break
                end
            end
        end

        -- Nếu đã đạt Mục tiêu chính, quét tiếp hàng đính kèm
        if foundMainTarget then
            for _, extra in ipairs(ExtraItems) do
                if Config[extra.key] == true then
                    local hasIt = false
                    if extra.key == "Target_RainbowHaki" then hasIt = ownsRainbow
                    elseif extra.type == "Inv" and invMap[extra.name] then hasIt = true
                    elseif extra.type == "Melee" and hasMelee(extra.name) then hasIt = true end
                    
                    -- Đảm bảo không bị lặp tên (ví dụ Target là DaiCam rồi thì không ghi thêm _DaiCam nữa)
                    if hasIt and not string.find(finalStatusText, extra.alias) then 
                        finalStatusText = finalStatusText .. "_" .. extra.alias 
                    end
                end
            end

            -- Xuất file và kích hoạt Yummytool change acc
            local fileContent = (Config.Prefix or "Completed-") .. finalStatusText
            local fileName = player.Name .. ".txt"
            
            if writefile then
                writefile(fileName, fileContent)
            end
            break
        end
    end
end)
