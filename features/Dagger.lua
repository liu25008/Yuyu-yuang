return function(LiuGhost)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local lp = Players.LocalPlayer

	LiuGhost.State = LiuGhost.State or {}
	LiuGhost.Hooks = LiuGhost.Hooks or {}

	----------------------------------------------------------------
	-- CONFIG
	----------------------------------------------------------------
	local CD_TIME = 60            -- cooldown dagger (detik)
	local JUDGE_WINDOW = 0.8      -- waktu cek killer kena stun setelah parry
	local PARRY_DELAY = 0.05      -- jeda setelah animasi serang killer terdeteksi
	local FAKE_DELAY = 0.12       -- mode FakeHit: tunggu dulu, batal kalau animasi berhenti
	local DAMAGE_RANGE = 30       -- jarak killer dianggap sumber damage

	local TOOL_KEYS = { "dagger", "knife" }
	local ATTACK_KEYS = { "attack", "swing", "slash", "hit", "stab", "lunge", "swipe" }
	local STUN_KEYS = { "stun", "stagger", "parried", "dizzy" } -- sesuaikan dengan nama di game

	----------------------------------------------------------------
	-- STATE COOLDOWN
	----------------------------------------------------------------
	local cdEnd = 0        -- os.clock() saat dagger siap lagi
	local frozen = false   -- true = CD dibekukan (killer ke-stun, nunggu kena hit)
	local busy = false

	local function enabled() return LiuGhost.State.AutoDagger == true end
	local function radius() return LiuGhost.State.DaggerRadius or 15 end
	local function fakeEnabled() return LiuGhost.State.FakeHit == true end

	local function hasKey(text, keys)
		text = string.lower(text)
		for _, k in ipairs(keys) do
			if string.find(text, k, 1, true) then return true end
		end
		return false
	end

	----------------------------------------------------------------
	-- TEAM / TARGET
	----------------------------------------------------------------
	local function isKillerPlayer(p)
		if p == lp then return false end
		if lp.Team and p.Team then
			return hasKey(p.Team.Name, { "killer" })
		end
		return true -- tidak ada team: semua pemain lain dianggap target
	end

	local function amKiller()
		return lp.Team ~= nil and hasKey(lp.Team.Name, { "killer" })
	end

	local function nearestKiller(myRoot, range)
		local best, bestDist
		for _, p in ipairs(Players:GetPlayers()) do
			if isKillerPlayer(p) and p.Character then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				local root = p.Character:FindFirstChild("HumanoidRootPart")
				if hum and root and hum.Health > 0 then
					local d = (root.Position - myRoot.Position).Magnitude
					if d <= range and (not bestDist or d < bestDist) then
						best, bestDist = p.Character, d
					end
				end
			end
		end
		return best
	end

	----------------------------------------------------------------
	-- DAGGER TOOL
	----------------------------------------------------------------
	local function isDagger(t)
		return t:IsA("Tool") and hasKey(t.Name, TOOL_KEYS)
	end

	local function findDagger()
		local char = lp.Character
		if char then
			for _, t in ipairs(char:GetChildren()) do
				if isDagger(t) then return t end
			end
		end
		local bp = lp:FindFirstChildOfClass("Backpack")
		if bp then
			for _, t in ipairs(bp:GetChildren()) do
				if isDagger(t) then return t end
			end
		end
	end

	----------------------------------------------------------------
	-- DETEKSI KILLER STUN
	----------------------------------------------------------------
	local function isStunned(kChar, baseSpeed)
		for name, v in pairs(kChar:GetAttributes()) do
			if hasKey(name, STUN_KEYS) and (v == true or (type(v) == "number" and v > 0)) then
				return true
			end
		end
		for _, c in ipairs(kChar:GetChildren()) do
			if c:IsA("BoolValue") and c.Value and hasKey(c.Name, STUN_KEYS) then
				return true
			end
		end
		local hum = kChar:FindFirstChildOfClass("Humanoid")
		if hum then
			for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
				local n = track.Name
				if track.Animation then n = n .. " " .. track.Animation.Name end
				if hasKey(n, STUN_KEYS) then return true end
			end
			if hum.PlatformStand then return true end
			if baseSpeed > 4 and hum.WalkSpeed < baseSpeed * 0.3 then return true end
		end
		return false
	end

	----------------------------------------------------------------
	-- PARRY
	----------------------------------------------------------------
	local function ready()
		return not busy and not frozen and os.clock() >= cdEnd
	end

	local function tryParry(kChar)
		if not ready() then return end
		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or not root or hum.Health <= 0 then return end

		local dagger = findDagger()
		if not dagger or not dagger.Enabled then return end

		busy = true
		if dagger.Parent ~= char then
			hum:EquipTool(dagger)
			task.wait(0.1)
		end

		local kRoot = kChar:FindFirstChild("HumanoidRootPart")
		local kHum = kChar:FindFirstChildOfClass("Humanoid")
		local baseSpeed = kHum and kHum.WalkSpeed or 16
		if kRoot then
			root.CFrame = CFrame.lookAt(root.Position, Vector3.new(kRoot.Position.X, root.Position.Y, kRoot.Position.Z))
		end

		local usedAt = os.clock()
		dagger:Activate()

		local stunned = false
		while os.clock() - usedAt < JUDGE_WINDOW do
			task.wait(0.05)
			if isStunned(kChar, baseSpeed) then
				stunned = true
				break
			end
		end

		if stunned then
			frozen = true          -- CD beku sampai kena hit killer
			cdEnd = math.huge
		else
			cdEnd = usedAt + CD_TIME -- tidak stun: CD langsung jalan
		end
		busy = false
	end

	----------------------------------------------------------------
	-- CD BEKU -> JALAN SAAT KENA DAMAGE
	----------------------------------------------------------------
	local lastHealth = 100

	local function bindCharacter(char)
		local hum = char:WaitForChild("Humanoid", 10)
		if not hum then return end
		frozen, busy, cdEnd = false, false, 0
		lastHealth = hum.Health

		hum.HealthChanged:Connect(function(h)
			if frozen and h < lastHealth then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root and nearestKiller(root, DAMAGE_RANGE) then
					frozen = false
					cdEnd = os.clock() + CD_TIME
				end
			end
			lastHealth = h
		end)
	end

	lp.CharacterAdded:Connect(function(c) task.spawn(bindCharacter, c) end)
	if lp.Character then task.spawn(bindCharacter, lp.Character) end

	----------------------------------------------------------------
	-- BACA ANIMASI SERANG KILLER
	----------------------------------------------------------------
	local function isAttackAnim(track)
		local n = track.Name
		if track.Animation then n = n .. " " .. track.Animation.Name end
		return hasKey(n, ATTACK_KEYS) and not hasKey(n, STUN_KEYS)
	end

	local function watchCharacter(plr, char)
		local hum = char:WaitForChild("Humanoid", 5)
		if not hum then return end
		local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5)
		if not animator then return end
		local root = char:FindFirstChild("HumanoidRootPart")

		animator.AnimationPlayed:Connect(function(track)
			if not enabled() or amKiller() or not isKillerPlayer(plr) then return end
			if not isAttackAnim(track) then return end

			local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
			if not myRoot or not root then return end
			if (root.Position - myRoot.Position).Magnitude > radius() then return end

			task.spawn(function()
				if fakeEnabled() then
					task.wait(FAKE_DELAY)
					if not track.IsPlaying then return end -- fake/feint dibatalkan
				else
					task.wait(PARRY_DELAY)
				end
				tryParry(char)
			end)
		end)
	end

	local function hookPlayer(plr)
		if plr == lp then return end
		plr.CharacterAdded:Connect(function(c) task.spawn(watchCharacter, plr, c) end)
		if plr.Character then task.spawn(watchCharacter, plr, plr.Character) end
	end

	for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
	Players.PlayerAdded:Connect(hookPlayer)

	----------------------------------------------------------------
	-- RING RADIUS + PRE-EQUIP
	----------------------------------------------------------------
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

	RunService.Heartbeat:Connect(function()
		local char = lp.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local myRoot = char and char:FindFirstChild("HumanoidRootPart")

		if enabled() and myRoot then
			local r = radius()
			ring.Transparency = 0.85
			ring.Size = Vector3.new(0.15, r * 2, r * 2)
			ring.CFrame = CFrame.new(myRoot.Position - Vector3.new(0, 2.9, 0)) * CFrame.Angles(0, 0, math.rad(90))
		else
			ring.Transparency = 1
		end

		if not enabled() or amKiller() or not hum or not myRoot or hum.Health <= 0 then return end
		if not ready() then return end

		-- siapkan dagger sebelum killer menyerang
		if nearestKiller(myRoot, radius() + 8) then
			local dagger = findDagger()
			if dagger and dagger.Parent ~= char then
				hum:EquipTool(dagger)
			end
		end
	end)

	----------------------------------------------------------------
	-- HOOKS DARI GUI
	----------------------------------------------------------------
	LiuGhost.Hooks.AutoDagger = function(state)
		if not state then ring.Transparency = 1 end
	end

	LiuGhost.Hooks.DaggerRadius = function(value) end

	LiuGhost.Hooks.FakeHit = function(state) end

	-- status untuk label GUI: "READY", "FROZEN", atau sisa detik
	LiuGhost.Dagger = {
		GetStatus = function()
			if frozen then return "FROZEN" end
			local left = cdEnd - os.clock()
			if left <= 0 then return "READY" end
			return string.format("%ds", math.ceil(left))
		end,
	}
end
