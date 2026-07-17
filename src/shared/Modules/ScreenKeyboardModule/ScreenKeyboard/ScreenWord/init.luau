local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local DialogueWords = require("../../Language/English/DialogueWords")
local ScreenWord = {}
ScreenWord.__index = ScreenWord

local TEMPLATE_GUI = ReplicatedStorage.TemplateButton

local function FindEntryByWord(palavra: string)
    for _, entry in DialogueWords do
        if entry.word == palavra then
            return entry
        end
    end
    return nil
end

function ScreenWord.new(text: string, index: number, parent: Frame, Keyboard: { GUI: ScreenGui })
	local self = setmetatable({}, ScreenWord)

	local r = math.random(0, 255)
	local g = math.random(0, 255)
	local b = math.random(0, 255)

	self.index = index
	self.options = FindEntryByWord(text).options
	self.combinedOptions = FindEntryByWord(text).combinedOptions
	local newBt: TextButton = TEMPLATE_GUI:Clone()
	newBt.Text = text
	newBt.Name = text
	newBt.BackgroundColor3 = Color3.fromRGB(r, g, b)
	newBt.Parent = parent
	self.Button = newBt
	newBt.LayoutOrder = index + 100

	self._dragging = false
	self:Connect(self.Button.MouseButton1Down:Connect(function()
		local estadoAntigo = self.CURRENT_STATE.Name
		task.delay(0.15, function()
			if estadoAntigo ~= self.CURRENT_STATE.Name then
				return
			end

			self:ChangeState("WordDragging")
		end)
	end))
	self:Connect(self.Button.MouseButton1Click:Connect(function()
		if self._dragging then
			return
		end
		self:OnButtonClick()
	end))

	self.Keyboard = Keyboard

	self:ChangeState("WordAvailable")

	return self
end

function ScreenWord:Update(deltaTime: number)
	if not self.CURRENT_STATE then
		return
	end

	if not self.CURRENT_STATE.Instance then
		return
	end

	self.CURRENT_STATE.Instance:Update(deltaTime)
end

function ScreenWord:OnButtonClick()
	if not self.CURRENT_STATE then
		return
	end

	if not self.CURRENT_STATE.Instance then
		return
	end

	self.CURRENT_STATE.Instance:OnButtonClick()
end

function ScreenWord:ChangeState(stateName: string, ...)
	local state = script:FindFirstChild(stateName)
	if not state then
		warn("Não achei estado do tipo " .. stateName .. "!!!!")
		return
	end

	if self.CURRENT_STATE then
		if self.CURRENT_STATE.Name == stateName then
			warn("Já to nesse estado meu brother")
			return
		end

		self.CURRENT_STATE.Instance:Exit()
		self.CURRENT_STATE = nil
	end

	local newState = require(state).new(self, ...)
	self.CURRENT_STATE = { Name = stateName, Instance = newState }
	newState:Start()
end

function ScreenWord:MoveWordTo(papai, layoutorder)
	if self.Button.Parent == papai then
		return
	end

	local wordTemplate: TextButton = self.Button:Clone()
	wordTemplate.Parent = papai
	wordTemplate.Transparency = 0.5
	wordTemplate.Name = "TweenTemplate"
	wordTemplate.LayoutOrder = layoutorder

	local tweenMoveWord = TweenService:Create(
		self.Button,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(wordTemplate.AbsolutePosition.X, wordTemplate.AbsolutePosition.Y) }
	)

	local oldPos = self.Button.AbsolutePosition
	self.Button.Parent = self.Keyboard.GUI
	self.Button.Position = UDim2.fromOffset(oldPos.X, oldPos.Y)
	tweenMoveWord.Completed:Once(function(_a0: Enum.PlaybackState)
		wordTemplate:Destroy()
		self.Button.LayoutOrder = layoutorder
		self.Button.Parent = papai
	end)
	tweenMoveWord:Play()
end

function ScreenWord:Destroy()
	if self.connections then
		for _, conn in self.connections do
			if not conn then
				continue
			end
			conn:Disconnect()
		end
	end

	if self.Button then
		self.Button:Destroy()
	end
end

-- Internal
function ScreenWord:Connect(conn)
	if not self.connections then
		self.connections = {}
	end

	table.insert(self.connections, conn)
end
--

return ScreenWord
