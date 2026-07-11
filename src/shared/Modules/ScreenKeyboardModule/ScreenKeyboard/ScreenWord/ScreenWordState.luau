local ScreenWordState = {}
ScreenWordState.__index = ScreenWordState

function ScreenWordState.new(Word: {})
	local self = setmetatable({}, ScreenWordState)
	self.Word = Word

	return self
end

-- Jarona State Methods
function ScreenWordState:Start() end

function ScreenWordState:Update(deltaTime: number) end

function ScreenWordState:Exit()
	if self.connections then
		for _, conn in self.connections do
			if not conn then
				continue
			end
			conn:Disconnect()
		end
	end
end

function ScreenWordState:OnButtonClick() end
--

function ScreenWordState:Connect(conn)
	if not self.connections then
		self.connections = {}
	end

	table.insert(self.connections, conn)
end

return ScreenWordState
