local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local CharacterController = { CurrentCharacter = nil }

CharacterController.Dependencies = { "Event", "Player" }

CharacterController.Events = {}
CharacterController.Listeners = {
	["Character.ChangeController"] = function(self, data)
		self:ChangeController(data.controller or "")
	end,
	["Character.ChangeState"] = function(self, data)
		if not self.CurrentCharacter then
			return
		end

		self.CurrentCharacter:ChangeState(data.state, data.args or {})
	end,
}

CharacterController.Modules = { "Character" }
CharacterController.Controllers = { "Player" }

local Controllers
local Modules

function CharacterController:Init(controllers, modules)
	Controllers = controllers
	Modules = modules

	return true
end

function CharacterController:Start()
	self:_DestroyDefaultSounds()

	coroutine.wrap(function()
		while not game:IsLoaded() do
			task.wait(0.25)
		end
		Controllers.Event:FireServer("Character.IsLoaded")
	end)()

	return true
end

function CharacterController:ChangeController(type: string, newPosition: Vector3?, ignoreOldPos: boolean?)
	local charType = Modules.Character.Get(type)
	if not charType then
		warn("[CharacterController] Character type '" .. type .. "' not found!")
	end

	Promise.new(function(resolve)
		if self.CurrentCharacter then
			local oldPosition = self.CurrentCharacter.Model and self.CurrentCharacter.Model:GetPivot().Position or nil

			if self.CurrentCharacter._initialized then
				self.CurrentCharacter:Destroy(function()
					-- character may already be nil after Cleanup (UnloadCharacter)
					local char = Players.LocalPlayer.Character
					while char ~= nil and char.Parent == game.Workspace do
						task.wait(0)
						char = Players.LocalPlayer.Character
					end
					resolve(oldPosition)
				end)
			else
				-- just cleanup
				self.CurrentCharacter:Cleanup()
				self.CurrentCharacter = nil
				resolve(oldPosition)
			end
		else
			resolve(newPosition or nil)
		end
	end):andThen(function(oldPosition)
		self.CurrentCharacter = charType.new({
			InitialPosition = not ignoreOldPos and (newPosition and newPosition or oldPosition) or nil,
			Type = type,
			Controller = self,
		})
	end)
end

function CharacterController:_DestroyDefaultSounds()
	coroutine.wrap(function()
		local function deletarMalignos(player: Player)
			if player == Players.LocalPlayer then
				return
			end

			local character = player.Character
			if not character then
				return
			end

			local hrp = character:WaitForChild("HumanoidRootPart")
			local colapso = {
				"Climbing",
				"Died",
				"FreeFalling",
				"GettingUp",
				"Jumping",
				"Landing",
				"Running",
				"Splash",
				"Swimming",
			}
			for _, sound in hrp:GetChildren() do
				if not sound:IsA("Sound") then
					continue
				end

				if not table.find(colapso, sound.Name) then
					continue
				end

				sound:Destroy()
			end
		end

		for _, player in Players:GetPlayers() do
			deletarMalignos(player)
		end

		Players.PlayerAdded:Connect(function(player)
			deletarMalignos(player)
		end)
	end)()
end

return CharacterController
