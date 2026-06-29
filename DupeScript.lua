-- ==================================================
-- DUPE TOOL SCRIPT - Client-Side Only
-- Không sử dụng RemoteEvent. Chạy độc lập.
-- ==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ==================================================
-- TẠO GUI
-- ==================================================

-- Xóa GUI cũ nếu tồn tại (tránh bị nhân đôi khi chạy lại)
local existingGui = LocalPlayer.PlayerGui:FindFirstChild("DupeGui")
if existingGui then
    existingGui:Destroy()
end

-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DupeGui"
ScreenGui.ResetOnSpawn = false  -- Không mất khi hồi sinh
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

-- Tạo nút DupeButton
local DupeButton = Instance.new("TextButton")
DupeButton.Name = "DupeButton"
DupeButton.Size = UDim2.new(0, 130, 0, 50)
DupeButton.Position = UDim2.new(0, 20, 0.5, -25) -- Giữa màn hình, bên trái
DupeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
DupeButton.TextColor3 = Color3.fromRGB(0, 220, 255)
DupeButton.Text = "DUPE TOOL"
DupeButton.Font = Enum.Font.GothamBold
DupeButton.TextSize = 15
DupeButton.BorderSizePixel = 0
DupeButton.AutoButtonColor = false
DupeButton.ZIndex = 10
DupeButton.Parent = ScreenGui

-- Bo góc cho nút
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = DupeButton

-- Viền nhẹ
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 200, 255)
UIStroke.Thickness = 1.5
UIStroke.Parent = DupeButton

-- ==================================================
-- LOGIC KÉO THẢ MƯỢT MÀ (Touch + Mouse)
-- ==================================================

local dragging = false
local dragStartPos = nil      -- Vị trí chạm/click ban đầu (trên màn hình)
local buttonStartPos = nil    -- Vị trí nút ban đầu (offset pixels)
local didDrag = false         -- Phân biệt kéo vs bấm

local function getAbsolutePosition(button)
    -- Trả về vị trí góc trên-trái của nút tính bằng pixel
    return Vector2.new(
        button.AbsolutePosition.X,
        button.AbsolutePosition.Y
    )
end

-- Bắt đầu kéo (dùng chung cho cả Touch và Mouse)
local function onDragStart(inputPosition)
    dragging = true
    didDrag = false
    dragStartPos = inputPosition
    buttonStartPos = getAbsolutePosition(DupeButton)
end

-- Trong lúc kéo
local function onDragMove(inputPosition)
    if not dragging then return end

    local delta = inputPosition - dragStartPos

    -- Nếu di chuyển đủ xa thì coi là đang kéo (không phải bấm)
    if delta.Magnitude > 5 then
        didDrag = true
    end

    -- Tính vị trí mới (pixel)
    local newX = buttonStartPos.X + delta.X
    local newY = buttonStartPos.Y + delta.Y

    -- Giới hạn trong màn hình
    local screenSize = ScreenGui.AbsoluteSize
    local btnSize = DupeButton.AbsoluteSize
    newX = math.clamp(newX, 0, screenSize.X - btnSize.X)
    newY = math.clamp(newY, 0, screenSize.Y - btnSize.Y)

    -- Cập nhật vị trí (dùng Offset để tránh nhảy)
    DupeButton.Position = UDim2.new(0, newX, 0, newY)
end

-- Kết thúc kéo
local function onDragEnd()
    dragging = false
end

-- ==================================================
-- KẾT NỐI SỰ KIỆN INPUT
-- ==================================================

-- TOUCH (Mobile)
DupeButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        onDragStart(Vector2.new(input.Position.X, input.Position.Y))
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        onDragMove(Vector2.new(input.Position.X, input.Position.Y))
    elseif input.UserInputType == Enum.UserInputType.MouseMovement then
        onDragMove(Vector2.new(input.Position.X, input.Position.Y))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        onDragEnd()
    end
end)

-- MOUSE (PC / Emulator)
DupeButton.MouseButton1Down:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    onDragStart(mousePos)
end)

-- ==================================================
-- HIỆU ỨNG HOVER / PRESS
-- ==================================================

DupeButton.MouseEnter:Connect(function()
    DupeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
end)

DupeButton.MouseLeave:Connect(function()
    DupeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
end)

DupeButton.MouseButton1Down:Connect(function()
    DupeButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
end)

DupeButton.MouseButton1Up:Connect(function()
    DupeButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
end)

-- ==================================================
-- CHỨC NĂNG NHÂN BẢN TOOL (CLIENT-SIDE)
-- ==================================================

DupeButton.MouseButton1Click:Connect(function()
    -- Nếu vừa kéo thì không thực hiện dupe
    if didDrag then
        didDrag = false
        return
    end

    -- Lấy Character hiện tại
    local character = LocalPlayer.Character
    if not character then
        warn("[DupeTool] Không tìm thấy Character.")
        return
    end

    -- Tìm Tool đang được trang bị (con của Character)
    local equippedTool = nil
    for _, obj in ipairs(character:GetChildren()) do
        if obj:IsA("Tool") then
            equippedTool = obj
            break
        end
    end

    if not equippedTool then
        -- Thông báo trực quan ngắn gọn
        DupeButton.Text = "Cầm Tool!"
        task.delay(1.5, function()
            DupeButton.Text = "DUPE TOOL"
        end)
        return
    end

    -- Nhân bản tool hoàn toàn phía Client
    local clonedTool = equippedTool:Clone()

    -- Đưa tool nhân bản vào Backpack
    clonedTool.Parent = LocalPlayer.Backpack

    -- Phản hồi thành công
    local originalText = DupeButton.Text
    DupeButton.Text = "✓ DONE!"
    DupeButton.TextColor3 = Color3.fromRGB(0, 255, 150)
    task.delay(1.2, function()
        DupeButton.Text = originalText
        DupeButton.TextColor3 = Color3.fromRGB(0, 220, 255)
    end)

    print("[DupeTool] Đã nhân bản:", equippedTool.Name)
end)

print("[DupeTool] Script đã khởi động thành công!")