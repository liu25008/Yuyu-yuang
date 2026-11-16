return function(LiuGhost)
	local Players = game:GetService("Players")
	local RS = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local VIM = game:GetService("VirtualInputManager")

	local lp = Players.LocalPlayer

	----------------------------------------------------------------
	-- KONFIG
	----------------------------------------------------------------
	local keywords = { "vault", "window", "pallet", "mantle", "climb" }
	local PERCENT_PER_UNIT = 0.15

	local GenCfg = {
		Range = 12,
		GenKeyword = "generator",
		RemoteKeywords = { "repair", "skillcheck", "generator" },
		InstanSpeed = 0.05,
		PerfectDelay = 0.35,
	}

	local cfg = {
		
		autoGen = false,
		genMode = LiuGhost.State.AutoGenMode or "Perfect",
	}

	local function guiAlive()
		local ok, hui = pcall(function() return gethui and gethui() end)
		if ok and hui and hui:FindFirstChild("LiuGhost") then return true end
		local pg = lp:FindFirstChild("PlayerGui")
		return pg ~= nil and pg:FindFirstChild("LiuGhost") ~= nil
	end

	----------------------------------------------------------------
	-- FAST VAULT (toggle: AntiSlowVault)
	----------------------------------------------------------------
	local VAULT_ANIM_SPEED = 2.5  -- kecepatan animasi vault
	local VAULT_PUSH = 28         -- dorongan maju saat vault (stud/detik)

	local vaulting = 0
	local animConns = {}

	local function isVaultAnim(track)
		local name = track.Name
		if track.Animation then name = name .. " " .. track.Animation.Name end
		name = string.lower(name)
		for _, k in ipairs(keywords) do
			if string.find(name, k, 1, true) then return true end
		end
		return false
	end

	local function clearAnimConns()
		for _, c in ipairs(animConns) do c:Disconnect() end
		table.clear(animConns)
	end

	local function setupChar(char)
		clearAnimConns()
		vaulting = 0

		local hum = char:WaitForChild("Humanoid", 10)
		if not hum then return end
		local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5)
		if not animator then return end

		table.insert(animConns, animator.AnimationPlayed:Connect(function(track)
			if not isVaultAnim(track) then return end
			vaulting += 1
			if LiuGhost.State.AntiSlowVault == true then
				track:AdjustSpeed(VAULT_ANIM_SPEED)
			end
			track.Stopped:Once(function()
				vaulting = math.max(0, vaulting - 1)
			end)
		end))
	end

	if lp.Character then task.spawn(setupChar, lp.Character) end
	local charConn = lp.CharacterAdded:Connect(setupChar)

	----------------------------------------------------------------
	-- SPEED BOOST (toggle: SpeedBoostOn, slider: SpeedBoost)
	----------------------------------------------------------------
	local moveConn
	moveConn = RunService.Heartbeat:Connect(function(dt)
		if not guiAlive() then
			moveConn:Disconnect()
			return
		end

		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not root or hum.Health <= 0 then return end

		-- fast vault: dorong maju selama animasi vault jalan
		if vaulting > 0 and LiuGhost.State.AntiSlowVault == true then
			local look = root.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude > 0 then
				root.CFrame = root.CFrame + flat.Unit * VAULT_PUSH * dt
			end
			return
		end

		-- speed boost: tambah jarak tempuh saat bergerak
		if LiuGhost.State.SpeedBoostOn == true and hum.MoveDirection.Magnitude > 0 then
			local boost = tonumber(LiuGhost.State.SpeedBoost) or 1
			root.CFrame = root.CFrame + hum.MoveDirection * hum.WalkSpeed * PERCENT_PER_UNIT * boost * dt
		end
	end)
	----------------------------------------------------------------
	-- AUTO GEN
	----------------------------------------------------------------
	local gens, lastScan = {}, 0
	local function scanGens()
		if tick() - lastScan < 5 then return gens end
		lastScan = tick()
		gens = {}
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("Model") and string.find(v.Name:lower(), GenCfg.GenKeyword, 1, true) then
				table.insert(gens, v)
			end
		end
		return gens
	end

	local function nearestGen()
		local char = lp.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local best, dist = nil, GenCfg.Range
		for _, g in ipairs(scanGens()) do
			local ok, pos = pcall(function() return g:GetPivot().Position end)
			if ok then
				local d = (pos - root.Position).Magnitude
				if d <= dist then best, dist = g, d end
			end
		end
		return best
	end

	local function findRemotes()
		local list = {}
		for _, v in ipairs(RS:GetDescendants()) do
			if v:IsA("RemoteEvent") then
				local n = v.Name:lower()
				for _, k in ipairs(GenCfg.RemoteKeywords) do
					if string.find(n, k, 1, true) then
						table.insert(list, v)
						break
					end
				end
			end
		end
		return list
	end

	local function firePrompt(gen)
		if not fireproximityprompt then return end
		for _, p in ipairs(gen:GetDescendants()) do
			if p:IsA("ProximityPrompt") then fireproximityprompt(p) end
		end
	end

	local function skillCheckVisible()
		local pg = lp:FindFirstChild("PlayerGui")
		if not pg then return false end
		for _, g in ipairs(pg:GetDescendants()) do
			if g:IsA("GuiObject") and g.Visible and string.find(g.Name:lower(), "skillcheck", 1, true) then
				return true
			end
		end
		return false
	end

	local function pressSpace()
		VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
		VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
	end

	task.spawn(function()
		local remotes = findRemotes()
		while guiAlive() do
			if cfg.autoGen then
				local g = nearestGen()
				if g then
					firePrompt(g)
					if cfg.g
