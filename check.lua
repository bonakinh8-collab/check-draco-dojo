local Config = _G.YummyConfig or {}

local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local commF = replicatedStorage:FindFirstChild("Remotes") and replicatedStorage.Remotes:FindFirstChild("CommF_")

-- Đưa Rainbow Saviour vào chung danh sách Target chuẩn
local TargetItems = {
    { key = "Target_RainbowHaki", name = "Rainbow Saviour", alias = "Rainbow" },
    { key = "Target_DaiCam", name = "Dojo Belt (Orange)", alias = "DaiCam" },
    { key = "Target_DaiDen", name = "Dojo Belt (Black)", alias = "DaiDen" },
    { key = "Target_DaiTim", name = "Dojo Belt (Purple)", alias = "DaiTim" },
    { key = "Target_DaiTrang", name = "Dojo Belt (White)", alias = "DaiTrang" },
    { key = "Target_DaiVang", name = "Dojo Belt (Yellow)", alias = "DaiVang" }
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

-- Quét toàn bộ dữ liệu ẩn của hòm đồ (Không cần mở GUI)
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
    print("Đang chạy lõi từ GitHub... Đang tìm kiếm các Mục tiêu đã được bật True!")
    while task.wait(Config.CheckInterval or 10) do
        local invMap = getInventoryMap()
        local foundMainTarget = false
        local finalStatusText = ""

        -- Kiểm tra xem có trúng Target nào đang bật true không
        for _, target in ipairs(TargetItems) do
            if Config[target.key] == true and invMap[target.name] then
                foundMainTarget = true
                finalStatusText = target.alias
                break 
            end
        end

        -- Nếu đã đạt Mục tiêu chính, tiến hành kiểm tra hàng đính kèm và xuất file
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
                print("Đã tìm thấy Target! Tạo file thành công: " .. fileName .. " | Nội dung: " .. fileContent)
            else
                warn("Lỗi: Executor không hỗ trợ writefile!")
            end
            break -- Xong nhiệm vụ, dừng vòng lặp để tool change acc
        end
    end
end)
