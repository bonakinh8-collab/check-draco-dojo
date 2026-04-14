local Config = _G.YummyConfig or {}
local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

task.spawn(function()
    while not player do task.wait(1); player = game.Players.LocalPlayer end
    local commF = rs:WaitForChild("Remotes", 9e9):WaitForChild("CommF_", 9e9)

    -- Mấy cái râu ria cũ giữ lại nhỡ mày cần xài
    local beltMap = {
        Target_BlackBelt = "Dojo Belt (Black)"
    }

    while task.wait(10) do 
        local foundTargets = {} 
        
        -- =======================================================
        -- KHAI BÁO BIẾN Y CHANG SOURCE GỐC (ẢNH SỐ 6, 7)
        -- =======================================================
        local Draco = false
        local Storm = false
        local Heart = false
        local StormMas = 0
        local HeartMas = 0

        -- 1. CHECK RACE (Y CHANG ẢNH SỐ 3)
        pcall(function()
            if player:FindFirstChild("Data") and player.Data:FindFirstChild("Race") then
                if player.Data.Race.Value == "Draco" or string.find(string.lower(tostring(player.Data.Race.Value)), "draco") then
                    Draco = true
                end
            end
        end)

        -- 2. CHECK INVENTORY & MASTERY (Y CHANG ẢNH SỐ 6)
        pcall(function()
            local inv = commF:InvokeServer("getInventory")
            if type(inv) == "table" then
                for i, v in pairs(inv) do
                    if type(v) == "table" and v.Name then
                        
                        -- Lấy dữ liệu 2 thanh kiếm/súng
                        if v.Name == "Dragon Storm" then
                            Storm = true
                            StormMas = tonumber(v.Mastery) or 0
                        end
                        if v.Name == "Dragon Heart" then
                            Heart = true
                            HeartMas = tonumber(v.Mastery) or 0
                        end

                        -- Quét Đai Đen (Râu ria)
                        for cfgKey, bName in pairs(beltMap) do
                            if Config[cfgKey] and v.Name == bName then table.insert(foundTargets, bName) end
                        end
                    end
                end
            end
        end)

        -- =======================================================
        -- 3. LOGIC ĐỔI ACC CHÍNH XÁC TỪ SOURCE GAME (ẢNH SỐ 7)
        -- =======================================================
        if Config.Target_Combo3Mon_Draco_Weapons then
            local reqStorm = tonumber(Config.Target_DragonStorm_Mastery) or 500
            local reqHeart = tonumber(Config.Target_DragonHeart_Mastery) or 500
            
            -- In ra F9 để mày theo dõi tiến độ luôn
            print("[DEBUG ĐỘC QUYỀN] Draco: " .. tostring(Draco) .. " | Storm: " .. tostring(Storm) .. " (" .. StormMas .. "/" .. reqStorm .. ") | Heart: " .. tostring(Heart) .. " (" .. HeartMas .. "/" .. reqHeart .. ")")
            
            -- LOGIC CHỐT HẠ Y HỆT TRONG ẢNH SỐ 7
            if Draco == true and Storm == true and Heart == true and StormMas >= reqStorm and HeartMas >= reqHeart then
                table.insert(foundTargets, "ComboDracoWeapons_MaxPing")
            end
        end

        -- =======================================================
        -- 4. XUẤT FILE ĐỔI ACC
        -- =======================================================
        if #foundTargets > 0 then
            local status = table.concat(foundTargets, "_")
            print("[CHECKER] ĐÃ ĐẠT ĐIỀU KIỆN! TIẾN HÀNH ĐỔI ACC: " .. status)
            
            pcall(function()
                if writefile then
                    writefile(player.Name .. ".txt", (Config.Prefix or "Completed-") .. status)
                end
            end)
            break
        end
    end
end)
