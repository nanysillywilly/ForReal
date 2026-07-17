local DialogueWords = require("../Modules/Language/English/DialogueWords")
local ClientController = {}

local Controllers
local Modules

ClientController.Dependencies = { "Character" }
ClientController.Modules = { "ScreenKeyboard" }
ClientController.Listeners = {
	["Client.StartDialogue"] = function(self, _data)
		local formattedOptions = {}

		for _, entry in DialogueWords do
			table.insert(formattedOptions, entry.word)
		end

		local _newKeyboard = Modules.ScreenKeyboard.Get().new(formattedOptions)
		Controllers.Character.CurrentCharacter:ChangeState("CharDialogue")
	end,
}

function ClientController:Init(controllers, modules)
	Controllers = controllers
	Modules = modules

	return true
end

function ClientController:Start()
	return true
end

return ClientController
