local LuaUtils = require("../../../../Utils/LuaUtils")
local ScreenWordState = require("./ScreenWordState")

local WordAvailable = LuaUtils:extends(ScreenWordState)
WordAvailable.__index = WordAvailable

function WordAvailable.new(Word: {})
	local self = ScreenWordState.new(Word)
	setmetatable(self, WordAvailable)
	return self
end

-- Jarona State Methods
function WordAvailable:Start()
	ScreenWordState.Start(self)

	if self.Word.AvailableIndex then
		self.Word.Button.LayoutOrder = self.Word.AvailableIndex
	end

	self.Word:MoveWordTo(self.Word.Keyboard.GUI.Tudo.Palavras, self.Word.Button.LayoutOrder)
end

function WordAvailable:Update(deltaTime: number)
	ScreenWordState.Update(self, deltaTime)
end

function WordAvailable:OnButtonClick()
	ScreenWordState.OnButtonClick(self)
	self.Word:ChangeState("WordPhrased")
end

function WordAvailable:Exit()
	ScreenWordState.Exit(self)
end
--

return WordAvailable
