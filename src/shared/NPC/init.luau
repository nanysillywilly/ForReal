local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local NPC = {}
NPC.__index = NPC

NPC.CURRENT_STATE = nil

function NPC.new(npcSpawn: Vector3, service: {})
	local self = setmetatable({}, NPC)

	RunService.Stepped:Connect(function(time: number, deltaTime: number)
		if not self.CURRENT_STATE then
			return
		end

		if not self.CURRENT_STATE.Instance then
			return
		end

		self.CURRENT_STATE.Instance:OnUpdate(deltaTime)
	end)

	self.Model = game.ReplicatedStorage.ClientTemplate:Clone()
	self.Model.Parent = workspace
	self.SpawnLocation = npcSpawn
	self.Service = service
	self.UniqueID = HttpService:GenerateGUID(false)
	self.Model:SetAttribute("Id", self.UniqueID)

	return self
end

function NPC:MoveTo(position: Vector3)
	print("Me movendo até " .. tostring(position))
end

function NPC:ChangeState(stateName: string, ...)
	local state = script:FindFirstChild(stateName)
	if not state then
		warn("Não achei estado do tipo " .. stateName .. "!!!!")
		return
	end

	if self.CURRENT_STATE then
		if self.CURRENT_STATE.Name == stateName then
			warn("Já to nesse estado meu brother")
			return
		end

		self.CURRENT_STATE.Instance:OnExit()
		self.CURRENT_STATE = nil
	end

	local newState = require(state).new(self, ...)
	self.CURRENT_STATE = { Name = stateName, Instance = newState }
	newState:OnEnter()

	print("Mudei o estado para " .. tostring(stateName))
end

return NPC
