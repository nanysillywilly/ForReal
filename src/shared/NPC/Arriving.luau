local ClientService = require("@game/ServerScriptService/Services/ClientService")
local Utils = require("../Utils/Utils")
local NPCState = require(script.Parent.NPCState)

local Arriving = setmetatable({}, { __index = NPCState })
Arriving.__index = Arriving

function Arriving.new(NPC: {})
	local self = NPCState.new(NPC)
	setmetatable(self, Arriving)

	return self
end

-- NPC State Methods
function Arriving:OnEnter()
	NPCState.OnEnter(self)

	self.NPC.ChosenRoute = math.random(1, #self.NPC.Service.routes)

	self.NPC.Model:MoveTo(self.NPC.SpawnLocation)
	self.CurrentWaypoint = 1
	local chosenRoute = self.NPC.Service.routes[self.NPC.ChosenRoute]

	self.NPC.Model.Humanoid:MoveTo(chosenRoute.arriveWaypoints[self.CurrentWaypoint])

	self:Connect(self.NPC.Model.Humanoid.MoveToFinished:Connect(function(reached)
		if reached then
			self.CurrentWaypoint =
				Utils.reached(self.CurrentWaypoint, chosenRoute.arriveWaypoints, self.NPC.Model.Humanoid)

			if
				self.CurrentWaypoint > #chosenRoute.arriveWaypoints
				and ClientService.routes[self.NPC.ChosenRoute].queue[1] == self.NPC
			then
				ClientService:ChangeToDialogue(self.NPC)
			end
		else
			print("Failed to reach waypoint")
		end
	end))
end

function Arriving:OnUpdate(deltaTime: number)
	NPCState.OnUpdate(self, deltaTime)

	if not self.NPC.ChosenRoute then
		return
	end

	local chosenRoute = self.NPC.Service.routes[self.NPC.ChosenRoute]

	if self.CurrentWaypoint >= #chosenRoute.arriveWaypoints then
		if not table.find(chosenRoute.queue, self.NPC) then
			table.insert(chosenRoute.queue, self.NPC)

			ClientService:UpdateQueuePositions(chosenRoute)
		end

		return
	end
end

function Arriving:OnExit()
	NPCState.OnExit(self)
end
--

return Arriving
