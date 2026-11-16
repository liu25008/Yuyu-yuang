return function(LiuGhost)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local lp = Players.LocalPlayer

	----------------------------------------------------------------
	-- KONFIG
	----------------------------------------------------------------
	local keywords = { "vault", "window", "pallet", "mantle", "climb" }
	local PERCENT_PER_UNIT = 0.15 -- boost 0.1 = 1.5%, boost 2.0 = 30%

	local cfg = {
		antiSlow = false,
		boost = tonumber(LiuGhost.State.SpeedBoost) or 1,
	}

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
	-- SPEED BOOST (hanya saat lari / LeftShift)
	----------------------------------------------------------------
	local function isSprinting()
		return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	end

	local function boostEnabled()
		-- kalau nanti GUI punya toggle "SpeedBoostOn", dipakai. Kalau tidak ada, selalu aktif.
		local t = LiuGhost.State.SpeedBoostOn
		return t == nil or t == true
	end

	local function guiAlive()
		local pg = lp:FindFirstChild("PlayerGui")
		return pg ~= nil and pg:FindFirstChild("LiuGhost") ~= nil
	end

	local hbConn
	hbConn = RunService.Heartbeat:Connect(function(dt)
		-- GUI ditutup: matikan semuanya
		if not guiAlive() then
			hbConn:Disconnect()
			charConn:Disconnect()
			clearAnimConns()
			return
		end

		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not root or hum.Health <= 0 then return end

		-- Anti slow vault
		if activeTracks == 0 then
			baseSpeed = hum.WalkSpeed
		elseif cfg.antiSlow and savedSpeed and hum.WalkSpeed < savedSpeed then
			hum.WalkSpeed = savedSpeed
		end

		-- Speed boost
		if boostEnabled() and isSprinting() then
			local dir = hum.MoveDirection
			if dir.Magnitude > 0 then
				local extra = hum.WalkSpeed * (cfg.boost * PERCENT_PER_UNIT)
				root.CFrame = root.CFrame + dir.Unit * (extra * dt)
			end
		end
	end)

	----------------------------------------------------------------
	-- HOOKS DARI GUI
	----------------------------------------------------------------
	LiuGhost.Hooks.AntiSlowVault = function(state)
		cfg.antiSlow = state == true
	end

	LiuGhost.Hooks.SpeedBoost = function(value)
		if type(value) == "number" then
			cfg.boost = math.clamp(value, 0.1, 2)
		end
	end
end
