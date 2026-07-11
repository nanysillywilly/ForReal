local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Start = require(ReplicatedStorage.Modules.Core.Start)

local UPDATE_RATES = {
	DEFAULT = 1 / 60,
	LOW = 1 / 30,
	VERY_LOW = 1 / 15,
	BACKGROUND = 1 / 5,
}

local PRIORITY_CONTROLLERS = table.freeze({ "Event" })

local StartController = {}
StartController.__index = StartController

function StartController.New()
	local component = Start.New({
		componentType = "Controller",
		pluralType = "Controllers",
		componentSuffix = "Controller",
		priorityComponents = PRIORITY_CONTROLLERS,
		updateRates = UPDATE_RATES,
		getRootFolder = function()
			return ReplicatedStorage.Modules.Controllers
		end,
	})
	return setmetatable({ _component = component }, StartController)
end

function StartController:Start()
	return self._component:Start()
end

function StartController:Cleanup()
	return self._component:Cleanup()
end

function StartController:GetController(name)
	return self._component:GetComponent(name)
end

return StartController
