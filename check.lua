-- ==========================================
-- ĐÂY LÀ PHẦN LÕI ĐỂ TRÊN GITHUB (check.lua)
-- ==========================================

local Config = _G.YummyConfig or {
    Target_RainbowHaki = true, Target_DaiCam = false, Target_DaiDen = false, Target_DaiTim = false,
    DaiCam = true, DaiDen = true, DaiTim = true,
    CDK = true, Godhuman = true, TTK = false, SoulGuitar = false,
    CheckInterval = 10, Prefix = "Completed-"
}

local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local commF = replicatedStorage:FindFirstChild("Remotes") and replicatedStorage.Remotes:FindFirstChild("CommF_")

-- Hàm kiểm tra Inventory thông thường cho CDK, Belts, Godhuman
local function getInventoryMap()
    if not commF then return {} end
    local success, inventory = pcall(function() return commF:InvokeServer("getInventory") end)
    local map = {}
    if success and type(inventory) == "table" then
        for _, item in pairs(inventory) do map[item.Name] = true end
    end
    return map
end

-- Hàm kiểm tra Melee (Godhuman)
local function hasMelee(meleeName)
    if player.Backpack:FindFirstChild(meleeName) or (player.Character and player.Character:FindFirstChild(meleeName)) then return true end
    if commF then
        local success, result = pcall(function() return commF:InvokeServer("Buy" .. meleeName, true) end)
        return (success and result and type(result) ~= "string")
    end
    return false
end

-- === ĐÂY LÀ HÀM QUAN TRỌNG NHẤT: CHECK WARDROBE RAINBOW HAKI ===
local function HasRainbowHaki()
    -- Cách 1: Quét dữ liệu menu Tủ đồ (đây là cách chắc chắn nhất)
    -- GUI "Items" trong ảnh bạn gửi, mục Wardrobe -> Items -> Frame chứa list
    local wardrobeFrame = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("Main") and player.PlayerGui.Main:FindFirstChild("Wardrobe") and player.PlayerGui.Main.Wardrobe:FindFirstChild("Items")
    
    if wardrobeFrame and wardrobeFrame:FindFirstChild("List") then
        local listFrame = wardrobeFrame.List:FindFirstChild("Frame")
        if listFrame then
            for _, item in ipairs(listFrame:GetChildren()) do
                if item:IsA("Frame") and item:FindFirstChild("TextLabel") then
                    local itemName = item.TextLabel.Text
                    -- Tìm kiếm tên chính xác "Rainbow Saviour"
                    if itemName == "Rainbow Saviour" then
                        return true
                    end
                end
            end
        end
    end

    -- Cách 2 (Dự phòng): Quét dữ liệu ẩn của nhân vật
    local dataFolder = player:FindFirstChild("Data")
    if dataFolder then
        -- Blox Fruits thường lưu cosmetic (title, haki color) dưới dạng StringValue trong 'Data'
        for _, val in ipairs(dataFolder:GetChildren()) do
            if val:IsA("StringValue") and (val.Name:lower():find("rainbow") or val.Value:lower():find("rainbow")) then
                -- Nếu tên dữ liệu hoặc giá trị có chứa 'rainbow', khả năng cao là nó
                return true
            end
        end
    end
    
    return false
end

-- Các mục kiểm tra thêm (Extra) để ghi kèm vào file
local ExtraItems = {
    { key = "DaiCam", name = "Dojo Belt (Orange)", type = "Inv", alias = "DaiCam" },
    { key = "DaiDen", name = "Dojo Belt (Black)", type = "Inv", alias = "DaiDen" },
    { key = "DaiTim", name = "Dojo Belt (Purple)", type = "Inv", alias = "DaiTim" },
    { key = "CDK", name = "Cursed Dual Katana", type = "Inv", alias = "CDK" },
    { key = "TTK", name = "True Triple Katana", type = "Inv", alias = "TTK" },
    { key = "SoulGuitar", name = "Soul Guitar", type = "Inv", alias = "SG" },
    { key = "Godhuman", name = "Godhuman", type = "Melee", alias = "God" }
}

task.spawn(function()
    print("Đang chạy lõi từ GitHub... Đang check Wardrobe để tìm Haki Cầu Vồng!")
    while task.wait(Config.CheckInterval or 10) do
        local invMap = getInventoryMap()
        local ownsRainbowHaki = HasRainbowHaki() -- Gọi hàm check Wardrobe đặc biệt
        local finalStatusText = ""

        -- Kiểm tra xem mục tiêu chính là Haki Rainbow đã đạt chưa
        if Config.Target_RainbowHaki == true and ownsRainbowHaki then
            -- Nếu đã có Haki Rainbow, ta set target name cho file và quét tiếp các Item kèm theo
            finalStatusText = "Rainbow"
            
            for _, extra in ipairs(ExtraItems) do
                if Config[extra.key] == true then
                    local hasIt = false
                    if extra.type == "Inv" and invMap[extra.name] then hasIt = true
                    elseif extra.type == "Melee" and hasMelee(extra.name) then hasIt = true end
                    if hasIt then finalStatusText = finalStatusText .. "_" .. extra.alias end
                end
            end

            -- Xuất file cho Yummytool
            local fileContent = (Config.Prefix or "Completed-") .. finalStatusText
            local fileName = player.Name .. ".txt"
            
            if writefile then
                writefile(fileName, fileContent)
                print("Đã tìm thấy Haki Rainbow trong Wardrobe! Đã tạo file: " .. fileName .. " | Nội dung: " .. fileContent)
            else
                warn("Lỗi: Executor không hỗ trợ writefile!")
            end
            break -- Kết thúc, tool đổi acc
        end
    end
end)
