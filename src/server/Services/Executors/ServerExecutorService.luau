local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerExecutorService = {}

ServerExecutorService.Dependencies = { "Event" }
ServerExecutorService.Events = {
	Exec = {
		server = true,
		client = false,
		schema = {
			moduleName = "string",
			behaviorName = "string",
			data = "table",
		},
	},
}

local Services
local PREFFIX = "[ServerExecutor]"

function ServerExecutorService:Init(services, modules)
	Services = services
	return true
end

function ServerExecutorService:Start()
	Services.Event:On("ServerExecutor.Exec", function(player, payload)
		self:_dispatch(player, payload)
	end)
	return true
end

function ServerExecutorService:_dispatch(player: Player, payload)
	-- Find module in ReplicatedStorage
	local moduleScript = ReplicatedStorage:FindFirstChild(payload.moduleName, true)
	if not moduleScript then
		warn(("'%s' Módulo '%s' não encontrado."):format(PREFFIX, payload.moduleName))
		return
	end

	local ok, module = pcall(require, moduleScript)
	if not ok then
		warn(("'%s' Erro ao require '%s': %s"):format(PREFFIX, payload.moduleName, module))
		return
	end

	-- Only execute if module.OnServer exists
	local onServer = module.OnServer
	if not onServer then
		warn(("'%s' '%s' não tem tabela OnServer."):format(PREFFIX, payload.moduleName))
		return
	end

	local behavior = onServer[payload.behaviorName]
	if not behavior then
		warn(
			("'%s' Behavior '%s' não encontrado em '%s'.OnServer."):format(
				PREFFIX,
				payload.behaviorName,
				payload.moduleName
			)
		)
		return
	end

	behavior(player, payload.data)
end

return ServerExecutorService
