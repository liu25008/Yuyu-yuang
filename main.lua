local BASE = "https://raw.githubusercontent.com/liu25008/Yuyu-yuang/main/"

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- hapus GUI lama biar gak dobel saat execute ulang
for _, n in ipairs({ "LiuGhost", "LiuGhostMW", "LiuGhostAimRing", "MoonwalkButton" }) do
	local old = pg:FindFirstChild(n)
	if old then old:Destroy() end
end
task.wait(0.5) -- kasih waktu loop fitur lama berhenti

local function fetch(path)
	local ok, src = pcall(function()
		return game:HttpGet(BASE .. path .. "?t=" .. os.time())
	end)
	if not ok or type(src) ~= "string" or src == "" then
		warn("[LiuGhost] gagal download " .. path .. ": " .. tostring(src))
		return nil
	end
	return src
end

local src = fetch("gui.lua")
if not src then return end

local fn, err = loadstring(src)
if not fn then
	warn("[LiuGhost] error compile gui.lua: " .. tostring(err))
	return
end

local ok, result = pcall(fn)
if not ok then
	warn("[LiuGhost] error jalanin gui.lua: " .. tostring(result))
end
