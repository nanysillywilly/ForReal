local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LuaUtils = require("../../../../Utils/LuaUtils")
local ScreenWordState = require("./ScreenWordState")

local WordDragging = LuaUtils:extends(ScreenWordState)
WordDragging.__index = WordDragging

function WordDragging.new(Word: {})
	local self = ScreenWordState.new(Word)
	setmetatable(self, WordDragging)
	return self
end

-- Jarona State Methods
function WordDragging:Start()
	ScreenWordState.Start(self)
	self.Word._dragging = true

	self.MousePos = self:GetMousePosWithOffset()
	if self.MousePos then
		self.Word.Button.Position = UDim2.fromOffset(self.MousePos.X, self.MousePos.Y)
	end
	self.Word.Button.Parent = self.Word.Keyboard.GUI
end

function WordDragging:Update(deltaTime: number)
	ScreenWordState.Update(self, deltaTime)

	if UserInputService:IsMouseButtonPressed(0) == false then
		self:Soltar()
		return
	end

	self.MousePos = self:GetMousePosWithOffset()
	if self.MousePos then
		self.Word.Button.Position = UDim2.fromOffset(self.MousePos.X, self.MousePos.Y)

		local buttonCenter = self.Word.Button.AbsolutePosition + self.Word.Button.AbsoluteSize / 2
		local wordsPhrased = self.Word.Keyboard.WordsPhrased

		if wordsPhrased ~= nil then
			for i, button in wordsPhrased do
				local possiblePosition = button.AbsolutePosition + button.AbsoluteSize / 2

				if
					self.Word.Button.AbsolutePosition.Y < Workspace.CurrentCamera.ViewportSize.Y / 2
					and buttonCenter.X < possiblePosition.X
				then
					self.insertIndex = i
					break
				end
			end
		end
	end
end

function WordDragging:OnButtonClick()
	ScreenWordState.OnButtonClick(self)
end

function WordDragging:Exit()
	self.Word._dragging = false
	ScreenWordState.Exit(self)
end
--

function WordDragging:Soltar()
	if self.Word.Button.AbsolutePosition.Y < Workspace.CurrentCamera.ViewportSize.Y / 2 then
		local wordsPhrased = self.Word.Keyboard.WordsPhrased

		if self.insertIndex ~= nil and table.find(wordsPhrased, self.Word.Button) == nil then
			table.insert(wordsPhrased, self.insertIndex, self.Word.Button)
		end

		self.Word:ChangeState("WordPhrased")
	else
		self.Word.Button.LayoutOrder = self.Word.index
		self.Word:ChangeState("WordAvailable")
	end
end

function WordDragging:GetMousePosWithOffset(): Vector2
	return UserInputService:GetMouseLocation()
		- (self.Word.Button.AbsoluteSize / 2)
		- Vector2.new(0, self.Word.Button.AbsoluteSize.Y)
end

return WordDragging
