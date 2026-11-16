return function(LiuGhost)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local lp = Players.LocalPlayer
	local cooldown = 0.35
	local lastHit = 0

	local function enabled()
		return LiuGhost.State.AutoDagger == true
	end

	local function radius()
		return LiuGhost.State.DaggerRadius or 15
	end

	-- Cari dagger (di tangan atau di backpack)
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

	-- Target terdekat dalam radius
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

	-- Lingkaran radius (visual lokal)
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
		updateR
