local Config = _G.YummyConfig or {}
local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

task.spawn(function()
    -- Vòng lặp an toàn: Chỉ chạy khi có LocalPlayer, không dùng Wait() gây kẹt
    while not player do
        task.wait(1)
        player = game.Players.LocalPlayer
    end
    
    while task.wait(Config.CheckInterval or 10) do
        local foundMainTarget = false
        local status = ""
        
        -- 1. KIỂM TRA HAKI RAINBOW (Quét toàn bộ Data ngầm cực mạnh, không gây treo)
        local hasRainbow = false
        local data = player:FindFirstChild("Data")
        if data then
            for _, v in pairs(data:GetDescendants()) do
                if v:IsA("StringValue") and (v.Value == "Rainbow Saviour" or v.Value == "Final Hero" or v.Name == "Rainbow Saviour") then
                    hasRainbow = true
                    break
                end
            end
        end

        -- 2. KIỂM TRA HÒM ĐỒ VÀ MUA BÁN (Bọc lỗi pcall an toàn tuyệt đối)
        local invMap = {}
        local remotes = rs:FindFirstChild("Remotes")
        local commF = remotes and remotes:FindFirstChild("CommF_")
        
        if commF then
            pcall(function()
                local inv = commF:InvokeServer("getInventory")
                if type(inv) == "table" then
                    for _, item in pairs(inv) do invMap[item.Name] = true end
                end
            end)
        end

        -- 3. XÁC ĐỊNH MỤC TIÊU CHÍNH
        if Config.Target_RainbowHaki and hasRainbow then
            foundMainTarget = true
            status = "Rainbow"
        elseif not Config.Target_RainbowHaki then
            if Config.Target_DaiCam and invMap["Dojo Belt (Orange)"] then foundMainTarget = true; status = "DaiCam"
            elseif Config.Target_DaiDen and invMap["Dojo Belt (Black)"] then foundMainTarget = true; status = "DaiDen"
            elseif Config.Target_DaiTim and invMap["Dojo Belt (Purple)"] then foundMainTarget = true; status = "DaiTim"
            end
        end

        -- 4. XUẤT FILE ĐỔI ACC NẾU ĐẠT
        if foundMainTarget then
            -- Quét hàng kèm theo
            if Config.DaiCam and invMap["Dojo Belt (Orange)"] and not status:match("DaiCam") then status = status .. "_DaiCam" end
            if Config.DaiDen and invMap["Dojo Belt (Black)"] and not status:match("DaiDen") then status = status .. "_DaiDen" end
            if Config.DaiTim and invMap["Dojo Belt (Purple)"] and not status:match("DaiTim") then status = status .. "_DaiTim" end
            if Config.CDK and invMap["Cursed Dual Katana"] then status = status .. "_CDK" end
            if Config.TTK and invMap["True Triple Katana"] then status = status .. "_TTK" end
            if Config.SoulGuitar and invMap["Soul Guitar"] then status = status .. "_SG" end
            
            -- Check Godhuman
            if Config.Godhuman then
                if (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Godhuman")) or 
                   (player.Character and player.Character:FindFirstChild("Godhuman")) then
                    status = status .. "_God"
                end
            end

            -- Báo cho YummyTool
            local fileName = player.Name .. ".txt"
            local fileContent = (Config.Prefix or "Completed-") .. status
            
            if writefile then
                writefile(fileName, fileContent)
            end
            break -- Đổi acc
        end
    end
end)
