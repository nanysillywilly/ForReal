local EventService = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Event = require(ReplicatedStorage.Modules.Core.Event)

EventService._isInitialized = false
EventService._warnedInitialization = false
EventService._isShuttingDown = false

local function CheckInitialized()
	if EventService._isShuttingDown then
		return false
	end
	if not EventService._isInitialized and not EventService._warnedInitialization then
		if RunService:IsStudio() and not RunService:IsRunning() then
			return false
		end
		EventService._warnedInitialization = true
		warn("Attempted to use EventService before initialization")
		return false
	end
	return EventService._isInitialized
end

function EventService:Init()
	self._eventSystem = Event.New({ debug = false })
	self.events = self._eventSystem.events
	self.functions = self._eventSystem.functions
	self.connections = self._eventSystem.connections
	self.warnedEvents = self._eventSystem.warnedEvents
	self.eventConfigs = self._eventSystem.eventConfigs
	self.validators = self._eventSystem.validators
	self._shutdownConnection = game:BindToClose(function()
		self._isShuttingDown = true
	end)
	self._isInitialized = true
	return true
end

function EventService:Cleanup()
	self._isShuttingDown = true
	if self._shutdownConnection then
		self._shutdownConnection:Disconnect()
		self._shutdownConnection = nil
	end
	if self._eventSystem then
		self._eventSystem:Cleanup()
	end
	self._isInitialized = false
	self._warnedInitialization = false
end

function EventService:RegisterEvent(eventName, config)
	if not CheckInitialized() then
		return nil
	end
	return self._eventSystem:RegisterEvent(eventName, config)
end

function EventService:On(eventName, callback)
	if not CheckInitialized() then
		return { Disconnect = function() end }
	end
	return self._eventSystem:On(eventName, callback)
end

function EventService:Once(eventName, callback)
	if not CheckInitialized() then
		return { Disconnect = function() end }
	end
	return self._eventSystem:Once(eventName, callback)
end

function EventService:OnServerEvent(eventName, callback)
	if not RunService:IsServer() then
		return
	end
	if not CheckInitialized() then
		return { Disconnect = function() end }
	end
	return self._eventSystem:OnServerEvent(eventName, callback)
end

function EventService:OnClientEvent(eventName, callback)
	if RunService:IsServer() then
		return
	end
	if not CheckInitialized() then
		return { Disconnect = function() end }
	end
	return self._eventSystem:OnClientEvent(eventName, callback)
end

function EventService:Fire(eventName, ...)
	if not CheckInitialized() then
		return
	end
	return self._eventSystem:Fire(eventName, ...)
end

function EventService:FireTo(player, eventName, ...)
	if not RunService:IsServer() then
		return
	end
	if not CheckInitialized() then
		return
	end
	return self._eventSystem:FireTo(player, eventName, ...)
end

function EventService:FireAllExcept(excludedPlayer, eventName, ...)
	if not RunService:IsServer() then
		return
	end
	if not CheckInitialized() then
		return
	end
	return self._eventSystem:FireAllExcept(excludedPlayer, eventName, ...)
end

function EventService:FireServer(eventName, ...)
	if RunService:IsServer() then
		return
	end
	if not CheckInitialized() then
		return
	end
	return self._eventSystem:FireServer(eventName, ...)
end

function EventService:RegisterFunction(functionName)
	if not RunService:IsServer() then
		return
	end
	if not CheckInitialized() then
		return
	end
	return self._eventSystem:RegisterFunction(functionName)
end

function EventService:SetCallback(functionName, callback)
	if not RunService:IsServer() then
		return
	end
	if not CheckInitialized() then
		return
	end
	return self._eventSystem:SetCallback(functionName, callback)
end

function EventService:InvokeServer(functionName, ...)
	if RunService:IsServer() then
		return nil
	end
	if not CheckInitialized() then
		return nil
	end
	return self._eventSystem:InvokeServer(functionName, ...)
end

EventService.Connect = EventService.On
EventService.FireClient = EventService.FireTo
EventService.Disconnect = function(connection)
	if connection then
		connection:Disconnect()
	end
end

return EventService
