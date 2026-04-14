local Config = _G.YummyConfig or {}
local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

task.spawn(function()
    while not player do task.wait(1); player = game.Players.LocalPlayer end
    local commF = rs:WaitForChild("Remotes", 9e9):WaitForChild("CommF_", 9e9)

    local beltMap = {
        Target_OrangeBelt = "Dojo Belt (Orange)",
        Target_PurpleBelt = "Dojo Belt (Purple)",
        Target_WhiteBelt  = "Dojo Belt (White)",
        Target_BlueBelt   = "Dojo Belt (Blue)",
        Target_GreenBelt  = "Dojo Belt (Green)",
        Target_YellowBelt = "Dojo Belt (Yellow)",
        Target_RedBelt    = "Dojo Belt (Red)",
        Target_BlackBelt  = "Dojo Belt (Black)"
    }

    while task.wait(10) do 
        local hasRB = false
        local foundTargets = {} 
        local foundBelts = {}
        local foundMastery = {} 
        local vipItems = {}
        
        -- BIẾN LƯU SỐ LƯỢNG NGUYÊN LIỆU
        local materials = {Dino = 0, Scale = 0, Ember = 0}

        pcall(function()
            local inv = commF:InvokeServer("getInventory")
            if type(inv) == "table" then
                for _, item in pairs(inv) do
                    if type(item) == "table" and item.Name then
                        local iName = item.Name
                        local currentAmount = tonumber(item.Count) or tonumber(item.Quantity) or 1
                        local currentMas = tonumber(item.Mastery) or 0
                        
                        -- 1. LẤY SỐ LƯỢNG NGUYÊN LIỆU
                        if iName == "Dinosaur Bones" or iName == "Dinosaur Bone" then materials.Dino = currentAmount end
                        if iName == "Dragon Scale" then materials.Scale = currentAmount end
                        if iName == "Blaze Ember"  then materials.Ember = currentAmount end

                        -- 2. CHECK MASTERY (THÔNG THẠO VŨ KHÍ)
                        if Config.Target_Mastery and type(Config.Target_Mastery) == "table" then
                            local targetMas = Config.Target_Mastery[iName]
                            if targetMas and currentMas >= targetMas then
                                table.insert(foundMastery, iName .. "_Mas" .. tostring(math.floor(currentMas)))
                            end
                        end

                        -- 3. CHECK ĐAI DOJO
                        for cfgKey, bName in pairs(beltMap) do
                            if Config[cfgKey] and iName == bName then table.insert(foundBelts, bName) end
                        end

                        -- VIP LOGS (GHI CHÚ ĐỒ HIẾM)
                        if iName == "Cursed Dual Katana" then table.insert(vipItems, "CDK") end
                        if iName == "Soul Guitar" then table.insert(vipItems, "SGT") end
                        if iName == "True Triple Katana" then table.insert(vipItems, "TTK") end
                        if iName == "Fox Lamp" then table.insert(vipItems, "Fox Lamp") end
                        if iName == "Dark Dagger" then table.insert(vipItems, "Dark Dagger") end
                        if iName == "Hallow Scythe" then table.insert(vipItems, "Hallow Scythe") end
                    end
                end
            end
        end)

        -- 4. CHECK COMBO 3 MÓN NGUYÊN LIỆU (PHẢI ĐỦ CẢ 3 MỚI ĐỔI)
        if Config.Target_Combo3Materials then
            local targetDino = tonumber(Config.Target_DinosaurBones) or 0
            if materials.Dino >= targetDino and materials.Scale >= 5 and materials.Ember >= 45 then
                table.insert(foundTargets, "Combo3Ready")
            end
        end

        -- 5. CHECK TỘC DRACO
        if Config.Target_RaceDraco then
            pcall(function()
                if player:FindFirstChild("Data") and player.Data:FindFirstChild("Race") then
                    if string.find(string.lower(player.Data.Race.Value), "draco") then
                        table.insert(foundTargets, "RaceDraco")
                    end
                end
            end)
        end

        -- 6. CHECK HAKI RAINBOW
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

        -- TỔNG HỢP VÀ XUẤT FILE ĐỔI ACC
        local finalFound = {}
        if hasRB then table.insert(finalFound, "Rainbow") end
        for _, v in ipairs(foundTargets) do table.insert(finalFound, v) end
        for _, b in ipairs(foundBelts) do table.insert(finalFound, b) end
        for _, m in ipairs(foundMastery) do table.insert(finalFound, m) end 

        if #finalFound > 0 then
            local status = table.concat(finalFound, "_")
            local vipString = #vipItems > 0 and table.concat(vipItems, ", ") or "None"
            print("[CHECKER] FOUND: " .. status .. " | VIP: " .. vipString)
            
            pcall(function()
                if writefile then
                    writefile(player.Name .. ".txt", (Config.Prefix or "Completed-") .. status)
                end
            end)
            break
        end
    end
end)
