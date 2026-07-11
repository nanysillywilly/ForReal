local ClientService = require("@game/ServerScriptService/Services/ClientService")
local Utils = require("../Utils/Utils")
local NPCState = require(script.Parent.NPCState)

local Leaving = setmetatable({}, { __index = NPCState })
Leaving.__index = Leaving

function Leaving.new(NPC: {})
	local self = NPCState.new(NPC)
	setmetatable(self, Leaving)

	return self
end

-- NPC State Methods
function Leaving:OnEnter()
	NPCState.OnEnter(self)

	local chosenRoute = self.NPC.Service.routes[self.NPC.ChosenRoute]
	table.remove(chosenRoute.queue, table.find(chosenRoute.queue, self.NPC))
	self.CurrentWaypoint = 1

	self.NPC.Model.Humanoid:MoveTo(chosenRoute.leaveWaypoints[self.CurrentWaypoint])

	self:Connect(self.NPC.Model.Humanoid.MoveToFinished:Connect(function(reached)
		if reached then
			self.CurrentWaypoint =
				Utils.reached(self.CurrentWaypoint, chosenRoute.leaveWaypoints, self.NPC.Model.Humanoid)

			if self.CurrentWaypoint > #chosenRoute.leaveWaypoints then
				self.NPC.Model:Destroy()
			end
		else
			print("Failed to reach waypoint")
		end
	end))

	ClientService:UpdateQueuePositions(chosenRoute)
	table.remove(
		self.NPC.Service.routes[self.NPC.ChosenRoute].queue,
		table.find(self.NPC.Service.routes[self.NPC.ChosenRoute].queue, self.NPC)
	)
end

function Leaving:OnUpdate(deltaTime: number)
	NPCState.OnUpdate(self, deltaTime)
end

function Leaving:OnExit()
	NPCState.OnExit(self)
end
--

return Leaving
