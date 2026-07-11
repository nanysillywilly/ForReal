local EventController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Event = require(ReplicatedStorage.Modules.Core.Event)

EventController._isInitialized = false
EventController._warnedInitialization = false

local function CheckInitialized()
	if not EventController._isInitialized and not EventController._warnedInitialization then
		EventController._warnedInitialization = true
		warn("Attempted to use EventController before initialization")
		return false
	end
	return EventController._isInitialized
end

function EventController:Init()
	self._eventSystem = Event.New({ debug = false })
	self.events = self._eventSystem.events
	self.connections = self._eventSystem.connections
	self.remoteEvents = self._eventSystem.remoteEvents
	self.remoteFunctions = self._eventSystem.remoteFunctions
	self.warnedEvents = self._eventSystem.warnedEvents
	self.eventConfigs = self._eventSystem.eventConfigs
	self.validators = self._eventSystem.validators
	self._isInitialized = true
	return true
end

function EventController:Cleanup()
	if self._eventSystem then
		self._eventSystem:Cleanup()
	end
	self._isInitialized = false
	self._warnedInitialization = false
end

function EventController:RegisterEvent(eventName, config)
	if not CheckInitialized() then
		return nil
	end
	return self._eventSystem:RegisterEvent(eventName, config)
end

function EventController:On(eventName, callback)
	if not CheckInitialized() then
		return { Disconnect = function() end }
	end
	return self._eventSystem:On(eventName, callback)
end

function EventController:Once(eventName, callback)
	if not CheckInitialized() then
		return { Disconnect = function() end }
	end
	return self._eventSystem:Once(eventName, callback)
end

function EventController:OnClientEvent(eventName, callback)
	if RunService:IsServer() then
		return
	end
	if not CheckInitialized() then
		return { Disconnect = function() end }
	end
	return self._eventSystem:OnClientEvent(eventName, callback)
end

function EventController:Fire(eventName, ...)
	if not CheckInitialized() then
		return
	end
	return self._eventSystem:Fire(eventName, ...)
end

function EventController:FireServer(eventName, ...)
	if RunService:IsServer() then
		return
	end
	if not CheckInitialized() then
		return
	end
	return self._eventSystem:FireServer(eventName, ...)
end

function EventController:InvokeServer(functionName, ...)
	if RunService:IsServer() then
		return nil
	end
	if not CheckInitialized() then
		return nil
	end
	return self._eventSystem:InvokeServer(functionName, ...)
end

function EventController:AddValidator(name, validator)
	if not CheckInitialized() then
		return
	end
	return self._eventSystem:AddValidator(name, validator)
end

EventController.Connect = EventController.On
EventController.FireClient = EventController.Fire
EventController.Disconnect = function(connection)
	if connection then
		connection:Disconnect()
	end
end

return EventController
