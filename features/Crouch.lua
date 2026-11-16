return function(LiuGhost)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local VIM = game:GetService("VirtualInputManager")

	local lp = Players.LocalPlayer

	----------------------------------------------------------------
	-- KONFIG
	----------------------------------------------------------------
	local cfg = {
		enabled = LiuGhost.State.AutoCrouch == true,
		minDist = 10,
		maxDist = 40,
		crouchKey = Enum.KeyCode.C, -- ganti sesuai tombol jongkok di game
		holdTime = 1.2,
	}
	local killerName = "abyss"
	local skillWords = { "slash", "skill", "ability", "swing", "sweep", "cleave", "attack" }

	local conns = {}
	local releaseAt = 0
	local crouching = false
	local alive = true

	----------------------------------------------------------------
	-- DETEKSI KILLER ABYSS + SKILL
	----------------------------------------------------------------
	local function matchAbyss(plr, char)
		local combined = string.lower(plr.Name .. " " .. plr.DisplayName .. " " .. char.Name)
		if string.find(combined, killerName, 1, true) then return true end
		for _, v in pairs(char:GetAttributes()) do
			if type(v) == "string" and string.find(string.lower(v), killerName, 1, true) then
				return true
			end
		end
		return plr.Team ~= nil and string.find(string.lower(plr.Team.Name), killerName, 1, true) ~= nil
	end

	local function isSkill(track)
		local n = string.lower(track.Name .. " " .. (track.Animation and track.Animation.Name or ""))
		for _, w in ipairs(skillWords) do
			if string.find(n, w, 1, true) then return true end
		end
		return false
	end

	----------------------------------------------------------------
	-- JONGKOK
	----------------------------------------------------------------
	local function press(down)
		pcall(function()
			VIM:SendKeyEvent(down, cfg.crouchKey, false, game)
		end)
	end

	local function triggerCrouch()
		releaseAt = os.clock() + cfg.holdTime
		if crouching then return end
		crouching = true
		press(true)
		task.spawn(function()
			while alive and os.clock() < releaseAt do task.wait(0.05) end
			press(false)
			crouching = false
		end)
	end

	----------------------------------------------------------------
	-- WATCH SETIAP PEMAIN
	----------------------------------------------------------------
	local function watch(plr, char)
		local hum = char:WaitForChild("Humanoid", 5)
		if not hum then return end
		local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5)
		if not animator then return end
		local root = char:WaitForChild("HumanoidRootPart", 5)
		if not root then return end

		table.insert(conns, animator.AnimationPlayed:Connect(function(track)
			if not alive or not cfg.enabled then return end
			if not isSkill(track) or not matchAbyss(plr, char) then return end

			local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
			if not myRoot then return end

			local d = (root.Position - myRoot.Position).Magnitude
			if d >= cfg.minDist and d <= cfg.maxDist then
				triggerCrouch()
			end
		end))
	end

	local function hookPlayer(plr)
		if plr == lp then return end
		table.insert(conns, plr.CharacterAdded:Connect(function(c)
			task.spawn(watch, plr, c)
		end))
		if plr.Character then task.spawn(watch, plr, plr.Character) end
	end

	for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
	table.insert(conns, Players.PlayerAdded:Connect(hookPlayer))

	----------------------------------------------------------------
	-- BERSIH SAAT GUI DITUTUP
	----------------------------------------------------------------
	local function guiAlive()
		local pg = lp:FindFirstChild("PlayerGui")
		return pg ~= nil and pg:FindFirstChild("LiuGhost") ~= nil
	end

	local watchdog
	watchdog = RunService.Heartbeat:Connect(function()
		if guiAlive() then return end
		alive = false
		cfg.enabled = false
		watchdog:Disconnect()
		for _, c in ipairs(conns) do c:Disconnect() end
		table.clear(conns)
		if crouching then
			press(false)
			crouching = false
		end
	end)

	----------------------------------------------------------------
	-- HOOK DARI GUI
	----------------------------------------------------------------
	LiuGhost.Hooks.AutoCrouch = function(state)
		cfg.enabled = state == true
		if not cfg.enabled and crouching then
			releaseAt = 0
		end
	end
end
