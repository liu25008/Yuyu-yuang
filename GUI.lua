local GUI = {}

function GUI.Create(player)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "YuyuYuangGUI"
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.fromOffset(230, 160)
    frame.Position = UDim2.new(0.5, -115, 0.5, -80)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Yuyu-Yuang"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 20
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Position = UDim2.fromOffset(10, 50)
    status.Size = UDim2.new(1, -20, 0, 30)
    status.BackgroundTransparency = 1
    status.Text = "TRAINING: OFF"
    status.TextColor3 = Color3.fromRGB(220, 100, 100)
    status.Parent = frame

    local toggle = Instance.new("TextButton")
    toggle.Position = UDim2.fromOffset(15, 95)
    toggle.Size = UDim2.new(1, -30, 0, 40)
    toggle.Text = "ENABLE TRAINING"
    toggle.Parent = frame

    local enabled = false

    toggle.Activated:Connect(function()
        enabled = not enabled

        status.Text = enabled
            and "TRAINING: ON"
            or "TRAINING: OFF"

        toggle.Text = enabled
            and "DISABLE TRAINING"
            or "ENABLE TRAINING"

        status.TextColor3 = enabled
            and Color3.fromRGB(80, 220, 120)
            or Color3.fromRGB(220, 100, 100)
    end)

    screenGui.Parent = player:WaitForChild("PlayerGui")

    return screenGui
end

return GUI
