local ScreenKeyboardState = {}
ScreenKeyboardState.__index = ScreenKeyboardState

function ScreenKeyboardState.new(Keyboard: {})
	local self = setmetatable({}, ScreenKeyboardState)
	self.Keyboard = Keyboard

	return self
end

-- San Francisco State Methods
function ScreenKeyboardState:Start() end

function ScreenKeyboardState:Update(deltaTime: number)
	for _text, word in self.Keyboard.WordInstances do
		word:Update(deltaTime)
	end
end

function ScreenKeyboardState:Exit()
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

function ScreenKeyboardState:Connect(conn)
	if not self.connections then
		self.connections = {}
	end

	table.insert(self.connections, conn)
end

return ScreenKeyboardState
