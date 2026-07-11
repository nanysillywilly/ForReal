local LuaUtils = require("../../../../Utils/LuaUtils")
local ScreenWordState = require("./ScreenWordState")

local WordPhrased = LuaUtils:extends(ScreenWordState)
WordPhrased.__index = WordPhrased

function WordPhrased.new(Word: {})
	local self = ScreenWordState.new(Word)
	setmetatable(self, WordPhrased)
	return self
end

-- Jarona State Methods
function WordPhrased:Start()
	ScreenWordState.Start(self)

	if not self.Word.AvailableIndex then
		self.Word.AvailableIndex = self.Word.Button.LayoutOrder
	end

	if table.find(self.Word.Keyboard.WordsPhrased, self.Word.Button) == nil then
		table.insert(self.Word.Keyboard.WordsPhrased, self.Word.Button)
	end

	self.index = table.find(self.Word.Keyboard.WordsPhrased, self.Word.Button)
	for i, button in self.Word.Keyboard.WordsPhrased do
		if button ~= self.Word.Button then
			button.LayoutOrder = i
		end
	end
	self.Word:MoveWordTo(self.Word.Keyboard.GUI.Tudo.Frase, self.index or self.Word.Button.LayoutOrder)
end

function WordPhrased:Update(deltaTime: number)
	ScreenWordState.Update(self, deltaTime)
end

function WordPhrased:OnButtonClick()
	ScreenWordState.OnButtonClick(self)
	self.Word:ChangeState("WordAvailable")
end

function WordPhrased:Exit()
	local index = table.find(self.Word.Keyboard.WordsPhrased, self.Word.Button)

	if index then
		table.remove(self.Word.Keyboard.WordsPhrased, index)
	end
	
	ScreenWordState.Exit(self)
end
--

return WordPhrased
