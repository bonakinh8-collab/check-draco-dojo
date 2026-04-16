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

    -- HÀM LẤY ITEM & MASTERY XỊN (ÉP CHẾT LỖI DẤU CÁCH)
    local function GetItemData(targetName)
        local found = false
        local mastery = 0
        local cleanTarget = string.lower(string.gsub(targetName, "%s+", ""))
        
        pcall(function()
            local inv = commF:InvokeServer("getInventory")
            if type(inv) == "table" then
                for _, v in pairs(inv) do
                    if type(v) == "table" and v.Name then
                        local cleanItem = string.lower(string.gsub(v.Name, "%s+", ""))
                        if cleanItem == cleanTarget then
                            found = true
                            mastery = tonumber(v.Mastery) or 0
                            break
                        end
                    end
                end
            end
            if not found then
                local tool = player.Backpack:FindFirstChild(targetName) or (player.Character and player.Character:FindFirstChild(targetName))
                if tool then found = true end
            end
        end)
        return found, mastery
    end

    while task.wait(10) do
        local foundTargets = {} 
        local foundBelts = {}
        local materials = {Dino = 0, Scale = 0, Ember = 0}

        -- Quét Tộc Draco (Dành cho Mục 3)
        local hasDraco = false
        pcall(function()
            if player:FindFirstChild("Data") and player.Data:FindFirstChild("Race") then
                local raceVal = tostring(player.Data.Race.Value)
                if string.find(string.lower(raceVal), "draco") then hasDraco = true end
            end
        end)

        -- Quét Súng & Kiếm Draco (Dành cho Mục 3)
        local hasStorm = GetItemData("Dragonstorm")
        local hasHeart = GetItemData("Dragonheart")

        -- Quét Nguyên liệu & Đai
        pcall(function()
            local inv = commF:InvokeServer("getInventory")
            if type(inv) == "table" then
                for _, v in pairs(inv) do
                    if type(v) == "table" and v.Name then
                        local n = v.Name
                        local cleanName = string.lower(string.gsub(n, "%s+", ""))
                        local currentAmount = tonumber(v.Count) or tonumber(v.Quantity) or 1
                        
                        if string.find(cleanName, "dinosaurbone") then materials.Dino = currentAmount end
                        if string.find(cleanName, "dragonscale") then materials.Scale = currentAmount end
                        if string.find(cleanName, "blazeember") then materials.Ember = currentAmount end

                        for cfgKey, bName in pairs(beltMap) do
                            if Config[cfgKey] and n == bName then table.insert(foundBelts, bName) end
                        end
                    end
                end
            end
        end)

        -- Quét Haki
        local hasRB = false
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
        -- XỬ LÝ LOGIC ĐỔI ACC
        -- =======================================================
        local isReadyToJump = false
        local jumpReason = ""

        -- [MỤC 3] Combo Draco (Có hàng là đổi luôn)
        if Config.Target_ComboDraco then
            if hasDraco and hasStorm and hasHeart then
                isReadyToJump = true
                jumpReason = "ComboDraco_Instant"
            end
            
        -- [MỤC 4] Mastery Custom ĐA NĂNG (Kiểm tra bất kỳ vũ khí nào mày ghi trong Config)
        elseif Config.Target_Mastery and type(Config.Target_Mastery) == "table" then
            local allMasteryDone = true
            local hasAnyTarget = false
            local reasons = {}

            -- Duyệt qua từng món đồ mày điền trong bảng Config
            for wName, reqMas in pairs(Config.Target_Mastery) do
                hasAnyTarget = true
                local hasW, wMas = GetItemData(wName)
                
                print("[DEBUG MASTERY] " .. wName .. ": " .. tostring(wMas) .. " / " .. tostring(reqMas))
                
                -- Nếu có đồ và đủ mastery thì lưu lại
                if hasW and wMas >= reqMas then
                    table.insert(reasons, wName .. "_Mas" .. math.floor(wMas))
                else
                    allMasteryDone = false -- Thiếu đồ hoặc chưa đủ điểm thì đéo cho lượn
                end
            end

            -- Nếu đủ tất cả các yêu cầu Mastery thì bật cờ cho bay Acc
            if hasAnyTarget and allMasteryDone then
                isReadyToJump = true
                jumpReason = table.concat(reasons, "_")
            end
        end

        -- Check nguyên liệu lẻ
        if Config.Target_DinosaurBones and materials.Dino >= (tonumber(Config.Target_DinosaurBones) or 1) then table.insert(foundTargets, "Dino_"..materials.Dino) end
        if Config.Target_DragonScale and materials.Scale >= (tonumber(Config.Target_DragonScale) or 1) then table.insert(foundTargets, "Scale_"..materials.Scale) end
        if Config.Target_BlazeEmber and materials.Ember >= (tonumber(Config.Target_BlazeEmber) or 1) then table.insert(foundTargets, "Ember_"..materials.Ember) end

        -- XUẤT FILE ĐỔI ACC
        if isReadyToJump then
            print("[CHECKER] ĐÃ ĐẠT ĐIỀU KIỆN! ĐANG XUẤT FILE ĐỔI ACC...")
            if writefile then writefile(player.Name .. ".txt", (Config.Prefix or "Completed-") .. jumpReason) end
            break
        elseif #foundTargets > 0 or #foundBelts > 0 or hasRB then
            local res = {}
            if hasRB then table.insert(res, "Rainbow") end
            for _, v in ipairs(foundTargets) do table.insert(res, v) end
            for _, v in ipairs(foundBelts) do table.insert(res, v) end
            
            local status = table.concat(res, "_")
            print("[CHECKER] ĐỔI ACC VÌ ĐỦ NGUYÊN LIỆU/ĐAI: " .. status)
            if writefile then writefile(player.Name .. ".txt", (Config.Prefix or "Completed-") .. status) end
            break
        end
    end
end)
