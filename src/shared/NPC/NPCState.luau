local NPCState = {}
NPCState.__index = NPCState

function NPCState.new(NPC: {})
	local self = setmetatable({}, NPCState)
	self.NPC = NPC

	return self
end

-- NPC State Methods
function NPCState:OnEnter() end

function NPCState:OnUpdate(_deltaTime: number) end

function NPCState:OnExit()
	if self.connections then
		for _, conn in self.connections do
			if not conn then
				continue
			end
			conn:Disconnect()
		end
	end
end
--

function NPCState:Connect(conn)
	if not self.connections then
		self.connections = {}
	end

	table.insert(self.connections, conn)
end

return NPCState
