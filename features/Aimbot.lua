return function(LiuGhost)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local lp = Players.LocalPlayer
	local cam = workspace.CurrentCamera

	----------------------------------------------------------------
	-- KONFIG
	----------------------------------------------------------------
	local modeNames = { "Pistol", "Jeff", "Cure" }
	local modes = {
		Pistol = { speed = 0,  drop = 0,   fov = 160, smooth = 0.35, part = "Head" },
		Jeff   = { speed = 0,  drop = 0,   fov = 260, smooth = 0.5,  part = "HumanoidRootPart", maxDist = 25 },
		Cure   = { speed = 90, drop = 0.5, fov = 220, smooth = 0.3,  part = "HumanoidRootPart" },
	}

	local function stateBool(id, default)
		local v = LiuGhost.State[id]
		if v == nil then return default end
		return v == true
	end

	local cfg = {
		enabled = stateBool("Aimbot", false),
		hold = stateBool("AimHold", true),
		wallCheck = stateBool("AimWall", true),
		mode = modeNames[math.clamp(tonumber(LiuGhost.State.AimMode) or 1, 1, 3)],
	}
	local holding = false

	----------------------------------------------------------------
	-- PERAN LAWAN (survivor -> target killer, killer -> target survivor)
	----------------------------------------------------------------
	local function isKillerPlayer(plr)
		local t = plr.Team and string.lower(plr.Team.Name) or ""
		if string.find(t, "killer", 1, true) then return true end
		local c = plr.Character
		return c ~= nil and c:GetAttribute("Killer") == true
	end

	local function isEnemy(plr)
		if plr == lp then return false end
		return isKillerPlayer(lp) ~= isKillerPlayer(plr)
	end

	local function visible(part, char)
		if not cfg.wallCheck then return true end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { lp.Character, char }
		local origin = cam.CFrame.Position
		return workspace:Raycast(origin, part.Position - origin, params) == nil
	end

	local function aimPoint(part, m)
		local pos = part.Position
		local dist = (pos - cam.CFrame.Position).Magnitude
		if m.speed > 0 then
			local t = dist / m.speed
			pos += part.AssemblyLinearVelocity * t
			pos += Vector3.new(0, m.drop * t * t * workspace.Gravity * 0.5 * 0.1, 0)
		end
		return pos
	end

	local function getTarget()
		local m = modes[cfg.mode]
		local best, bestScore
		local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
		local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")

		for _, plr in ipairs(Players:GetPlayers()) do
			if isEnemy(plr) and plr.Character then
				local hum = plr.Character:FindFirstChildOfClass("Humanoid")
				local part = plr.Character:FindFirstChild(m.part) or plr.Character:FindFirstChild("HumanoidRootPart")
				if hum and part and hum.Health > 0 then
					local sp, onScreen = cam:WorldToViewportPoint(part.Position)
					if onScreen then
						local d2 = (Vector2.new(sp.X, sp.Y) - center).Magnitude
						local d3 = myRoot and (part.Position - myRoot.Position).Magnitude or 0
						local inRange = (not m.maxDist) or d3 <= m.maxDist
						if d2 <= m.fov and inRange and visible(part, plr.Character) then
							if not bestScore or d2 < bestScore then
								best, bestScore = part, d2
							end
						end
					end
				end
			end
		end
		return best
	end

	----------------------------------------------------------------
	-- LINGKARAN FOV
	----------------------------------------------------------------
	local ringGui = Instance.new("ScreenGui")
	ringGui.Name = "LiuGhostAimRing"
	ringGui.ResetOnSpawn = false
	ringGui.IgnoreGuiInset = true
	ringGui.Parent = lp:WaitForChild("PlayerGui")

	local fovRing = Instance.new("Frame")
	fovRing.AnchorPoint = Vector2.new(0.5, 0.5)
	fovRing.Position = UDim2.fromScale(0.5, 0.5)
	fovRing.BackgroundTransparency = 1
	fovRing.Visible = false
	fovRing.Parent = ringGui
	Instance.new("UICorner", fovRing).CornerRadius = UDim.new(1, 0)

	local ringStroke = Instance.new("UIStroke", fovRing)
	ringStroke.Color = Color3.fromRGB(200, 200, 200)
	ringStroke.Thickness = 1
	ringStroke.Transparency = 0.5

	local function refreshRing()
		local f = modes[cfg.mode].fov
		fovRing.Size = UDim2.fromOffset(f * 2, f * 2)
		fovRing.Visible = cfg.enabled
	end
	refreshRing()

	----------------------------------------------------------------
	-- INPUT + LOOP
	----------------------------------------------------------------
	local conns = {}

	table.insert(conns, UserInputService.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton2 then holding = true end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton2 then holding = false end
	end))

	local function guiAlive()
		local pg = lp:FindFirstChild("PlayerGui")
		return pg ~= nil and pg:FindFirstChild("LiuGhost") ~= nil
	end

	local renderConn
	renderConn = RunService.RenderStepped:Connect(function()
		-- GUI ditutup: bersihkan semuanya
		if not guiAlive() then
			renderConn:Disconnect()
			for _, c in ipairs(conns) do c:Disconnect() end
			ringGui:Destroy()
			return
		end

		cam = workspace.CurrentCamera
		if not cfg.enabled then return end
		if cfg.hold and not holding then return end

		local part = getTarget()
		if not part then return end
		local m = modes[cfg.mode]
		local goal = CFrame.lookAt(cam.CFrame.Position, aimPoint(part, m))
		cam.CFrame = cam.CFrame:Lerp(goal, m.smooth)
	end)

	----------------------------------------------------------------
	-- HOOKS DARI GUI
	----------------------------------------------------------------
	LiuGhost.Hooks.Aimbot = function(state)
		cfg.enabled = state == true
		refreshRing()
	end

	LiuGhost.Hooks.AimMode = function(value)
		local idx = math.clamp(math.floor((tonumber(value) or 1) + 0.5), 1, 3)
		cfg.mode = modeNames[idx]
		refreshRing()
	end

	LiuGhost.Hooks.AimHold = function(state)
		cfg.hold = state == true
	end

	LiuGhost.Hooks.AimWall = function(state)
		cfg.wallCheck = state == true
	end
end
