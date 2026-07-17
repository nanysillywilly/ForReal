local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocaleUtils = require("../../Utils/LocaleUtils")
local LuaUtils = require("../../Utils/LuaUtils")
local TextBoxPlus = require("../../Utils/TextBoxPlus")

local ScreenKeyboard = {}
ScreenKeyboard.__index = ScreenKeyboard

local GUI_TEMPLATE = ReplicatedStorage.ScreenKeyboard

function ScreenKeyboard.new(options, args: {}?)
	local self = setmetatable({}, ScreenKeyboard)
	if args ~= nil then
		LuaUtils:CollectArgs(self, args)
	end

	self.GUI = GUI_TEMPLATE:Clone()
	self.GUI.Parent = Players.LocalPlayer.PlayerGui
	self.WordInstances = {}
	self.WordsPhrased = {}

	self.TextBox = TextBoxPlus.new(self.GUI.Tudo.Frame, {
		TextSize = 15,
		TextWrapped = false,
		Font = Enum.Font.Code,
		PlaceholderText = "",
		PlaceholderColor3 = Color3.fromHex("#5b5b5b"),
		Multiline = false,
		Padded = false,
	})

	self.TextBox.TextBox.PlaceholderText = LocaleUtils:GetText("KeyboardTutorialMessage")
	self:Connect(LocaleUtils.LanguageChanged:Connect(function()
		self.TextBox.TextBox.PlaceholderText = LocaleUtils:GetText("KeyboardTutorialMessage")
	end))

	self:Connect(self.TextBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		if self.TextBox == nil then
			return
		end

		local textBox: TextBox = self.TextBox.TextBox
		textBox.TextColor3 = Color3.new(0, 0, 0)

		if not string.find(textBox.Text, " ") then
			return
		end

		local words = string.split(textBox.Text, " ")
		if words[1] ~= " " and words[1] ~= "" then
			local wordInstance = self.WordInstances[words[1]]
			if wordInstance then
				if wordInstance.CURRENT_STATE.Name ~= "WordPhrased" then
					wordInstance:ChangeState("WordPhrased")
					self.TextBox.SetContent("")
				else
					-- Tentou ir pra word phrased mas ja tava phrased
					textBox.TextColor3 = Color3.new(1, 0.054902, 0.054902)
				end
			else
				-- Nao achei a instnacia do texto, o brother escreveu algo erraddo
				textBox.TextColor3 = Color3.new(1, 0.054902, 0.054902)
			end
		end
	end))

	local function setupOptions()
		for index, palavrinha in options do
			self:InstanceWord(palavrinha, index)
		end
	end
	setupOptions()

	self.Joana = self.GUI.Tudo.Joana

	self:ChangeState("KeyboardOpened")

	self:Connect(RunService.RenderStepped:Connect(function(deltaTime: number)
		self:Update(deltaTime)
	end))

	return self
end

function ScreenKeyboard:ChangeState(stateName: string, ...)
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

function ScreenKeyboard:Update(deltaTime: number)
	if not self.CURRENT_STATE then
		return
	end

	if not self.CURRENT_STATE.Instance then
		return
	end

	self.CURRENT_STATE.Instance:Update(deltaTime)
end

function ScreenKeyboard:Destroy()
	if self.connections then
		for _, conn in self.connections do
			if not conn then
				continue
			end
			conn:Disconnect()
		end
	end

	for _, word in self.WordInstances do
		word:Destroy()
	end

	if self.GUI then
		self.GUI:Destroy()
	end
end

function ScreenKeyboard:InstanceWord(text: string, index)
	local newWord = require(script.ScreenWord).new(text, index, self.GUI.Tudo.Palavras, self)
	self.WordInstances[text] = newWord
end

-- Internal
function ScreenKeyboard:Connect(conn)
	if not self.connections then
		self.connections = {}
	end

	table.insert(self.connections, conn)
end
--

return ScreenKeyboard
