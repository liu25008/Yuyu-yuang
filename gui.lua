-- LocalScript
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local Theme = {
	Bg = Color3.fromRGB(12, 8, 20),
	Panel = Color3.fromRGB(18, 13, 30),
	Row = Color3.fromRGB(24, 18, 40),
	RowHover = Color3.fromRGB(32, 24, 54),
	Accent = Color3.fromRGB(96, 58, 156),
	AccentSoft = Color3.fromRGB(150, 110, 210),
	Text = Color3.fromRGB(220, 210, 240),
	Muted = Color3.fromRGB(125, 112, 150),
}

local LiuGhost = { Hooks = {}, State = {} }

-- 1 fitur = 1 halaman. Isi "icon" dengan asset id (rbxassetid://...) kalau mau pakai gambar.
local Pages = {
	{ name = "Dagger", icon = "", items = {
		{ type = "toggle", id = "AutoDagger", text = "Auto Dagger", icon = "" },
		{ type = "toggle", id = "FakeHit", text = "Fake Hit", icon = "" },
		{ type = "slider", id = "DaggerRadius", text = "Radius Auto Dagger", min = 5, max = 50, default = 15, icon = "" },
	}},
	{ name = "ESP", icon = "", items = {
		{ type = "toggle", id = "EspKiller", text = "ESP Killer", icon = "" },
		{ type = "toggle", id = "EspSurvivor", text = "ESP Survivor", icon = "" },
		{ type = "toggle", id = "EspDistance", text = "Jarak Killer dan Survivor", icon = "" },
		{ type = "toggle", id = "EspTrap", text = "ESP Trap", icon = "" },
		{ type = "toggle", id = "EspPallet", text = "ESP Pallet", icon = "" },
		{ type = "toggle", id = "EspWindow", text = "ESP Window", icon = "" },
		{ type = "toggle", id = "EspZombie", text = "ESP Zombie", icon = "" },
	}},
	{ name = "Aimbot", icon = "", items = {
		{ type = "toggle", id = "Aimbot", text = "Aimbot", icon = "" },
	}},
	{ name = "Moonwalk", icon = "", items = {
		{ type = "toggle", id = "Moonwalk", text = "Moonwalk", icon = "" },
	}},
	{ name = "Crouch", icon = "", items = {
		{ type = "toggle", id = "AutoCrouch", text = "Auto Jongkok Killer Abyss", icon = "" },
	}},
}

local function fire(id, value)
	LiuGhost.State[id] = value
	local hook = LiuGhost.Hooks[id]
	if hook then
		task.spawn(hook, value)
	end
end

local function tween(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function round(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = obj
end

local function label(parent, text, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size or 14
	l.TextColor3 = color or Theme.Text
	l.Font = font or Enum.Font.GothamMedium
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

-- Slot icon: pakai gambar kalau ada, kalau kosong tampil bentuk geometris kecil
local function iconSlot(parent, icon, pos, color)
	if icon and icon ~= "" then
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromOffset(18, 18)
		img.Position = pos
		img.Image = icon
		img.ImageColor3 = color
		img.Parent = parent
		return img
	end
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(12, 12)
	f.Position = pos + UDim2.fromOffset(3, 3)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Rotation = 45
	f.Parent = parent
	round(f, 3)
	return f
end

-- Root
local gui = Instance.new("ScreenGui")
gui.Name = "LiuGhost"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(520, 330)
main.Position = UDim2.new(0.5, -260, 0.5, -165)
main.BackgroundColor3 = Theme.Bg
main.BorderSizePixel = 0
main.Parent = gui
round(main, 14)

local stroke = Instance.new("UIStroke")
stroke.Color = Theme.Accent
stroke.Transparency = 0.35
stroke.Thickness = 1.5
stroke.Parent = main

-- Header
local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 46)
top.BackgroundTransparency = 1
top.Parent = main

local title = label(top, "LIUGHOST", 20, Theme.AccentSoft, Enum.Font.GothamBold)
title.Size = UDim2.fromOffset(110, 46)
title.Position = UDim2.fromOffset(18, 0)

local divider = Instance.new("Frame")
divider.Size = UDim2.fromOffset(1, 18)
divider.Position = UDim2.fromOffset(134, 14)
divider.BackgroundColor3 = Theme.Muted
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel = 0
divider.Parent = top

local sub = label(top, "Violence District", 13, Theme.Muted)
sub.Size = UDim2.fromOffset(160, 46)
sub.Position = UDim2.fromOffset(146, 0)

local function headerBtn(text, x)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(26, 26)
	b.Position = UDim2.new(1, x, 0, 10)
	b.BackgroundTransparency = 1
	b.Text = text
	b.TextColor3 = Theme.Muted
	b.TextSize = 18
	b.Font = Enum.Font.GothamBold
	b.AutoButtonColor = false
	b.Parent = top
	b.MouseEnter:Connect(function() tween(b, { TextColor3 = Theme.Text }) end)
	b.MouseLeave:Connect(function() tween(b, { TextColor3 = Theme.Muted }) end)
	return b
end
local minBtn = headerBtn("-", -64)
local closeBtn = headerBtn("x", -34)

-- Drag lewat header
do
	local dragging, dragStart, startPos
	top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

-- Sidebar
local side = Instance.new("Frame")
side.Size = UDim2.new(0, 150, 1, -58)
side.Position = UDim2.fromOffset(10, 48)
side.BackgroundColor3 = Theme.Panel
side.BorderSizePixel = 0
side.Parent = main
round(side, 10)

local sideList = Instance.new("UIListLayout")
sideList.Padding = UDim.new(0, 4)
sideList.Parent = side
local sidePad = Instance.new("UIPadding")
sidePad.PaddingTop = UDim.new(0, 8)
sidePad.PaddingLeft = UDim.new(0, 8)
sidePad.PaddingRight = UDim.new(0, 8)
sidePad.Parent = side

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -182, 1, -58)
content.Position = UDim2.fromOffset(170, 48)
content.BackgroundTransparency = 1
content.Parent = main

local tabs = {}

local function selectPage(name)
	for n, t in pairs(tabs) do
		local active = n == name
		t.page.Visible = active
		tween(t.btn, { BackgroundTransparency = active and 0 or 1 })
		tween(t.text, { TextColor3 = active and Color3.new(1, 1, 1) or Theme.Muted })
	end
end

local function makeToggle(parent, item)
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -6, 0, 44)
	row.BackgroundColor3 = Theme.Row
	row.Text = ""
	row.AutoButtonColor = false
	row.Parent = parent
	round(row, 10)

	iconSlot(row, item.icon, UDim2.fromOffset(14, 13), Theme.AccentSoft)

	local l = label(row, item.text, 14)
	l.Size = UDim2.new(1, -110, 1, 0)
	l.Position = UDim2.fromOffset(44, 0)

	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromOffset(42, 22)
	pill.Position = UDim2.new(1, -54, 0.5, -11)
	pill.BackgroundColor3 = Theme.Bg
	pill.BorderSizePixel = 0
	pill.Parent = row
	round(pill, 11)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16, 16)
	knob.Position = UDim2.fromOffset(3, 3)
	knob.BackgroundColor3 = Theme.Muted
	knob.BorderSizePixel = 0
	knob.Parent = pill
	round(knob, 8)

	local on = false
	LiuGhost.State[item.id] = false

	row.MouseEnter:Connect(function() tween(row, { BackgroundColor3 = Theme.RowHover }) end)
	row.MouseLeave:Connect(function() tween(row, { BackgroundColor3 = Theme.Row }) end)
	row.MouseButton1Click:Connect(function()
		on = not on
		tween(pill, { BackgroundColor3 = on and Theme.Accent or Theme.Bg })
		tween(knob, {
			Position = on and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
			BackgroundColor3 = on and Color3.new(1, 1, 1) or Theme.Muted,
		})
		fire(item.id, on)
	end)
end

local function makeSlider(parent, item)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 58)
	row.BackgroundColor3 = Theme.Row
	row.BorderSizePixel = 0
	row.Parent = parent
	round(row, 10)

	iconSlot(row, item.icon, UDim2.fromOffset(14, 8), Theme.AccentSoft)

	local l = label(row, item.text, 14)
	l.Size = UDim2.new(1, -110, 0, 26)
	l.Position = UDim2.fromOffset(44, 4)

	local val = label(row, tostring(item.default), 14, Theme.Muted)
	val.Size = UDim2.fromOffset(50, 26)
	val.Position = UDim2.new(1, -62, 0, 4)
	val.TextXAlignment = Enum.TextXAlignment.Right

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -28, 0, 6)
	track.Position = UDim2.fromOffset(14, 40)
	track.BackgroundColor3 = Theme.Bg
	track.BorderSizePixel = 0
	track.Parent = row
	round(track, 3)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Theme.Accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	round(fill, 3)

	local function setValue(v)
		v = math.clamp(math.floor(v + 0.5), item.min, item.max)
		fill.Size = UDim2.new((v - item.min) / (item.max - item.min), 0, 1, 0)
		val.Text = tostring(v)
		fire(item.id, v)
	end
	setValue(item.default)

	local sliding = false
	local function update(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		setValue(item.min + a * (item.max - item.min))
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			update(input.Position.X)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input.Position.X)
		end
	end)
end

for _, p in ipairs(Pages) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 38)
	btn.BackgroundColor3 = Theme.Accent
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = side
	round(btn, 8)

	iconSlot(btn, p.icon, UDim2.fromOffset(12, 10), Theme.AccentSoft)

	local txt = label(btn, p.name, 14, Theme.Muted)
	txt.Size = UDim2.new(1, -44, 1, 0)
	txt.Position = UDim2.fromOffset(40, 0)

	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Theme.Accent
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.CanvasSize = UDim2.new()
	page.Visible = false
	page.Parent = content

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.Parent = page

	for _, item in ipairs(p.items) do
		if item.type == "toggle" then
			makeToggle(page, item)
		elseif item.type == "slider" then
			makeSlider(page, item)
		end
	end

	tabs[p.name] = { btn = btn, text = txt, page = page }
	btn.MouseButton1Click:Connect(function() selectPage(p.name) end)
end

selectPage(Pages[1].name)

-- Minimize (RightShift buka lagi) dan close
local hidden = false
local function toggleGui()
	hidden = not hidden
	main.Visible = not hidden
end
minBtn.MouseButton1Click:Connect(toggleGui)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
UIS.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
		toggleGui()
	end
end)

-- Pasang kode lo di sini:
-- LiuGhost.Hooks.AutoDagger = function(state) end
-- LiuGhost.Hooks.DaggerRadius = function(value) end

return LiuGhost
