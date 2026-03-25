local Config = _G.YummyConfig or {}
local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

-- HÀM LẤY TÚI ĐỒ (Y HỆT BẢN ĐẦU TIÊN HOẠT ĐỘNG)
local function getInventoryMap()
    local map = {}
    local remotes = rs:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if commF then
        pcall(function()
            local inv = commF:InvokeServer("getInventory")
            if type(inv) == "table" then
                for _, item in pairs(inv) do map[item.Name] = true end
            end
        end)
    end
    return map
end

-- HÀM TÌM RAINBOW NHẸ NHÀNG (Tránh lỗi game)
local function hasRainbow()
    if player and player:FindFirstChild("Data") then
        for _, v in pairs(player.Data:GetDescendants()) do
            if v:IsA("StringValue") and (v.Value == "Rainbow Saviour" or v.Name == "Rainbow Saviour" or v.Value == "Final Hero") then
                return true
            end
        end
    end
    return false
end

-- VÒNG LẶP CHÍNH CỦA YUMMY (Y HỆT BẢN ĐẦU TIÊN)
task.spawn(function()
    while task.wait(Config.CheckInterval or 10) do
        if not player then player = game.Players.LocalPlayer end
        if not player then continue end

        local invMap = getInventoryMap()
        
        -- Kiểm tra xem có Haki Rainbow trong túi hoặc trong data không
        local ownsRainbow = invMap["Rainbow Saviour"] or hasRainbow()
        
        local targetFound = nil
        
        -- 1. CHỈ TÌM MỤC TIÊU BẠN ĐÃ BẬT TRUE
        if Config.Target_RainbowHaki and ownsRainbow then 
            targetFound = "Rainbow"
        elseif Config.Target_DaiCam and invMap["Dojo Belt (Orange)"] then 
            targetFound = "DaiCam"
        elseif Config.Target_DaiDen and invMap["Dojo Belt (Black)"] then 
            targetFound = "DaiDen"
        elseif Config.Target_DaiTim and invMap["Dojo Belt (Purple)"] then 
            targetFound = "DaiTim"
        end

        -- 2. NẾU ĐẠT MỤC TIÊU -> XUẤT FILE ĐỔI ACC
        if targetFound then
            local finalStatus = targetFound
            
            -- Ghi chú thêm các đồ đang có sẵn trong túi
            if Config.DaiCam and invMap["Dojo Belt (Orange)"] and targetFound ~= "DaiCam" then finalStatus = finalStatus .. "_DaiCam" end
            if Config.DaiDen and invMap["Dojo Belt (Black)"] and targetFound ~= "DaiDen" then finalStatus = finalStatus .. "_DaiDen" end
            if Config.DaiTim and invMap["Dojo Belt (Purple)"] and targetFound ~= "DaiTim" then finalStatus = finalStatus .. "_DaiTim" end
            if Config.CDK and invMap["Cursed Dual Katana"] then finalStatus = finalStatus .. "_CDK" end
            if Config.TTK and invMap["True Triple Katana"] then finalStatus = finalStatus .. "_TTK" end
            if Config.SoulGuitar and invMap["Soul Guitar"] then finalStatus = finalStatus .. "_SG" end
            if Config.Godhuman and (invMap["Godhuman"] or (player.Backpack and player.Backpack:FindFirstChild("Godhuman"))) then finalStatus = finalStatus .. "_God" end
            
            -- LỆNH ĐỔI ACC CỦA YUMMY
            local fileContent = (Config.Prefix or "Completed-") .. finalStatus
            local fileName = player.Name .. ".txt"
            if writefile then
                writefile(fileName, fileContent)
            end
            break -- Thoát vòng lặp
        end
    end
end)
