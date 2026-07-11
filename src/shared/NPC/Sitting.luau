local ClientService = require("@game/ServerScriptService/Services/ClientService")
local NPCState = require(script.Parent.NPCState)

local Sitting = setmetatable({}, { __index = NPCState })
Sitting.__index = Sitting

function Sitting.new(NPC: {}, chosenTable)
	local self = NPCState.new(NPC)
	setmetatable(self, Sitting)

	self.mesa = chosenTable

	return self
end

-- NPC State Methods
function Sitting:OnEnter()
	NPCState.OnEnter(self)

	if self.mesa then
		self.NPC.Model.Humanoid:MoveTo(self.mesa)

		table.remove(
			self.NPC.Service.routes[self.NPC.ChosenRoute].queue,
			table.find(self.NPC.Service.routes[self.NPC.ChosenRoute].queue, self.NPC)
		)
		ClientService:UpdateQueuePositions(self.NPC.Service.routes[self.NPC.ChosenRoute])
		return
	else
		print("No free table, will leave instead")
	end
end

function Sitting:OnUpdate(deltaTime: number)
	NPCState.OnUpdate(self, deltaTime)
end

function Sitting:OnExit()
	NPCState.OnExit(self)
end
--

return Sitting
