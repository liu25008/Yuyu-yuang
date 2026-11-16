local base = "https://raw.githubusercontent.com/liu25008/Yuyu-yuang/main/"

local function fetch(path)
	return loadstring(game:HttpGet(base .. path))()
end

local LiuGhost = fetch("gui.lua")

local features = { "Dagger", "ESP", "Aimbot", "Moonwalk", "Crouch" }

for _, name in ipairs(features) do
	local ok, mod = pcall(fetch, "features/" .. name .. ".lua")
	if ok and type(mod) == "function" then
		mod(LiuGhost)
	else
		warn("Gagal load " .. name .. ": " .. tostring(mod))
	end
end
