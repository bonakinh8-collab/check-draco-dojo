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
        local foundDinoString = nil 
        local foundBelts = {}
        local foundMastery = {} 
        local vipItems = {}
        
        -- BIẾN ĐẾM NGUYÊN LIỆU TRADE
        local scaleCount = 0
        local emberCount = 0

        pcall(function()
            local inv = commF:InvokeServer("getInventory")
            if type(inv) == "table" then
                for _, item in pairs(inv) do
                    if type(item) == "table" and item.Name then
                        local iName = item.Name
                        local currentAmount = tonumber(item.Count) or tonumber(item.Quantity) or 1
                        
                        -- 1. Check Đai (Belts)
                        for cfgKey, bName in pairs(beltMap) do
                            if Config[cfgKey] and iName == bName then
                                table.insert(foundBelts, bName)
                            end
                        end
                        
                        -- 2. Check Mastery (Kiếm & Súng)
                        if Config.Target_Mastery and type(Config.Target_Mastery) == "table" then
                            local targetMas = Config.Target_Mastery[iName]
                            if targetMas and tonumber(item.Mastery) and tonumber(item.Mastery) >= targetMas then
                                table.insert(foundMastery, iName .. "_Mas" .. tostring(math.floor(item.Mastery)))
                            end
                        end

                        -- 3. Check SỐ LƯỢNG VẬT PHẨM (Dinosaur Bones)
                        if Config.Target_DinosaurBones and (iName == "Dinosaur Bones" or iName == "Dinosaur Bone") then
                            local targetAmount = tonumber(Config.Target_DinosaurBones)
                            if targetAmount then
                                if currentAmount >= targetAmount then
                                    foundDinoString = "DinosaurBones_" .. currentAmount
                                end
                            elseif Config.Target_DinosaurBones == true then
                                foundDinoString = "DinosaurBones_" .. currentAmount
                            end
                        end
                        
                        -- 4. GOM SỐ LIỆU ĐỂ TRADE DRAGON
                        if iName == "Dragon Scale" then scaleCount = currentAmount end
                        if iName == "Blaze Ember" then emberCount = currentAmount end
                        
                        -- 5. Check Đồ VIP đi kèm (Chỉ để hiển thị LOGS)
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

        -- 6. Check Haki Rainbow
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

        -- TỔNG HỢP MỤC TIÊU ĐẠT ĐƯỢC
        local foundTargets = {}
        if hasRB then table.insert(foundTargets, "Rainbow") end
        if foundDinoString then table.insert(foundTargets, foundDinoString) end 
        
        -- [MỚI] KIỂM TRA ĐỦ ĐIỀU KIỆN ĐỔI ACC NẾU ĐÃ GOM ĐỦ NGUYÊN LIỆU TRADE
        if Config.Target_DragonTradeReady then
            if scaleCount >= 5 and emberCount >= 45 then
                table.insert(foundTargets, "ReadyTradeDragon")
            end
        end

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
