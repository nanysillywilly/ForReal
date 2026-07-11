local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorkspaceUtils = require(ReplicatedStorage.Modules.Utils.WorkspaceUtils)
local CharacterService = {}

CharacterService.Dependencies = { "Event" }
CharacterService.Events = {
	IsLoaded = {
		server = true,
		client = false,
	},
	ChangeController = {
		server = false,
		client = true,
		schema = {
			controller = "string",
		},
	},
	ChangeState = {
		server = false,
		client = true,
		schema = {
			state = "string",
		},
	},
}
CharacterService.Listeners = {
	["Character.IsLoaded"] = function(self, player)
		player:SetAttribute("_Loaded", true)
	end,
}

local Services
local _Modules

function CharacterService:Init(services, modules)
	Services = services
	_Modules = modules
	self:_SetupCharacterInitialization()
	return true
end

function CharacterService:Start()
	return true
end

function CharacterService:_SetupCharacterInitialization()
	Players.PlayerAdded:Connect(function(player)
		while not player:GetAttribute("_Loaded") do
			task.wait(0.5)
		end

		player.CharacterAdded:Connect(function(char: Model)
			char.Parent = WorkspaceUtils:FindOrCreateFolder("PLAYERS")
		end)

		Services.Event:FireClient(player, "Character.ChangeController", { controller = "" })
	end)
end

return CharacterService
