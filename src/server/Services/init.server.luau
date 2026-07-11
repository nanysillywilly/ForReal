local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Start = require(ReplicatedStorage.Modules.Core.Start)

local StartService = Start.New({
	componentType = "Service",
	pluralType = "Services",
	componentSuffix = "Service",
	priorityComponents = { "Event", "Data" },
	updateRates = { DEFAULT = 1 / 60, LOW = 1 / 30, VERY_LOW = 1 / 15, BACKGROUND = 1 / 5 },
	getRootFolder = function()
		return game:GetService("ServerScriptService").Services
	end,
})

StartService:Start():catch(function(err)
	warn("Servidor falhou ao iniciar:", err)
end)
