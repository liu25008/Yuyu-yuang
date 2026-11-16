return function(LiuGhost)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")

	local lp = Players.LocalPlayer
	local cfg = {
		visible = LiuGhost.State.Moonwalk == true, -- toggle GUI: tampilkan / sembunyikan tombol MW
		enabled = false,                           -- status moonwalk (tap tombol MW)
		turnSpeed = 0.35,
	}
	local conns = {}

	local function getParts()
		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		return char, hum, root
	end

	local function applyAutoRotate()
		local _, hum = getParts()
		if hum then hum.AutoRotate = not cfg.enabled end
	end

	local function guiAlive()
		local pg = lp:FindFirstChild("PlayerGui")
		return pg ~= nil and pg:FindFirstChild("LiuGhost") ~= nil
	end

	----------------------------------------------------------------
	-- TOMBOL MW (tap = toggle, geser = pindah posisi)
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
	stroke.Color = Color3.fromRGB(70, 70, 74)
	stroke.Thickness = 1.5

	local function paint()
		TweenService:Create(btn, TweenInfo.new(0.2), {
			BackgroundColor3 = cfg.enabled and Color3.fromRGB(235, 235, 235) or Color3.fromRGB(22, 22, 24),
			TextColor3 = cfg.enabled and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(200, 200, 200),
		}):Play()
	end

	local function setEnabled(v)
		cfg.enabled = v
		applyAutoRotate()
		paint()
	end

	local pressing, moved = false, false
	local startInput, startPos

	table.insert(conns, btn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			pressing, moved = true, false
			startInput = i.Position
			startPos = btn.Position
		end
	end))

	table.insert(conns, UserInputService.InputChanged:Connect(function(i)
		if not pressing then return end
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			local d = i.Position - startInput
			if d.Magnitude > 8 then moved = true end
			if moved then
				btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end
	end))

	table.insert(conns, UserInputService.InputEnded:Connect(function(i)
		if not pressing then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			pressing = false
			if not moved then setEnabled(not cfg.enabled) end
		end
	end))

	----------------------------------------------------------------
	-- MOONWALK: badan menghadap berlawanan arah gerak
	----------------------------------------------------------------
	local renderConn
	renderConn = RunService.RenderStepped:Connect(function()
		-- GUI ditutup: bersihkan semuanya
		if not guiAlive() then
			renderConn:Disconnect()
			for _, c in ipairs(conns) do c:Disconnect() end
			table.clear(conns)
			cfg.enabled = false
			applyAutoRotate()
			gui:Destroy()
			return
		end

		if not cfg.visible or not cfg.enabled then return end
		local _, hum, root = getParts()
		if not hum or not root or hum.Health <= 0 then return end

		local dir = hum.MoveDirection
		if dir.Magnitude < 0.1 then return end

		local back = Vector3.new(-dir.X, 0, -dir.Z)
		local goal = CFrame.lookAt(root.Position, root.Position + back)
		root.CFrame = root.CFrame:Lerp(goal, cfg.turnSpeed)
	end)

	table.insert(conns, lp.CharacterAdded:Connect(function()
		task.wait(0.3)
		applyAutoRotate()
	end))

	----------------------------------------------------------------
	-- HOOK DARI GUI
	----------------------------------------------------------------
	LiuGhost.Hooks.Moonwalk = function(state)
		cfg.visible = state == true
		btn.Visible = cfg.visible
		if not cfg.visible and cfg.enabled then
			setEnabled(false)
		end
	end
end
