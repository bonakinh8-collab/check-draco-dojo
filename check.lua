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
        local foundItems = {} 
        local foundBelts = {}
        local foundMastery = {} 
        local vipItems = {}

        pcall(function()
            local inv = commF:InvokeServer("getInventory")
            if type(inv) == "table" then
                
                -- Bảng lưu trữ nhanh số lượng mọi vật phẩm đang có trong túi
                local inventoryCounts = {}
                
                for _, item in pairs(inv) do
                    if type(item) == "table" and item.Name then
                        local iName = item.Name
                        local currentAmount = tonumber(item.Count) or tonumber(item.Quantity) or 1
                        inventoryCounts[iName] = currentAmount
                        
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

                        -- Check Đồ VIP đi kèm (Chỉ để hiển thị LOGS)
                        if iName == "Cursed Dual Katana" then table.insert(vipItems, "CDK") end
                        if iName == "Soul Guitar" then table.insert(vipItems, "SGT") end
                        if iName == "True Triple Katana" then table.insert(vipItems, "TTK") end
                        if iName == "Fox Lamp" then table.insert(vipItems, "Fox Lamp") end
                        if iName == "Dark Dagger" then table.insert(vipItems, "Dark Dagger") end
                        if iName == "Hallow Scythe" then table.insert(vipItems, "Hallow Scythe") end
                    end
                end
                
                -- 3. CHECK VẬT PHẨM RIÊNG LẺ (Chỉ cần 1 món đủ là đổi acc)
                if Config.Target_Items and type(Config.Target_Items) == "table" then
                    for reqName, reqAmount in pairs(Config.Target_Items) do
                        local myAmount = inventoryCounts[reqName] or 0
                        -- Bắt dính cả 2 tên Xương
                        if reqName == "Dinosaur Bones" then
                            myAmount = (inventoryCounts["Dinosaur Bones"] or 0) + (inventoryCounts["Dinosaur Bone"] or 0)
                        end
                        
                        if myAmount >= reqAmount then
                            table.insert(foundItems, string.gsub(reqName, " ", "") .. "_" .. myAmount)
                        end
                    end
                end

                -- 4. CHECK COMBO NGUYÊN LIỆU (Phải ĐỦ TẤT CẢ các món kê khai mới đổi acc)
                if Config.Target_ComboMaterials and type(Config.Target_ComboMaterials) == "table" then
                    local comboMet = true
                    local comboHasReq = false
                    
                    for reqName, reqAmount in pairs(Config.Target_ComboMaterials) do
                        comboHasReq = true
                        local myAmount = inventoryCounts[reqName] or 0
                        -- Nếu có 1 món bất kỳ bị thiếu số lượng -> Hủy bỏ
                        if myAmount < reqAmount then
                            comboMet = false
                            break
                        end
                    end
                    
                    if comboHasReq and comboMet then
                        table.insert(foundItems, "ComboMaterialsDone")
                    end
                end
            end
        end)

        -- 5. Check Haki Rainbow
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
        for _, i in ipairs(foundItems) do table.insert(foundTargets, i) end 
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
