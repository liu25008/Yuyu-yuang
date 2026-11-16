return function(LiuGhost)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local lp = Players.LocalPlayer

	local RED = Color3.fromRGB(255, 60, 60)
	local BLUE = Color3.fromRGB(70, 130, 255)
	local ORANGE = Color3.fromRGB(255, 140, 0)
	local GREEN = Color3.fromRGB(110, 170, 110)
	local PINK = Color3.fromRGB(255, 105, 180)
	local TEXT = Color3.fromRGB(235, 235, 235)

	local function on(id)
		return LiuGhost.State[id] == true
	end

	----------------------------------------------------------------
	-- ESP PEMAIN (Killer / Survivor) - jarak hanya di sini
	----------------------------------------------------------------
	local KEYWORD = "killer"
	local espPlayers = {}

	local function hasKeyword(v)
		return typeof(v) == "string" and string.find(string.lower(v), KEYWORD, 1, true) ~= nil
	end

	local function isKiller(plr)
		if plr.Team and hasKeyword(plr.Team.Name) then return true end
		for _, a in ipairs({ "Role", "Team", "Type" }) do
			if hasKeyword(plr:GetAttribute(a)) then return true end
			if plr.Character and hasKeyword(plr.Character:GetAttribute(a)) then return true end
		end
		return false
	end

	local function removePlayerEsp(plr)
		local d = espPlayers[plr]
		if d then
			if d.hl then d.hl:Destroy() end
			if d.bb then d.bb:Destroy() end
			espPlayers[plr] = nil
		end
	end

	local function applyPlayerEsp(plr, role, char, head)
		local color = role == "killer" and RED or BLUE

		local hl = Instance.new("Highlight")
		hl.FillColor = color
		hl.FillTransparency = role == "killer" and 0.7 or 0.75
		hl.OutlineColor = color
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = char

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(140, 30)
		bb.StudsOffset = Vector3.new(0, 2.5, 0)
		bb.AlwaysOnTop = true
		bb.Adornee = head
		bb.Parent = head

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = role == "killer" and RED or TEXT
		label.TextStrokeTransparency = 0.4
		label.Font = role == "killer" and Enum.Font.GothamBold or Enum.Font.GothamMedium
		label.TextSize = role == "killer" and 14 or 13
		label.Text = ""
		label.Parent = bb

		espPlayers[plr] = { role = role, char = char, hl = hl, bb = bb, label = label }
	end

	local function refreshPlayers()
		local myChar = lp.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= lp then
				local char = plr.Character
				local head = char and char:FindFirstChild("Head")
				local root = char and char:FindFirstChild("HumanoidRootPart")

				local role
				if head and root then
					if isKiller(plr) then
						if on("EspKiller") then role = "killer" end
					elseif on("EspSurvivor") then
						role = "survivor"
					end
				end

				local d = espPlayers[plr]
				if d and (d.role ~= role or d.char ~= char) then
					removePlayerEsp(plr)
					d = nil
				end
				if role and not d then
					applyPlayerEsp(plr, role, char, head)
					d = espPlayers[plr]
				end
				if d then
					local text = role == "killer" and "KILLER" or plr.DisplayName
					if on("EspDistance") and myRoot then
						local m = math.floor((root.Position - myRoot.Position).Magnitude)
						text = text .. "  [" .. m .. "m]"
					end
					d.label.Text = text
				end
			end
		end
	end

	Players.PlayerRemoving:Connect(removePlayerEsp)

	----------------------------------------------------------------
	-- PROGRESS GENERATOR
	----------------------------------------------------------------
	local PROGRESS_KEYS = { "progress", "percent", "repair", "complet" }

	local function nameMatch(n)
		n = string.lower(n)
		for _, k in ipairs(PROGRESS_KEYS) do
			if string.find(n, k, 1, true) then return true end
		end
		return false
	end

	-- cari sumber angka progress: Attribute atau NumberValue/IntValue
	local function findSource(inst)
		local function scanAttr(o)
			for name, val in pairs(o:GetAttributes()) do
				if type(val) == "number" and nameMatch(name) then
					return function() return o:GetAttribute(name) end
				end
			end
		end

		local f = scanAttr(inst)
		if f then return f end

		for _, d in ipairs(inst:GetDescendants()) do
			if (d:IsA("NumberValue") or d:IsA("IntValue")) and nameMatch(d.Name) then
				return function() return d.Value end
			end
			local g = scanAttr(d)
			if g then return g end
		end
		return nil
	end

	local function toPercent(v)
		if type(v) ~= "number" then return nil end
		if v <= 1 and v ~= math.floor(v) then v = v * 100 end -- format 0..1
		return math.clamp(math.floor(v + 0.5), 0, 100)
	end

	----------------------------------------------------------------
	-- ESP OBJEK (Pallet / Window / Trap / Zombie / Generator)
	----------------------------------------------------------------
	local kinds = {
		pallet    = { kw = "pallet",    label = "Pallet",    color = ORANGE, thick = 0.04, on = false, items = {} },
		window    = { kw = "window",    label = "Window",    color = ORANGE, thick = 0.04, on = false, items = {} },
		trap      = { kw = "trap",      label = "TRAP",      color = BLUE,   thick = 0.09, on = false, items = {} },
		zombie    = { kw = "zombie",    label = "Zombie",    color = GREEN,  thick = 0.05, on = false, items = {} },
		generator = { kw = "generator", label = "Generator", color = PINK,   thick = 0.05, on = false, items = {}, progress = true },
	}
	local tracked = {}

	local function classify(inst)
		if not (inst:IsA("Model") or inst:IsA("BasePart")) then return nil end
		local n = string.lower(inst.Name)
		for key, d in pairs(kinds) do
			if d.on and string.find(n, d.kw, 1, true) then return key end
		end
	end

	local function hasTrackedAncestor(inst)
		local p = inst.Parent
		while p and p ~= workspace do
			if tracked[p] then return true end
			p = p.Parent
		end
		return false
	end

	local function anchorPart(inst)
		if inst:IsA("BasePart") then return inst end
		if inst:IsA("Model") then
			return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
		end
	end

	local function removeItem(key, inst)
		local item = kinds[key].items[inst]
		if item then
			item.box:Destroy()
			item.bb:Destroy()
			item.conn:Disconnect()
			kinds[key].items[inst] = nil
		end
		tracked[inst] = nil
	end

	local function addItem(inst)
		if tracked[inst] or not inst.Parent then return end
		local key = classify(inst)
		if not key or hasTrackedAncestor(inst) then return end
		if inst:IsA("Model") and Players:GetPlayerFromCharacter(inst) then return end
		local part = anchorPart(inst)
		if not part then return end
		local d = kinds[key]

		local box = Instance.new("SelectionBox")
		box.Adornee = inst
		box.Color3 = d.color
		box.SurfaceColor3 = d.color
		box.SurfaceTransparency = 0.88
		box.LineThickness = d.thick
		box.Parent = inst

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(130, 20)
		bb.StudsOffset = Vector3.new(0, 2, 0)
		bb.AlwaysOnTop = true
		bb.Adornee = part
		bb.Parent = part

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = d.color
		label.TextStrokeTransparency = 0.4
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.Text = d.label
		label.Parent = bb

		local conn = inst.AncestryChanged:Connect(function()
			if not inst:IsDescendantOf(workspace) then removeItem(key, inst) end
		end)

		tracked[inst] = key
		d.items[inst] = {
			box = box, bb = bb, label = label, part = part, conn = conn,
			inst = inst, src = nil,
		}
	end

	local function setKind(key, state)
		local d = kinds[key]
		d.on = state
		if state then
			for _, inst in ipairs(workspace:GetDescendants()) do addItem(inst) end
		else
			for inst in pairs(d.items) do removeItem(key, inst) end
		end
	end

	workspace.DescendantAdded:Connect(function(inst)
		task.defer(addItem, inst)
	end)

	----------------------------------------------------------------
	-- LOOP UPDATE (tiap 0.2 detik)
	----------------------------------------------------------------
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.2 then return end
		acc = 0

		refreshPlayers()

		-- label objek: tanpa jarak, generator + persen progress
		for _, d in pairs(kinds) do
			for _, item in pairs(d.items) do
				if item.part.Parent then
					local text = d.label
					if d.progress then
						if not item.src then
							item.src = findSource(item.inst)
						end
						if item.src then
							local ok, v = pcall(item.src)
							local pct = ok and toPercent(v) or nil
							if pct then
								text = text .. "  [" .. pct .. "%]"
							end
						end
					end
					item.label.Text = text
				end
			end
		end
	end)

	----------------------------------------------------------------
	-- HOOKS DARI GUI
	----------------------------------------------------------------
	LiuGhost.Hooks.EspKiller = function() refreshPlayers() end
	LiuGhost.Hooks.EspSurvivor = function() refreshPlayers() end
	LiuGhost.Hooks.EspDistance = function() refreshPlayers() end

	local objectHooks = {
		EspTrap = "trap",
		EspPallet = "pallet",
		EspWindow = "window",
		EspZombie = "zombie",
		EspGenerator = "generator",
	}
	for id, key in pairs(objectHooks) do
		LiuGhost.Hooks[id] = function(state)
			setKind(key, state)
		end
	end
end
