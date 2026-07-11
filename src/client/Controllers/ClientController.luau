local Answering = require("../Answering")
local ClientController = {}

local Controllers
local Modules

ClientController.Dependencies = { "Character" }
ClientController.Modules = { "ScreenKeyboard" }
ClientController.Listeners = {
	["Client.StartDialogue"] = function(self, _data)
		local formattedOptions = {}
		for _, i in Answering.Answering do
			for _, j in i do
				table.insert(formattedOptions, j)
			end
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
