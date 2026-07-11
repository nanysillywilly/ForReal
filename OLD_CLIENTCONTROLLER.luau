local player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")
local Answering = require("./src/shared/Answering")
local TextBoxPlus = require("./src/shared/Utils/TextBoxPlus")
local remoteEvent: RemoteEvent = game.ReplicatedStorage.RemoteEvents.Dialogue
local dialogueGui = player.PlayerGui:WaitForChild("Answering")
local hideOrShowButton: GuiButton = dialogueGui.Tudo.HideOrShowButton

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenOpen = TweenService:Create(dialogueGui.Tudo, tweenInfo, { Position = UDim2.fromScale(0.5, 1) })
local tweenLower = TweenService:Create(dialogueGui.Tudo, tweenInfo, { Position = UDim2.fromScale(0.5, 1.402) })

local ClientController = {}

function ClientController.MoveWordTween(wordInDisplay, papai) 
	local wordTemplate: TextButton = wordInDisplay:Clone()
	wordTemplate.Parent = papai
	wordTemplate.Transparency = 1

	local tweenMoveWord = TweenService:Create(
		wordInDisplay,
		tweenInfo,
		{ Position = UDim2.fromOffset(wordTemplate.AbsolutePosition.X, wordTemplate.AbsolutePosition.Y) }
	)

	local oldPos = wordInDisplay.AbsolutePosition
	wordInDisplay.Parent = wordInDisplay.Parent.Parent.Parent
	wordInDisplay.Position = UDim2.fromOffset(oldPos.X, oldPos.Y)
	tweenMoveWord.Completed:Once(function(_a0: Enum.PlaybackState)
		wordTemplate:Destroy()
		wordInDisplay.Parent = papai
	end)
	tweenMoveWord:Play()
end

function ClientController.DisplayOptions(options, whereToDisplay, template)
	template.Visible = false
	for _, i in options do
		for _, j in i do
			local button = template:Clone()

			button.Name = j
			button.Text = j
			button.Parent = whereToDisplay
			button.Visible = true
			local padding = Instance.new("UIPadding")
			padding.PaddingTop = UDim.new(0, 8)
			padding.PaddingBottom = UDim.new(0, 8)
			padding.Parent = button

			button.MouseButton1Click:Connect(function()
				ClientController:AddWord(button)
			end)
		end
	end
end

local function CreateSpinButonTween(rotation) 
	local spinButton = TweenService:Create(hideOrShowButton, tweenInfo, { Rotation = rotation })
	spinButton:Play()
end

local oldSpace = 1

function ClientController:GetWords(text, list)
	local wordList = {}

	for _, i in list do
		for _, j in i do
			table.insert(wordList, j)
		end
	end

	if text ~= nil then
		local words = string.split(text, " ")

		if #words ~= oldSpace then
			for _, word in words do
				if table.find(wordList, word) then
					local wordInDisplay = dialogueGui.Tudo.Palavras:FindFirstChild(word)
					if not wordInDisplay then
						continue
					end
					self:AddWord(wordInDisplay)
				end
			end
		end

		oldSpace = #words
	end
end

local tbpObject = TextBoxPlus.new(dialogueGui.Tudo.Frame, { 
	TextSize = 15,
	TextWrapped = false,
	Font = Enum.Font.Code,
	PlaceholderText = "Type here or click the words to make a sentence!",
	PlaceholderColor3 = Color3.fromHex("#5b5b5b"),
	Multiline = false,
})

tbpObject.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
	ClientController:GetWords(tbpObject.TextBox.Text, Answering.Answering)
end)

function ClientController:AddWord(palavrinha)
	local isPhrased = palavrinha:GetAttribute("isPhrased")
	if palavrinha.Parent:IsA("ScreenGui") then
		return
	end

	if isPhrased then
		ClientController.MoveWordTween(palavrinha, palavrinha.Parent.Parent.Palavras)
		palavrinha:SetAttribute("isPhrased", false)
	else
		ClientController.MoveWordTween(palavrinha, palavrinha.Parent.Parent.Frase)
		palavrinha:SetAttribute("isPhrased", true)
	end
end

function ClientController:Start() 
	remoteEvent.OnClientEvent:Connect(function(_NPCID)
		dialogueGui.Enabled = true
		ClientController.DisplayOptions(
			Answering.Answering,
			dialogueGui.Tudo.Palavras,
			dialogueGui.Tudo.Palavras.TemplateButton
		)
		tweenOpen:Play()
	end)

	hideOrShowButton.Activated:Connect(function()
		if dialogueGui.Tudo.Position == UDim2.fromScale(0.5, 1) then -- Posição de quando está para cima
			CreateSpinButonTween(180)
			tweenLower:Play()
		elseif dialogueGui.Tudo.Position == UDim2.fromScale(0.5, 1.402) then -- Posição de quando está para baixo
			CreateSpinButonTween(0)
			tweenOpen:Play()
		end
	end)

	return true
end

return ClientController
