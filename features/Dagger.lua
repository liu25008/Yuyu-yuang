return function(LiuGhost)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local lp = Players.LocalPlayer

	----------------------------------------------------------------
	-- AUTO DAGGER
	----------------------------------------------------------------
	local cooldown = 0.35
	local lastHit = 0

	local function enabled()
		return LiuGhost.State.AutoDagger == true
	end

	local function radius()
		return LiuGhost.State.DaggerRadius or 15
	end

	local function findDagger()
		local char = lp.Character
		if char then
			for _, t in ipairs(char:GetChildren()) do
				if t:IsA("Tool") and string.find(string.lower(t.Name), "dagger") then return t end
			end
		end
		local bp = lp:FindFirstChildOfClass("Backpack")
		if bp then
			for _, t in ipairs(bp:GetChildren()) do
				if t:IsA("Tool") and string.find(string.lower(t.Name), "dagger") then return t end
			end
		end
	end

	local function nearestTarget(myRoot)
		local best, bestDist
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp and p.Character then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				local root = p.Character:FindFirstChild("HumanoidRootPart")
				if hum and root and hum.Health > 0 then
					local d = (root.Position - myRoot.Position).Magnitude
					if d <= radius() and (not bestDist or d < bestDist) then
						best, bestDist = root, d
					end
				end
			end
		end
		return best
	end

	local ring = Instance.new("Part")
	ring.Name = "DaggerRadius"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.SmoothPlastic
	ring.Color = Color3.fromRGB(200, 200, 200)
	ring.Transparency = 1
	ring.Parent = workspace

	local function updateRing(myRoot)
		if enabled() and myRoot then
			local r = radius()
			ring.Transparency = 0.85
			ring.Size = Vector3.new(0.15, r * 2, r * 2)
			ring.CFrame = CFrame.new(myRoot.Position - Vector3.new(0, 2.9, 0)) * CFrame.Angles(0, 0, math.rad(90))
		else
			ring.Transparency = 1
		end
	end

	RunService.Heartbeat:Connect(function()
		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local myRoot = char and char:FindFirstChild("HumanoidRootPart")
		updateRing(myRoot)
		if not enabled() or not hum or not myRoot or hum.Health <= 0 then return end
		if os.clock() - lastHit < cooldown then return end
      if _G.VD_HoldDagger then return end

		local target = nearestTarget(myRoot)
		if not target then return end

		local dagger = findDagger()
		if not dagger then return end
		if dagger.Parent ~= char then hum:EquipTool(dagger) end

		myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(target.Position.X, myRoot.Position.Y, target.Position.Z))
		lastHit = os.clock()
		dagger:Activate()
	end)

	----------------------------------------------------------------
	-- ANTI FAKE HIT (toggle: FakeHit)
	----------------------------------------------------------------
	local fakeRange = 15
	local fakeBuffer = 0.45
	local keywords = { "attack", "swing", "slash", "hit", "stab", "lunge", "swipe" }

	local active = 0
	local holdUntil = 0

	_G.VD_HoldDagger = false

	local function fakeEnabled()
		return LiuGhost.State.FakeHit == true
	end

	local function isAttackAnim(track)
		local n = track.Name
		if track.Animation then n = n .. " " .. track.Animation.Name end
		n = string.lower(n)
		for _, k in ipairs(keywords) do
			if string.find(n, k, 1, true) then return true end
		end
		return false
	end

	local function watchCharacter(plr, char)
		local hum = char:WaitForChild("Humanoid", 5)
		if not hum then return end
		local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5)
		if not animator then return end
		local root = char:FindFirstChild("HumanoidRootPart")

		animator.AnimationPlayed:Connect(function(track)
			if not fakeEnabled() or not isAttackAnim(track) then return end
			local myChar = lp.Character
			local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if not myRoot or not root then return end
			if (root.Position - myRoot.Position).Magnitude > fakeRange then return end

			active += 1
			track.Stopped:Once(function()
				active = math.max(0, active - 1)
				holdUntil = os.clock() + fakeBuffer
			end)
		end)
	end

	local function hookPlayer(plr)
		if plr == lp then return end
		plr.CharacterAdded:Connect(function(char) task.spawn(watchCharacter, plr, char) end)
		if plr.Character then task.spawn(watchCharacter, plr, plr.Character) end
	end

	for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
	Players.PlayerAdded:Connect(hookPlayer)

	RunService.Heartbeat:Connect(function()
		_G.VD_HoldDagger = fakeEnabled() and (active > 0 or os.clock() < holdUntil)
	end)

	----------------------------------------------------------------
	-- HOOKS DARI GUI
	----------------------------------------------------------------
	LiuGhost.Hooks.AutoDagger = function(state)
		if not state then ring.Transparency = 1 end
	end

	LiuGhost.Hooks.DaggerRadius = function(value)
		-- dibaca langsung dari State di loop
	end

	LiuGhost.Hooks.FakeHit = function(state)
		if not state then
			active = 0
			holdUntil = 0
			_G.VD_HoldDagger = false
		end
	end
end
