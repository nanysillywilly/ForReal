local NPC = require("@game/ReplicatedStorage/Modules/NPC")
local Utils = require("@game/ReplicatedStorage/Modules/Utils/Utils")

local cashierFolder = game.Workspace["Cashier"]
local npcSpawn = cashierFolder.NPCSpawn.Position

local ClientService = {
	activeClients = {},
	tables = Utils.sameTypeGatherer(cashierFolder.Tables),
	activeTables = {},
}

ClientService.Events = {
	StartDialogue = {
		client = true,
		server = false,
		schema = {
			npcId = "string",
		},
	},
}

ClientService.routes = {
	{
		arriveWaypoints = Utils.sameTypeGatherer(cashierFolder.RQueueEntering),
		leaveWaypoints = Utils.sameTypeGatherer(cashierFolder.RQueueLeaving),
		queue = {},
	},
	{
		arriveWaypoints = Utils.sameTypeGatherer(cashierFolder.LQueueEntering),
		leaveWaypoints = Utils.sameTypeGatherer(cashierFolder.LQueueLeaving),
		queue = {},
	},
}

function ClientService:Init()
	local nextNPCButton = cashierFolder.NextNPCButton
	local rOderNotedButton = cashierFolder.ROderNotedButton
	local lOrderNotedButton = cashierFolder.LOrderNotedButton

	local debounce = false
	nextNPCButton.Touched:Connect(function(_hit)
		if debounce then
			return
		end
		debounce = true
		ClientService:SpawnClient()

		task.delay(1, function()
			debounce = false
		end)
	end)

	local debounceR = false
	rOderNotedButton.Touched:Connect(function(_hit)
		if debounceR then
			return
		end
		debounceR = true

		ClientService:ChangeToSitOrLeaving(1)

		task.delay(1, function()
			debounceR = false
		end)
	end)

	local debounceL = false
	lOrderNotedButton.Touched:Connect(function(_hit)
		if debounceL then
			return
		end
		debounceL = true

		ClientService:ChangeToSitOrLeaving(2)

		task.delay(1, function()
			debounceL = false
		end)
	end)

	return true
end

function ClientService:SpawnClient()
	local InstanciaNPC = NPC.new(npcSpawn, self)
	table.insert(self.activeClients, InstanciaNPC)
	InstanciaNPC:ChangeState("Arriving")
end

function ClientService:UpdateQueuePositions(route)
	for i, npc in route.queue do
		local humanoid = npc.Model:FindFirstChild("Humanoid")

		if humanoid then
			local basePos = route.arriveWaypoints[#route.arriveWaypoints]
			local offset = Vector3.new(0, 0, 5 * (i - 1))
			local targetPos = basePos + offset
			humanoid:MoveTo(targetPos)
		end
	end
end

function ClientService:ChangeToDialogue(npc)
	if not npc then
		return
	end

	npc:ChangeState("Dialogue")
end

function ClientService:ChangeToSitOrLeaving(route)
	local npc = self.routes[route].queue[1]
	local behaviorOptions = { "Leaving", "Sitting" }
	local chosenBehavior = behaviorOptions[math.random(1, #behaviorOptions)]
	local chosenTable = nil

	if not npc then
		return
	end

	if chosenBehavior == "Sitting" then
		for _, mesa in pairs(ClientService.tables) do
			if not table.find(ClientService.activeTables, mesa) then
				chosenTable = mesa
				table.insert(ClientService.activeTables, mesa)
				break
			end
		end
	elseif chosenBehavior == "Leaving" then
		table.remove(self.activeClients, table.find(self.activeClients, npc))
	end

	npc:ChangeState(chosenTable and "Sitting" or "Leaving", chosenTable)
end

return ClientService
