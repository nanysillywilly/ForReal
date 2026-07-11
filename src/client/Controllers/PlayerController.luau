local PlayerController = { CharacterController = nil }
local StarterGui = game:GetService("StarterGui")
local ExpressivePrompts = require("../../Packages/ExpressivePrompts")

PlayerController.Dependencies = { "Event" }

local DISABLE_CORE_GUIS = {
	Backpack = true,
	Chat = false,
	EmotesMenu = true,
	Health = true,
	PlayerList = false,
	TopBar = true,
}

local DISABLE_RESET = true
local RESET_MAX_ATTEMPTS = 20
local RESET_RETRY_DELAY = 0.5

PlayerController.Events = {
	Join = true,
	Left = true,
}

PlayerController.Listeners = {
	["Player.Join"] = function(_self, _data) end,
	["Player.Left"] = function(_self, _data) end,
}

function PlayerController:Init(_controllers, _modules)
	return true
end

function PlayerController:Start()
	self:DisableDefault()
	ExpressivePrompts.Init()
	return true
end

function PlayerController:DisableDefault()
	self:DisableCoreGuis()
	self:DisableReset()
end

function PlayerController:DisableCoreGuis()
	for guiType, disabled in pairs(DISABLE_CORE_GUIS) do
		if disabled then
			pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[guiType], false)
			end)
		end
	end
end

function PlayerController:DisableReset()
	if not DISABLE_RESET then
		return
	end
	local function AttemptDisable()
		return pcall(function()
			StarterGui:SetCore("ResetButtonCallback", false)
		end)
	end
	task.spawn(function()
		local attempts = 0
		while attempts < RESET_MAX_ATTEMPTS do
			if AttemptDisable() then
				break
			end
			attempts += 1
			task.wait(RESET_RETRY_DELAY)
		end
	end)
end

return PlayerController
