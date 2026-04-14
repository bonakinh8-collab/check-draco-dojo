local Config = _G.YummyConfig or {}
local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

task.spawn(function()
    while not player do task.wait(1); player = game.Players.LocalPlayer end
    local commF = rs:WaitForChild("Remotes", 9e9):WaitForChild("CommF_", 9e9)

    -- Chỉ cho in 1 lần để F9 đỡ bị trôi tin nhắn
    local hasPrintedDump = false 

    while task.wait(5) do 
        local Draco = false
        local Storm = false
        local Heart = false

        -- 1. KIỂM TRA TỘC
        pcall(function()
            if player:FindFirstChild("Data") and player.Data:FindFirstChild("Race") then
                local raceVal = tostring(player.Data.Race.Value)
                if raceVal == "Draco" or string.find(string.lower(raceVal), "draco") or string.find(string.lower(raceVal), "dragon") then
                    Draco = true
                end
            end
        end)

        -- 2. QUÉT BALO & IN RA F9
        pcall(function()
            if player:FindFirstChild("Backpack") then
                for _, tool in pairs(player.Backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        if not hasPrintedDump then
                            print("[TRÊN TAY/BALO CÓ:] => [" .. tostring(tool.Name) .. "]")
                        end
                        local tName = string.lower(tool.Name)
                        if string.find(tName, "dragon storm") then Storm = true end
                        if string.find(tName, "dragon heart") then Heart = true end
                    end
                end
            end
        end)

        -- 3. QUÉT TÚI ĐỒ (INVENTORY) VÀ IN RA F9
        pcall(function()
            local inv = commF:InvokeServer("getInventory")
            if type(inv) == "table" then
                for i, v in pairs(inv) do
                    if type(v) == "table" and v.Name then
                        if not hasPrintedDump then
                            -- Tao kẹp nó vào dấu ngoặc vuông để xem nó có bị dư dấu cách không
                            print("[TRONG TÚI CÓ:] => [" .. tostring(v.Name) .. "]") 
                        end
                        
                        local lowerName = string.lower(v.Name)
                        if string.find(lowerName, "dragon storm") then Storm = true end
                        if string.find(lowerName, "dragon heart") then Heart = true end
                    end
                end
            end
        end)

        -- Đánh dấu đã in xong để đéo spam F9 nữa
        hasPrintedDump = true

        -- =======================================================
        -- 4. BÁO CÁO KẾT QUẢ CHECK 3 MÓN
        -- =======================================================
        if Config.Target_ComboDraco then
            print("[DEBUG CHECK] Tộc Draco: " .. tostring(Draco) .. " | Storm: " .. tostring(Storm) .. " | Heart: " .. tostring(Heart))
            
            if Draco == true and Storm == true and Heart == true then
                print("[CHECKER] ĐỦ 3 MÓN! ĐANG ĐỔI ACC...")
                pcall(function()
                    if writefile then
                        writefile(player.Name .. ".txt", (Config.Prefix or "Completed-") .. "ComboDraco_Done")
                    end
                end)
                break
            end
        end
    end
end)
