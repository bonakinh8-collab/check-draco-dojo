local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local commF = replicatedStorage:FindFirstChild("Remotes") and replicatedStorage.Remotes:FindFirstChild("CommF_")

-- Hàm kiểm tra xem có item trong Inventory không (dùng cho Đai cam và CDK)
local function checkItemInInventory(itemName)
    if not commF then return false end
    local success, inventory = pcall(function()
        return commF:InvokeServer("getInventory")
    end)
    if success and type(inventory) == "table" then
        for _, item in pairs(inventory) do
            if item.Name == itemName then return true end
        end
    end
    return false
end

-- Hàm check Godhuman
local function checkGodhuman()
    -- Cách 1: Check xem player có đang cầm hoặc có sẵn trong túi đồ không
    if player.Backpack:FindFirstChild("Godhuman") or (player.Character and player.Character:FindFirstChild("Godhuman")) then
        return true
    end
    
    -- Cách 2: Gọi thử qua server để check (Tham số true thường để check/trang bị mà không tốn tiền)
    if commF then
        local success, result = pcall(function()
            return commF:InvokeServer("BuyGodhuman", true)
        end)
        if success and result and type(result) ~= "string" then 
            return true 
        end
    end
    
    return false
end

-- Hàm xuất file tổng hợp cho Yummytool
local function notifyYummyTool()
    if not player then return end
    
    -- Khởi tạo chuỗi tên trạng thái (Vì gọi hàm này là chắc chắn đã có Đai cam)
    local accountStatus = "DaiCam" 
    
    -- Kiểm tra thêm Godhuman và CDK
    if checkGodhuman() then
        accountStatus = accountStatus .. "_God"
    end
    
    if checkItemInInventory("Cursed Dual Katana") then
        accountStatus = accountStatus .. "_CDK"
    end
    
    -- Tạo nội dung file chuẩn cú pháp Yummytool
    local fileContent = "Completed-" .. accountStatus
    local fileName = player.Name .. ".txt"
    
    if writefile then
        writefile(fileName, fileContent)
        print("Đã tạo file " .. fileName .. " với nội dung: " .. fileContent)
    else
        warn("Lỗi: Executor không hỗ trợ ghi file (writefile)!")
    end
end

-- Vòng lặp tự động check
task.spawn(function()
    print("Bắt đầu tự động kiểm tra Dojo Belt (Orange)...")
    while task.wait(10) do
        -- Nếu tìm thấy Đai cam
        if checkItemInInventory("Dojo Belt (Orange)") then
            print("Đã farm xong Đai cam! Đang kiểm tra Godhuman và CDK...")
            -- Gọi hàm kiểm tra tổng hợp và xuất file
            notifyYummyTool()
            break -- Dừng vòng lặp để tool change acc
        end
    end
end)
