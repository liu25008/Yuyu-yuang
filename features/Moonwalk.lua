return function(LiuGhost)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")

	local lp = Players.LocalPlayer
	local cfg = { visible = LiuGhost.State.Moonwalk == true, holding = false, turnSpeed = 0.35 }

	local function getParts()
		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		return char, hum, root
	end

	local function applyAutoRotate()
		local _, hum = getParts()
		if hum then hum.AutoRotate = not cfg.holding end
	end

	local function guiAlive()
		local pg = lp:FindFirstChild("PlayerGui")
		return pg ~= nil and pg:FindFirstChild("LiuGhost") ~= nil
	end

	----------------------------------------------------------------
	-- TOMBOL MW (hold = moonwalk, geser jauh = pindah posisi)
	----------------------------------------------------------------
	local gui = Instance.new("ScreenGui")
	gui.Name = "LiuGhostMW"
	gui.ResetOnSpawn = false
	gui.Parent = lp:WaitForChild("PlayerGui")

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(56, 56)
	btn.Position = UDim2.new(1, -90, 0.55, 0)
	btn.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
	btn.AutoButtonColor = false
	btn.Text = "MW"
	btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 15
	btn.BorderSizePixel = 0
	btn.Visible = cfg.visible
	btn.Parent = gui
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fro
