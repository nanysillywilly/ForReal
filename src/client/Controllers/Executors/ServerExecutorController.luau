local ServerExecutorController = {}
ServerExecutorController.Dependencies = { "Event" }

local Controllers
local PREFFIX = "[ServerExecutor]"

function ServerExecutorController:Init(controllers, modules)
	Controllers = controllers
	return true
end

function ServerExecutorController:Start()
	return true
end

function ServerExecutorController:Exec(callerSelf, behaviorName: string, data: {}?)
	local class = getmetatable(callerSelf).__index

	if not class.ModuleName then
		warn(("'%s' Classe sem .ModuleName, behavior '%s' ignorado."):format(PREFFIX, behaviorName))
		return
	end

	if not class.OnServer or not class.OnServer[behaviorName] then
		warn(("'%s' '%s' não existe em %s.OnServer."):format(PREFFIX, behaviorName, class.ModuleName))
		return
	end

	Controllers.Event:FireServer("ServerExecutor.Exec", {
		moduleName = class.ModuleName,
		behaviorName = behaviorName,
		data = data or {},
	})
end

return ServerExecutorController