local Config = _G.YummyConfig or {
    Target_RainbowHaki = true, Target_DaiCam = false, Target_DaiDen = false, Target_DaiTim = false,
    DaiCam = true, DaiDen = true, DaiTim = true, CDK = true, Godhuman = true, TTK = false, SoulGuitar = false,
    CheckInterval = 10, Prefix = "Completed-"
}

local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local commF = replicatedStorage:FindFirstChild("Remotes") and replicatedStorage.Remotes:FindFirstChild("CommF_")

-- Hàm kiểm tra Inventory chung (Đai, Kiếm, Súng)
local function getInventoryMap()
    if not commF then return {} end
    local success, inventory = pcall(function() return commF:InvokeServer("getInventory") end)
    local map = {}
    if success and type(inventory) == "table" then
        for _, item in pairs(inventory) do map[item.Name] = true end
    end
    return map
end

-- Hàm check Melee (Godhuman)
local function hasMelee(meleeName)
    if player.Backpack:FindFirstChild(meleeName) or (player.Character and player.Character:FindFirstChild(meleeName)) then return true end
    if commF then
        local success, result = pcall(function() return commF:InvokeServer("Buy" .. meleeName, true) end)
        return (success and result and type(result) ~= "string")
    end
    return false
end

-- HÀM SỬA LỖI: Check riêng biệt và chính xác cho Haki Rainbow
local function checkRainbowHaki()
    -- Cách 1: Quét dữ liệu nhân vật
    local data = player:FindFirstChild("Data")
    if data then
        for _, v in pairs(data:GetChildren()) do
            if v:IsA("StringValue") and (v.Value:match("Rainbow") or v.Name:match("Rainbow")) then
                return true
            end
        end
    end
    
    -- Cách 2: Quét GUI Tủ đồ (Trường hợp game lưu ở UI Wardrobe)
    local mainGui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("Main")
    if mainGui and mainGui:FindFirstChild("Wardrobe") and mainGui.Wardrobe:FindFirstChild("Items") then
        local list = mainGui.Wardrobe.Items:FindFirstChild("List") and mainGui.Wardrobe.Items.List:FindFirstChild("Frame")
        if list then
            for _, item in pairs(list:GetChildren()) do
                if item:IsA("Frame") and item:FindFirstChild("TextLabel") and item.TextLabel.Text == "Rainbow Saviour" then
                    return true
                end
            end
        end
    end
    return false
end

task.spawn(function()
    while task.wait(Config.CheckInterval or 10) do
        local invMap = getInventoryMap()
        local foundMainTarget = false
        local finalStatusText = ""

        -- 1. Ưu tiên kiểm tra Target Haki Rainbow (Sử dụng cả hàm riêng + hòm đồ)
        if Config.Target_RainbowHaki and (checkRainbowHaki() or invMap["Rainbow Saviour"]) then
            foundMainTarget = true
            finalStatusText = "Rainbow"
        end

        -- 2. Nếu không có Rainbow (hoặc đang tắt), kiểm tra tiếp các Đai
        if not foundMainTarget then
            if Config.Target_DaiCam and invMap["Dojo Belt (Orange)"] then foundMainTarget = true; finalStatusText = "DaiCam"
            elseif Config.Target_DaiDen and invMap["Dojo Belt (Black)"] then foundMainTarget = true; finalStatusText = "DaiDen"
            elseif Config.Target_DaiTim and invMap["Dojo Belt (Purple)"] then foundMainTarget = true; finalStatusText = "DaiTim"
            end
        end

        -- 3. XỬ LÝ KHI ĐÃ ĐẠT MỤC TIÊU
        if foundMainTarget then
            -- Ghi chú các hàng kèm theo
            if Config.DaiCam and invMap["Dojo Belt (Orange)"] and finalStatusText ~= "DaiCam" then finalStatusText = finalStatusText .. "_DaiCam" end
            if Config.DaiDen and invMap["Dojo Belt (Black)"] and finalStatusText ~= "DaiDen" then finalStatusText = finalStatusText .. "_DaiDen" end
            if Config.DaiTim and invMap["Dojo Belt (Purple)"] and finalStatusText ~= "DaiTim" then finalStatusText = finalStatusText .. "_DaiTim" end
            if Config.CDK and invMap["Cursed Dual Katana"] then finalStatusText = finalStatusText .. "_CDK" end
            if Config.TTK and invMap["True Triple Katana"] then finalStatusText = finalStatusText .. "_TTK" end
            if Config.SoulGuitar and invMap["Soul Guitar"] then finalStatusText = finalStatusText .. "_SG" end
            if Config.Godhuman and hasMelee("Godhuman") then finalStatusText = finalStatusText .. "_God" end

            local fileContent = (Config.Prefix or "Completed-") .. finalStatusText
            local fileName = player.Name .. ".txt"
            
            if writefile then
                writefile(fileName, fileContent)
            end
            break -- Xuất file xong -> Dừng script để tool change acc!
        end
    end
end)
