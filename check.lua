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
        
        -- CÁC BIẾN LƯU TRỮ NGUYÊN LIỆU (MATERIALS)
        local dinoCount  = 0
        local scaleCount = 0
        local emberCount = 0
        local stormCount = 0  -- MỚI THÊM: Dragon Storm
        local heartCount = 0  -- MỚI THÊM: Dragon Heart

        pcall(function()
            local inv = commF:InvokeServer("getInventory")
            if type(inv) == "table" then
                for _, item in pairs(inv) do
                    if type(item) == "table" and item.Name then
                        local iName = item.Name
                        local currentAmount = tonumber(item.Count) or tonumber(item.Quantity) or 1
                        
                        -- KIỂM TRA KHU VỰC NGUYÊN LIỆU
                        if iName == "Dinosaur Bones" or iName == "Dinosaur Bone" then dinoCount = currentAmount end
                        if iName == "Dragon Scale" then scaleCount = currentAmount end
                        if iName == "Blaze Ember"  then emberCount = currentAmount end
                        if iName == "Dragon Storm" then stormCount = currentAmount end
                        if iName == "Dragon Heart" then heartCount = currentAmount end

                        -- 1. Check Đai (Belts)
                        for cfgKey, bName in pairs(beltMap) do
                            if Config[cfgKey] and iName == bName then table.insert(foundBelts, bName) end
                        end
                        
                        -- 2. Check Mastery
                        if Config.Target_Mastery and type(Config.Target_Mastery) == "table" then
                            local targetMas = Config.Target_Mastery[iName]
                            if targetMas and tonumber(item.Mastery) and tonumber(item.Mastery) >= targetMas then
                                table.insert(foundMastery, iName .. "_Mas" .. tostring(math.floor(item.Mastery)))
                            end
                        end

                        -- VIP Items
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

        -- 3. XỬ LÝ LOGIC ĐỔI ACC
        
        -- Check Xương
        if Config.Target_DinosaurBones then
            local target = tonumber(Config.Target_DinosaurBones)
            if target and dinoCount >= target then table.insert(foundTargets, "DinosaurBones_" .. dinoCount)
            elseif Config.Target_DinosaurBones == true and dinoCount > 0 then table.insert(foundTargets, "DinosaurBones_" .. dinoCount) end
        end

        -- Check Vảy Rồng
        if Config.Target_DragonScale then
            local target = tonumber(Config.Target_DragonScale)
            if target and scaleCount >= target then table.insert(foundTargets, "DragonScale_" .. scaleCount)
            elseif Config.Target_DragonScale == true and scaleCount > 0 then table.insert(foundTargets, "DragonScale_" .. scaleCount) end
        end

        -- Check Lửa
        if Config.Target_BlazeEmber then
            local target = tonumber(Config.Target_BlazeEmber)
            if target and emberCount >= target then table.insert(foundTargets, "BlazeEmber_" .. emberCount)
            elseif Config.Target_BlazeEmber == true and emberCount > 0 then table.insert(foundTargets, "BlazeEmber_" .. emberCount) end
        end

        -- Check Dragon Storm (MỚI)
        if Config.Target_DragonStorm then
            local target = tonumber(Config.Target_DragonStorm)
            if target and stormCount >= target then table.insert(foundTargets, "DragonStorm_" .. stormCount)
            elseif Config.Target_DragonStorm == true and stormCount > 0 then table.insert(foundTargets, "DragonStorm_" .. stormCount) end
        end

        -- Check Dragon Heart (MỚI)
        if Config.Target_DragonHeart then
            local target = tonumber(Config.Target_DragonHeart)
            if target and heartCount >= target then table.insert(foundTargets, "DragonHeart_" .. heartCount)
            elseif Config.Target_DragonHeart == true and heartCount > 0 then table.insert(foundTargets, "DragonHeart_" .. heartCount) end
        end

        -- Check COMBO GỘP 
        if Config.Target_ComboTradeDragon then
            if scaleCount >= 5 and emberCount >= 45 then
                table.insert(foundTargets, "ReadyTradeDragon")
            end
        end

        -- 4. Check Haki Rainbow
        if Config.Target_RainbowHaki then
            pcall(function()
                local titles = commF:InvokeServer("getTitles")
                if type(titles) == "table" then
                    for _, v in pairs(titles) do
                        if type(v) == "table" then
                            local tName = tostring(v.Name or "")
                            local tInternal = tostring(v.InternalName or "")
                            if string.find(tName, "Final Hero") or string.find(tInternal, "Final Hero") or string.find(tName, "Rainbow") or string.find(tInternal, "Rainbow") then
                                if not string.find(string.upper(tName), "LOCKED") and not string.find(string.upper(tInternal), "LOCKED") then
                                    hasRB = true
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end

        -- GỘP KẾT QUẢ XUẤT FILE
        if hasRB then table.insert(foundTargets, "Rainbow") end
        for _, b in ipairs(foundBelts) do table.insert(foundTargets, b) end
        for _, m in ipairs(foundMastery) do table.insert(foundTargets, m) end 

        if #foundTargets > 0 then
            local status = table.concat(foundTargets, "_")
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
