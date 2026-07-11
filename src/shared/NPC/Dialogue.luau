local EventService = require("@game/ServerScriptService/Services/Network/EventService")
local NPCState = require(script.Parent.NPCState)

local Dialogue = setmetatable({}, { __index = NPCState })
Dialogue.__index = Dialogue

function Dialogue.new(NPC: {})
	local self = NPCState.new(NPC)
	setmetatable(self, Dialogue)

	return self
end

function Dialogue:OnEnter()
	NPCState.OnEnter(self)
	local prompt:ProximityPrompt = self.NPC.Model.HumanoidRootPart:WaitForChild("ProximityPrompt")
	prompt.Enabled = true

	local guiNPC:BillboardGui = game.StarterGui:WaitForChild("NPCBubble"):Clone()
	guiNPC.Adornee = self.NPC.Model:WaitForChild("Head")
	guiNPC.Parent = self.NPC.Model

	self:Connect(prompt.Triggered:Connect(function(player)
		prompt.Enabled = false
		guiNPC.Enabled = true

		EventService:FireClient(player, "Client.StartDialogue", { npcId = self.NPC.UniqueID })
	end))
end

function Dialogue:OnUpdate(deltaTime: number)
	NPCState.OnUpdate(self, deltaTime)
end

function Dialogue:OnExit()
	NPCState.OnExit(self)
end

return Dialogue
