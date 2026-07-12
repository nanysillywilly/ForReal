local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require("../../Packages/Signal")
local Language = require("../Modules/Language")
local LazyLoader = require("../Utils/GuiLib/LazyLoader")
local LocaleUtils = require("../Utils/LocaleUtils")
local LuaUtils = require("../Utils/LuaUtils")
local UIController = { CurrentSave = nil, GUI = nil, OnSettingsChanged = Signal.new() }

UIController.Dependencies = { "Event", "Player" }
UIController.Modules = { "Character" }

local Controllers
local _Modules

UIController.Listeners = {
	["UI.LoadedSettings"] = function(self, data)
		self.CurrentSave = data.data
		self:ApplySettings()
	end,
}

function UIController:Init(controllers, modules)
	Controllers = controllers
	_Modules = modules

	self:BuildUI()

	return true
end

function UIController:Start()
	return true
end

function UIController:BuildUI()
	self.GUI = ReplicatedStorage.UI:Clone()
	self.GUI.Parent = Players.LocalPlayer.PlayerGui

	local settingsFrame = self.GUI.SettingsPanel
	local optionsFrame = settingsFrame.OptionsFrame
	local templateOptionFrame = optionsFrame.OptionFrame

	templateOptionFrame.Visible = false

	local languageList = {}
	for nome, _ in Language do
		table.insert(languageList, nome)
	end

	local optionList = {
		{ ID = "Language", Label = "Language", Type = "Dropdown", Value = languageList },
		{ ID = "Rafracise", Label = "RafaelCiso", Type = "Checkbox" },
	}

	for i, option in optionList do
		local label = option.Label
		local optionType = option.Type
		local values = option.Value

		local guiFrame = templateOptionFrame:Clone()
		guiFrame.Parent = optionsFrame
		guiFrame.Visible = true
		guiFrame.OptionName.Text = label

		local optionValueFrame = guiFrame.OptionValue

		LuaUtils:switch(optionType)
			.case("Dropdown", function()
				guiFrame.ZIndex = 100 / i
				local dropdown = LazyLoader.Classes.Dropdown.Create(values, 4)

				dropdown.Button.Position = UDim2.fromOffset(0, 0)
				dropdown.Button.Parent = optionValueFrame
				dropdown.Button.Size = UDim2.fromScale(1, 1)
				self.OnSettingsChanged:Connect(function()
					dropdown:SetOptionByString(self.CurrentSave[option.ID])
				end)
				dropdown.Changed:Connect(function()
					self:ChangeSetting(option.ID, dropdown:GetText())
				end)
			end)
			.case("Checkbox", function()
				local checkbox = LazyLoader.Classes.CheckboxLabel.Create("")
				checkbox.Frame.Position = UDim2.fromOffset(0, 0)
				checkbox.Frame.Parent = optionValueFrame
				checkbox.Frame.Size = UDim2.fromScale(1, 1)

				UIController.OnSettingsChanged:Connect(function()
					checkbox:SetValue(self.CurrentSave[option.ID])
				end)
				checkbox.Changed:Connect(function()
					self:ChangeSetting(option.ID, checkbox:GetValue())
				end)
			end)
			.process()
	end
end

function UIController:ChangeSetting(settingName: string, newValue: any)
	if self.CurrentSave[settingName] == nil then
		return
	end

	self.CurrentSave[settingName] = newValue
	Controllers.Event:FireServer("UI.ChangeSetting", { id = settingName, newValue = newValue })
	LocaleUtils:LoadEntries(self.CurrentSave.Language)
end

function UIController:ApplySettings()
	UIController.OnSettingsChanged:Fire()
	LocaleUtils:LoadEntries(self.CurrentSave.Language)
end

return UIController
