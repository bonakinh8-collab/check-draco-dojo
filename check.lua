local Config = _G.YummyConfig or {}
local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

task.spawn(function()
    while not player do task.wait(1); player = game.Players.LocalPlayer end
    local commF = rs:WaitForChild("Remotes", 9e9):WaitForChild("CommF_", 9e9)

    local beltMap = {
        Target_OrangeBelt = "Dojo Belt (Orange)", Target_PurpleBelt = "Dojo Belt (Purple)",
        Target_WhiteBelt  = "Dojo Belt (White)",  Target_BlueBelt   = "Dojo Belt (Blue)",
        Target_GreenBelt  = "Dojo Belt (Green)",  Target_YellowBelt = "Dojo Belt (Yellow)",
        Target_RedBelt    = "Dojo Belt (Red)",    Target_BlackBelt  = "Dojo Belt (Black)"
    }

    while task.wait(10) do 
        local foundTargets = {} 
        local foundBelts = {}
        local foundMastery = {} 
        local vipItems = {}
        
        -- CÁC BIẾN LƯU TRỮ TỔNG HỢP
        local Draco = false
        local Storm = false
        local Heart = false
        local StormMas = 0
        local HeartMas = 0
        local hasRB = false
        local materials = {Dino = 0, Scale = 0, Ember = 0}

        -- 1. KIỂM TRA TỘC 
        pcall(function()
            if player:FindFirstChild("Data") and player.Data:FindFirstChild("Race") then
                local raceVal = tostring(player.Data.Race.Value)
                if raceVal == "Draco" or string.find(string.lower(raceVal), "draco") or string.find(string.lower(raceVal), "dragon") then
                    Draco = true
                end
            end
        end)

        -- 2. KIỂM TRA TÚI ĐỒ VÀ THÔNG THẠO
        pcall(function()
            local inv = commF:InvokeServer("getInventory")
            if type(inv) == "table" then
                for i, v in pairs(inv) do
                    if type(v) == "table" and v.Name then
                        local iName = v.Name
                        local currentAmount = tonumber(v.Count) or tonumber(v.Quantity) or 1
                        local currentMas = tonumber(v.Mastery) or 0
                        
                        -- Quét Vũ khí Combo
                        if iName == "Dragon Storm" then Storm = true; StormMas = currentMas end
                        if iName == "Dragon Heart" then Heart = true; HeartMas = currentMas end

                        -- Quét Nguyên liệu lẻ
                        if iName == "Dinosaur Bones" or iName == "Dinosaur Bone" then materials.Dino = currentAmount end
                        if iName == "Dragon Scale" then materials.Scale = currentAmount end
                        if iName == "Blaze Ember"  then materials.Ember = currentAmount end

                        -- Quét Thông thạo lẻ (Từ bảng Target_Mastery)
                        if Config.Target_Mastery and type(Config.Target_Mastery) == "table" then
                            local targetMas = Config.Target_Mastery[iName]
                            if targetMas and currentMas >= targetMas then
                                table.insert(foundMastery, iName .. "_Mas" .. tostring(math.floor(currentMas)))
                            end
                        end

                        -- Quét Đai Dojo
                        for cfgKey, bName in pairs(beltMap) do
                            if Config[cfgKey] and iName == bName then table.insert(foundBelts, bName) end
                        end

                        -- Ghi chú VIP Items
                        if iName == "Cursed Dual Katana" then table.insert(vipItems, "CDK") end
                        if iName == "Soul Guitar" then table.insert(vipItems, "SGT") end
                        if iName == "True Triple Katana" then table.insert(vipItems, "TTK") end
                        if iName == "Fox Lamp" then table.insert(vipItems, "Fox Lamp") end
                    end
                end
            end
        end)

        -- 3. KIỂM TRA HAKI RAINBOW
        if Config.Target_RainbowHaki then
            pcall(function()
                local titles = commF:InvokeServer("getTitles")
                if type(titles) == "table" then
                    for _, v in pairs(titles) do
                        if type(v) == "table" and (string.find(v.Name or "", "Final Hero") or string.find(v.Name or "", "Rainbow")) then
                            if not string.find(string.upper(v.Name), "LOCKED") then hasRB = true break end
                        end
                    end
                end
            end)
        end

        -- =======================================================
        -- 4. XỬ LÝ LOGIC ĐỔI ACC 
        -- =======================================================

        -- [COMBO TỐI THƯỢNG] Tộc Draco + Dragon Storm + Dragon Heart (Mặc định Mastery 1)
        if Config.Target_Combo3Mon_Draco_Weapons then
            -- NẾU KHÔNG ĐIỀN GÌ Ở CONFIG, NÓ SẼ TỰ ĐỘNG LẤY 1
            local reqStorm = tonumber(Config.Target_DragonStorm_Mastery) or 1
            local reqHeart = tonumber(Config.Target_DragonHeart_Mastery) or 1
            
            -- In Debug F9
            print("[DEBUG] Draco: " .. tostring(Draco) .. " | Storm: " .. tostring(Storm) .. " (" .. StormMas .. "/" .. reqStorm .. ") | Heart: " .. tostring(Heart) .. " (" .. HeartMas .. "/" .. reqHeart .. ")")
            
            if Draco == true and Storm == true and Heart == true and StormMas >= reqStorm and HeartMas >= reqHeart then
                table.insert(foundTargets, "ComboDracoWeapons_MaxPing")
            end
        end

        -- [COMBO TRADE] 5 Vảy + 45 Lửa
        if Config.Target_ComboTradeDragon then
            if materials.Scale >= 5 and materials.Ember >= 45 then table.insert(foundTargets, "ReadyTradeDragon") end
        end

        -- [NGUYÊN LIỆU ĐỘC LẬP]
        if Config.Target_DinosaurBones then
            local target = tonumber(Config.Target_DinosaurBones)
            if target and materials.Dino >= target then table.insert(foundTargets, "DinosaurBones_" .. materials.Dino)
            elseif Config.Target_DinosaurBones == true and materials.Dino > 0 then table.insert(foundTargets, "DinosaurBones_" .. materials.Dino) end
        end

        if Config.Target_DragonScale then
            local target = tonumber(Config.Target_DragonScale)
            if target and materials.Scale >= target then table.insert(foundTargets, "DragonScale_" .. materials.Scale)
            elseif Config.Target_DragonScale == true and materials.Scale > 0 then table.insert(foundTargets, "DragonScale_" .. materials.Scale) end
        end

        if Config.Target_BlazeEmber then
            local target = tonumber(Config.Target_BlazeEmber)
            if target and materials.Ember >= target then table.insert(foundTargets, "BlazeEmber_" .. materials.Ember)
            elseif Config.Target_BlazeEmber == true and materials.Ember > 0 then table.insert(foundTargets, "BlazeEmber_" .. materials.Ember) end
        end

        -- =======================================================
        -- 5. KẾT LUẬN & XUẤT FILE
        -- =======================================================
        local finalFound = {}
        if hasRB then table.insert(finalFound, "Rainbow") end
        for _, v in ipairs(foundTargets) do table.insert(finalFound, v) end
        for _, b in ipairs(foundBelts) do table.insert(finalFound, b) end
        for _, m in ipairs(foundMastery) do table.insert(finalFound, m) end 

        if #finalFound > 0 then
            local status = table.concat(finalFound, "_")
            local vipString = #vipItems > 0 and table.concat(vipItems, ", ") or "None"
            print("[CHECKER] ĐÃ ĐẠT ĐIỀU KIỆN! ĐANG XUẤT FILE: " .. status .. " | VIP: " .. vipString)
            
            pcall(function()
                if writefile then
                    writefile(player.Name .. ".txt", (Config.Prefix or "Completed-") .. status)
                end
            end)
            break
        end
    end
end)
