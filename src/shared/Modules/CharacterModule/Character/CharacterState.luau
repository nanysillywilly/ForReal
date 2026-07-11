local CharacterState = {}
CharacterState.__index = CharacterState

function CharacterState.new(character, args: {}?)
	local self = setmetatable({}, CharacterState)
	self.Character = character

	if args then
		for property, value in args do
			self[property] = value
		end
	end

	return self
end

-- State Functions --
function CharacterState:Start() end

function CharacterState:Update(deltaTime) end

function CharacterState:Exit()
	if self._promises then
		for _, promise in self._promises do
			if not promise then
				continue
			end

			promise:cancel()
		end
	end

	if self._connections then
		for _, conn in self._connections do
			if not conn then
				continue
			end

			conn:Disconnect()
		end
	end
end
--

-- Input Callbacks --
function CharacterState:OnActionPressed(action: string) end

function CharacterState:OnActionReleased(action: string) end
--

-- Collision --
function CharacterState:OnTouchClient(otherPart: BasePart) end
--

-- Internal --
function CharacterState:Connect(connection)
	if not self._connections then
		self._connections = {}
	end

	if not connection then
		return
	end

	table.insert(self._connections, connection)
end

function CharacterState:Promise(promise)
	if not self._promises then
		self._promises = {}
	end

	if not promise then
		return
	end

	table.insert(self._promises, promise)
end
--

return CharacterState