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
		antiSlow = false,
		boost = tonumber(LiuGhost.State.SpeedBoost) or 1,
		autoGen = false,
		genMode = LiuGhost.State.AutoGenMode or "Perfect",
	}

	local function guiAlive()
		local pg = lp:FindFirstChild("PlayerGui")
		return pg ~= nil and pg:FindFirstChild("LiuGhost") ~= nil
	end

	----------------------------------------------------------------
	-- ANTI SLOW VAULT
	----------------------------------------------------------------
	local baseSpeed = 16
	local savedSpeed = nil
	local activeTracks = 0
	local animConns = {}

	local function isVaultAnim(track)
		local name = ""
		if track.Animation then name = track.Animation.Name end
		name = string.lower(name .. " " .. track.Name)
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
		activeTracks = 0
		savedSpeed = nil

		local hum = char:WaitForChild("Humanoid", 10)
		if not hum then return end
		local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5)
		baseSpeed = hum.WalkSpeed

		if animator then
			table.insert(animConns, animator.AnimationPlayed:Connect(function(track)
				if not isVaultAnim(track) then return end
				if activeTracks == 0 then savedSpeed = baseSpeed end
				activeTracks += 1
				track.Stopped:Once(function()
					activeTracks = math.max(0, activeTracks - 1)
					if activeTracks == 0 then savedSpeed = nil end
				end)
			end))
		end
	end

	if lp.Character then task.spawn(setupChar, lp.Character) end
	local charConn = lp.CharacterAdded:Connect(setupChar)

	----------------------------------------------------------------
	-- SPEED BOOST
	----------------------------------------------------------------
	local function isSprinting()
		return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	end

	local function boostEnabled()
		local t = LiuGhost.State.SpeedBoostOn
		return t == nil or t == true
	end

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
