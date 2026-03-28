local Config = _G.YummyConfig or {
    Target_RainbowHaki = true,
    Target_Belts = {},
    Prefix = "Completed-"
}

local player = game.Players.LocalPlayer
local rs = game:GetService("ReplicatedStorage")

task.spawn(function()
    while not player do task.wait(1); player = game.Players.LocalPlayer end
    local commF = rs:WaitForChild("Remotes", 9e9):WaitForChild("CommF_", 9e9)

    while task.wait(10) do 
        local foundHaki = nil
        local foundBelt = nil
        local vipItems = {}

        pcall(function()
            local inv = commF:InvokeServer("getInventory")
            if type(inv) == "table" then
                for _, item in pairs(inv) do
                    if type(item) == "table" and item.Name then
                        local iName = item.Name
                        
                        if Config.Target_Belts then
                            for _, bName in ipairs(Config.Target_Belts) do
                                if iName == bName then
                                    foundBelt = iName
                                end
                            end
                        end
                        
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
                                    foundHaki = "Rainbow"
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end

        local status = ""
        if foundHaki and foundBelt then
            status = foundHaki .. "_" .. foundBelt
        elseif foundHaki then
            status = foundHaki
        elseif foundBelt then
            status = foundBelt
        end

        if status ~= "" then
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
