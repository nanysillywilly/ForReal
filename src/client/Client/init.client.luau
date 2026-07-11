local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StartController = require(ReplicatedStorage.Modules.Controllers.Network.StartController)

local client = StartController.New()

client:Start():andThen(function() end):catch(function(err)
	warn("Cliente falhou ao iniciar:", err)
end)
