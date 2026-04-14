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

    -- Hàm check Item và Mastery chuẩn 100%
    local function GetItemData(targetName)
        local found = false
        local mastery = 0
        local cleanTarget = string.lower(string.gsub(targetName, "%s+", ""))

        pcall(function()
            -- Quét trong Túi đồ (Inventory)
            local inv = commF:InvokeServer("getInventory")
            for _, v in pairs(inv) do
                if v.Name and string.lower(string.gsub(v.Name, "%s+", "")) == cleanTarget then
                    found = true
                    mastery = tonumber(v.Mastery) or 0
                    break
                end
            end
            -- Quét thêm trong Balo và Trên tay nếu cần
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
        local foundMastery = {} 
        
        -- 1. KIỂM TRA TỘC DRACO
        local hasDraco = false
        pcall(function()
            if player:FindFirstChild("Data") and player.Data:FindFirstChild("Race") then
                local raceVal = tostring(player.Data.Race.Value)
                if string.find(string.lower(raceVal), "draco") then hasDraco = true end
            end
        end)

        -- 2. QUÉT SÚNG & KIẾM (Dragonheart / Dragonstorm)
        local hasStorm, stormMas = GetItemData("Dragonstorm")
        local hasHeart, heartMas = GetItemData("Dragonheart")

        -- 3. QUÉT NGUYÊN LIỆU & ĐAI
        local materials = {Dino = 0, Scale = 0, Ember = 0}
        pcall(function()
            local inv = commF:InvokeServer("getInventory")
            for _, v in pairs(inv) do
                local n = v.Name or ""
                if n == "Dinosaur Bones" or n == "Dinosaur Bone" then materials.Dino = tonumber(v.Count or v.Quantity) or 0 end
                if n == "Dragon Scale" then materials.Scale = tonumber(v.Count or v.Quantity) or 0 end
                if n == "Blaze Ember" then materials.Ember = tonumber(v.Count or v.Quantity) or 0 end
                
                for cfgKey, bName in pairs(beltMap) do
                    if Config[cfgKey] and n == bName then table.insert(foundBelts, bName) end
                end
            end
        end)

        -- 4. KIỂM TRA HAKI RAINBOW
        local hasRB = false
        if Config.Target_RainbowHaki then
            pcall(function()
                local titles = commF:InvokeServer("getTitles")
                for _, v in pairs(titles) do
                    if string.find(v.Name or "", "Final Hero") or string.find(v.Name or "", "Rainbow") then
                        if not string.find(string.upper(v.Name), "LOCKED") then hasRB = true break end
                    end
                end
            end)
        end

        -- =======================================================
        -- LOGIC CHANGER (ĐỔI ACC)
        -- =======================================================
        
        -- Mục 3: Combo Draco (Tộc + 2 Vũ khí là sút luôn)
        if Config.Target_ComboDraco then
            print("[DEBUG] Draco: "..tostring(hasDraco).." | Storm: "..tostring(hasStorm).." | Heart: "..tostring(hasHeart))
            if hasDraco and hasStorm and hasHeart then
                table.insert(foundTargets, "ComboDraco_Instant")
            end
        end

        -- Mục 4: Mastery Custom (Kiểm tra số điểm)
        if Config.Target_Mastery then
            if Config.Target_Mastery["Dragonstorm"] and hasStorm and stormMas >= Config.Target_Mastery["Dragonstorm"] then
                table.insert(foundMastery, "Dragonstorm_Mas"..stormMas)
            end
            if Config.Target_Mastery["Dragonheart"] and hasHeart and heartMas >= Config.Target_Mastery["Dragonheart"] then
                table.insert(foundMastery, "Dragonheart_Mas"..heartMas)
            end
        end

        -- Mục 2: Nguyên liệu
        if Config.Target_DinosaurBones and materials.Dino >= (tonumber(Config.Target_DinosaurBones) or 1) then table.insert(foundTargets, "Dino_"..materials.Dino) end
        if Config.Target_DragonScale and materials.Scale >= (tonumber(Config.Target_DragonScale) or 1) then table.insert(foundTargets, "Scale_"..materials.Scale) end
        if Config.Target_BlazeEmber and materials.Ember >= (tonumber(Config.Target_BlazeEmber) or 1) then table.insert(foundTargets, "Ember_"..materials.Ember) end

        -- XUẤT FILE
        local res = {}
        if hasRB then table.insert(res, "Rainbow") end
        for _, v in ipairs(foundTargets) do table.insert(res, v) end
        for _, v in ipairs(foundBelts) do table.insert(res, v) end
        for _, v in ipairs(foundMastery) do table.insert(res, v) end

        if #res > 0 then
            local status = table.concat(res, "_")
            print("[SUCCESS] ĐỔI ACC: " .. status)
            if writefile then writefile(player.Name .. ".txt", (Config.Prefix or "Done-") .. status) end
            break
        end
    end
end)
