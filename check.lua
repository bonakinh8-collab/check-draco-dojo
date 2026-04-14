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

    -- ==========================================
    -- HÀM LẤY ITEM & MASTERY XỊN (ÉP CHẾT LỖI DẤU CÁCH)
    -- ==========================================
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
            -- Quét dự phòng trong balo
            if not found then
                local tool = player.Backpack:FindFirstChild(targetName) or (player.Character and player.Character:FindFirstChild(targetName))
                if tool then found = true end
            end
        end)
        return found, mastery
    end

    -- ==========================================
    -- VÒNG LẶP CHANGER
    -- ==========================================
    while task.wait(10) do
        local foundTargets = {} 
        local foundBelts = {}
        local materials = {Dino = 0, Scale = 0, Ember = 0}

        -- 1. Quét Tộc
        local hasDraco = false
        pcall(function()
            if player:FindFirstChild("Data") and player.Data:FindFirstChild("Race") then
                local raceVal = tostring(player.Data.Race.Value)
                if string.find(string.lower(raceVal), "draco") then hasDraco = true end
            end
        end)

        -- 2. Quét Súng & Kiếm bằng hàm xịn
        local hasStorm, stormMas = GetItemData("Dragonstorm")
        local hasHeart, heartMas = GetItemData("Dragonheart")

        -- 3. Quét Nguyên liệu & Đai
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

        -- 4. Quét Haki
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
            print("[DEBUG] Draco: " .. tostring(hasDraco) .. " | Storm: " .. tostring(hasStorm) .. " | Heart: " .. tostring(hasHeart))
            if hasDraco and hasStorm and hasHeart then
                isReadyToJump = true
                jumpReason = "ComboDraco_Instant"
            end
        end

        -- [MỤC 4] Mastery Custom (Cày đủ điểm mới đổi)
        -- (Chỉ chạy nếu Mục 3 đang tắt)
        if Config.Target_Mastery and not Config.Target_ComboDraco then
            local reqStorm = Config.Target_Mastery["Dragonstorm"]
            local reqHeart = Config.Target_Mastery["Dragonheart"]
            
            local stormDone = true
            if reqStorm then stormDone = (hasStorm and stormMas >= reqStorm) end
            
            local heartDone = true
            if reqHeart then heartDone = (hasHeart and heartMas >= reqHeart) end

            print("[DEBUG MASTERY] Storm: " .. stormMas .. "/" .. tostring(reqStorm or "Tắt") .. " | Heart: " .. heartMas .. "/" .. tostring(reqHeart or "Tắt"))

            if stormDone and heartDone and hasDraco and (reqStorm or reqHeart) then
                isReadyToJump = true
                jumpReason = "ComboDraco_MaxMastery"
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
