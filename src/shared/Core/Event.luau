local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

export type EventConfig = {
	server: boolean?,
	client: boolean?,
	reliable: boolean?,
	throttle: number?,
	validate: boolean?,
	schema: { [string]: string | { type: string, validator: (any) -> boolean } }?,
	local_only: boolean?,
	debounce: number?,
}

export type EventDefinition = {
	name: string,
	remote: boolean,
	bindable: BindableEvent,
	remoteEvent: RemoteEvent?,
	config: EventConfig,
	connections: { [string]: RBXScriptConnection },
}

export type FunctionDefinition = {
	name: string,
	remote: RemoteFunction?,
	callback: ((player: Player, ...any) -> ...any)?,
}

local DEFAULT_EVENT_CONFIG = {
	server = true,
	client = true,
	reliable = true,
	local_only = false,
	debounce = 0.01,
}

local Validators = {
	string = function(value)
		return type(value) == "string"
	end,
	number = function(value)
		return type(value) == "number"
	end,
	boolean = function(value)
		return type(value) == "boolean"
	end,
	table = function(value)
		return type(value) == "table"
	end,
	["function"] = function(value)
		return type(value) == "function"
	end,
	Instance = function(value)
		return typeof(value) == "Instance"
	end,
	Vector3 = function(value)
		return typeof(value) == "Vector3"
	end,
	CFrame = function(value)
		return typeof(value) == "CFrame"
	end,
	Color3 = function(value)
		return typeof(value) == "Color3"
	end,
	int = function(value)
		return type(value) == "number" and value % 1 == 0
	end,
	positiveNumber = function(value)
		return type(value) == "number" and value > 0
	end,
	negativeNumber = function(value)
		return type(value) == "number" and value < 0
	end,
	nonNegativeNumber = function(value)
		return type(value) == "number" and value >= 0
	end,
	userId = function(value)
		return type(value) == "number" and value > 0
	end,
	playerInstance = function(value)
		return typeof(value) == "Instance" and value:IsA("Player")
	end,
	nonEmptyString = function(value)
		return type(value) == "string" and #value > 0
	end,
	alphanumeric = function(value)
		return type(value) == "string" and not not value:match("^[%w_]+$")
	end,
	nonEmptyTable = function(value)
		return type(value) == "table" and next(value) ~= nil
	end,
	array = function(value)
		if type(value) ~= "table" then
			return false
		end
		local length = #value
		return length > 0
			and length
				== (function()
					local count = 0
					for _ in pairs(value) do
						count += 1
					end
					return count
				end)()
	end,
}

local function _ValidateData(data, schema, eventName)
	if type(data) ~= "table" then
		return false, "Expected table, got " .. type(data)
	end
	for field, validator in pairs(schema) do
		local value = data[field]
		if value == nil then
			return false, string.format("Missing required field '%s' in event %s", field, eventName)
		end
		local validatorType = type(validator)
		local success = false
		if validatorType == "string" then
			local validatorFn = Validators[validator]
			if validatorFn then
				success = validatorFn(value)
			end
		elseif validatorType == "table" and validator.type then
			local typeValidator = Validators[validator.type]
			success = typeValidator and typeValidator(value)
			if success and validator.validator then
				success = validator.validator(value)
			end
		elseif validatorType == "function" then
			success = validator(value)
		end
		if not success then
			return false, string.format("Validation failed for field '%s' in event %s", field, eventName)
		end
	end
	return true
end

local function CreateEventsFolder()
	local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if not eventsFolder then
		eventsFolder = Instance.new("Folder")
		eventsFolder.Name = "Events"
		eventsFolder.Parent = ReplicatedStorage
	end
	return eventsFolder
end

local function CreateFunctionsFolder()
	local functionsFolder = ReplicatedStorage:FindFirstChild("Functions")
	if not functionsFolder then
		functionsFolder = Instance.new("Folder")
		functionsFolder.Name = "Functions"
		functionsFolder.Parent = ReplicatedStorage
	end
	return functionsFolder
end

local Event = {}
Event.__index = Event

function Event.New(config)
	local self = setmetatable({
		events = {},
		functions = {},
		connections = {},
		remoteEvents = {},
		remoteFunctions = {},
		warnedEvents = {},
		eventConfigs = {},
		validators = table.clone(Validators),
		isServer = RunService:IsServer(),
		config = config or {},
		pendingEvents = {},
		pendingFunctions = {},
		debounceTimers = {},
	}, Event)
	self.eventsFolder = CreateEventsFolder()
	self.functionsFolder = CreateFunctionsFolder()
	self:Init()
	return self
end

function Event:Init()
	if self.isServer then
		return true
	end
	self.eventsFolder.ChildAdded:Connect(function(child)
		if child:IsA("RemoteEvent") then
			self.remoteEvents[child.Name] = child
			self:SetupRemoteEvent(child)
			if self.pendingEvents[child.Name] then
				for _, callback in ipairs(self.pendingEvents[child.Name]) do
					task.spawn(callback, child)
				end
				self.pendingEvents[child.Name] = nil
			end
		end
	end)
	for _, remoteEvent in ipairs(self.eventsFolder:GetChildren()) do
		if remoteEvent:IsA("RemoteEvent") then
			self.remoteEvents[remoteEvent.Name] = remoteEvent
			self:SetupRemoteEvent(remoteEvent)
		end
	end
	self.functionsFolder.ChildAdded:Connect(function(child)
		if child:IsA("RemoteFunction") then
			self.remoteFunctions[child.Name] = child
			if self.pendingFunctions[child.Name] then
				for _, callback in ipairs(self.pendingFunctions[child.Name]) do
					task.spawn(callback, child)
				end
				self.pendingFunctions[child.Name] = nil
			end
		end
	end)
	for _, remoteFunction in ipairs(self.functionsFolder:GetChildren()) do
		if remoteFunction:IsA("RemoteFunction") then
			self.remoteFunctions[remoteFunction.Name] = remoteFunction
		end
	end
	return true
end

function Event:SetupRemoteEvent(remoteEvent)
	if self.isServer then
		return
	end
	local eventName = remoteEvent.Name
	if not self.connections[eventName] then
		self.connections[eventName] = remoteEvent.OnClientEvent:Connect(function(...)
			self:FireListeners(eventName, ...)
		end)
	end
end

function Event:AddValidator(name, validator)
	if type(validator) ~= "function" then
		return
	end
	self.validators[name] = validator
end

function Event:RegisterEvent(eventName, config)
	if type(eventName) ~= "string" then
		return nil
	end
	if self.events[eventName] then
		return self.events[eventName]
	end
	local finalConfig = table.clone(DEFAULT_EVENT_CONFIG)
	if type(config) == "table" then
		for k, v in pairs(config) do
			finalConfig[k] = v
		end
	elseif type(config) == "boolean" then
		finalConfig.server = config
		finalConfig.client = config
	end
	self.eventConfigs[eventName] = finalConfig
	local isRemote = (finalConfig.server or finalConfig.client) and not finalConfig.local_only
	local remoteEvent
	if isRemote and self.isServer then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = eventName
		remoteEvent.Parent = self.eventsFolder
		remoteEvent.OnServerEvent:Connect(function(player, ...)
			self.events[eventName].bindable:Fire(player, ...)
		end)
	elseif not self.isServer then
		remoteEvent = self.remoteEvents[eventName] or self.eventsFolder:FindFirstChild(eventName)
		if remoteEvent then
			self.remoteEvents[eventName] = remoteEvent
			self:SetupRemoteEvent(remoteEvent)
		end
	end
	self.events[eventName] = {
		name = eventName,
		remote = isRemote,
		bindable = Instance.new("BindableEvent"),
		remoteEvent = remoteEvent,
		config = finalConfig,
		connections = {},
	}
	return self.events[eventName]
end

function Event:RegisterFunction(functionName)
	if type(functionName) ~= "string" or not self.isServer then
		return
	end
	if self.functions[functionName] then
		return self.functions[functionName]
	end
	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = functionName
	remoteFunction.Parent = self.functionsFolder
	self.functions[functionName] = { name = functionName, remote = remoteFunction, callback = nil }
	return self.functions[functionName]
end

function Event:SetCallback(functionName, callback)
	if not self.isServer or type(callback) ~= "function" then
		return
	end
	if not self.functions[functionName] then
		self:RegisterFunction(functionName)
	end
	local func = self.functions[functionName]
	func.callback = callback
	func.remote.OnServerInvoke = function(player, ...)
		return callback(player, ...)
	end
end

function Event:InvokeServer(functionName, ...)
	if self.isServer then
		return nil
	end
	local args = { ... }
	local remoteFunction = self.remoteFunctions[functionName]
	if remoteFunction then
		local success, result = pcall(function()
			return remoteFunction:InvokeServer(table.unpack(args))
		end)
		if success then
			return result
		end
		warn("Failed to invoke server function:", functionName, result)
		return nil
	end
	remoteFunction = self.functionsFolder:FindFirstChild(functionName)
	if remoteFunction then
		self.remoteFunctions[functionName] = remoteFunction
		local success, result = pcall(function()
			return remoteFunction:InvokeServer(table.unpack(args))
		end)
		if success then
			return result
		end
		return nil
	end
	if not self.pendingFunctions[functionName] then
		self.pendingFunctions[functionName] = {}
	end
	local result, resultReady
	local handleFunction = function(fn)
		local ok, fnResult = pcall(function()
			return fn:InvokeServer(table.unpack(args))
		end)
		if ok then
			result = fnResult
		end
		resultReady = true
	end
	table.insert(self.pendingFunctions[functionName], handleFunction)
	task.delay(0.5, function()
		if not resultReady then
			resultReady = true
			warn("Timed out waiting for RemoteFunction:", functionName)
		end
	end)
	while not resultReady do
		task.wait()
	end
	return result
end

function Event:On(eventName, callback)
	if not self.events[eventName] then
		self:RegisterEvent(eventName)
	end
	return self.events[eventName].bindable.Event:Connect(callback)
end

function Event:Once(eventName, callback)
	if not self.events[eventName] then
		self:RegisterEvent(eventName)
	end
	return self.events[eventName].bindable.Event:Once(callback)
end

function Event:OnServerEvent(eventName, callback)
	if not self.isServer then
		return
	end
	if not self.events[eventName] then
		self:RegisterEvent(eventName, true)
	end
	local event = self.events[eventName]
	if not event.remote then
		return
	end
	return event.remoteEvent.OnServerEvent:Connect(function(...)
		callback(...)
	end)
end

function Event:OnClientEvent(eventName, callback)
	if self.isServer then
		return
	end
	return self:On(eventName, callback)
end

function Event:FireListeners(eventName, ...)
	local event = self.events[eventName]
	if not event then
		return
	end
	event.bindable:Fire(...)
end

function Event:Fire(eventName, ...)
	if type(eventName) ~= "string" then
		return
	end
	local event = self.events[eventName]
	if not event then
		event = self:RegisterEvent(eventName)
	end
	if event.config.debounce and event.config.debounce > 0 then
		local lastFireTime = self.debounceTimers[eventName]
		local currentTime = tick()
		if lastFireTime and (currentTime - lastFireTime) < event.config.debounce then
			return
		end
		self.debounceTimers[eventName] = currentTime
	end
	if event.config.local_only then
		self:FireListeners(eventName, ...)
		return
	end
	if self.isServer then
		local args = { ... }
		if event.remote then
			if #args > 0 and typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
				local player = table.remove(args, 1)
				event.remoteEvent:FireClient(player, table.unpack(args))
			else
				event.remoteEvent:FireAllClients(...)
			end
		end
	else
		self:FireServer(eventName, ...)
	end
	event.bindable:Fire(...)
end

function Event:FireTo(player, eventName, ...)
	if not self.isServer then
		return
	end
	if not self.events[eventName] then
		self:RegisterEvent(eventName, { server = true, client = true })
	end
	local event = self.events[eventName]
	if event.remote then
		local args = { ... }
		pcall(function()
			event.remoteEvent:FireClient(player, table.unpack(args))
		end)
	end
end

function Event:FireAllExcept(excludedPlayer, eventName, ...)
	if not self.isServer then
		return
	end
	if not self.events[eventName] then
		self:RegisterEvent(eventName, { server = true, client = true })
	end
	local event = self.events[eventName]
	if event.remote then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= excludedPlayer then
				event.remoteEvent:FireClient(player, ...)
			end
		end
	end
end

function Event:FireServer(eventName, ...)
	if self.isServer then
		return
	end
	if type(eventName) ~= "string" then
		return
	end
	local event = self.events[eventName]
	if event and event.config.local_only then
		return
	end
	if event and event.config.debounce and event.config.debounce > 0 then
		local lastFireTime = self.debounceTimers[eventName]
		if lastFireTime and (tick() - lastFireTime) < event.config.debounce then
			return
		end
		self.debounceTimers[eventName] = tick()
	end
	local args = { ... }
	local remoteEvent = self.remoteEvents[eventName] or self.eventsFolder:FindFirstChild(eventName)
	if remoteEvent then
		self.remoteEvents[eventName] = remoteEvent
		pcall(function()
			remoteEvent:FireServer(table.unpack(args))
		end)
		return
	end
	if not self.pendingEvents[eventName] then
		self.pendingEvents[eventName] = {}
	end
	table.insert(self.pendingEvents[eventName], function(evt)
		pcall(function()
			evt:FireServer(table.unpack(args))
		end)
	end)
	task.delay(0.5, function()
		if self.pendingEvents[eventName] then
			warn("Timed out waiting for RemoteEvent:", eventName)
			self.pendingEvents[eventName] = nil
		end
	end)
end

function Event:Cleanup()
	for _, connection in pairs(self.connections) do
		connection:Disconnect()
	end
	for _, event in pairs(self.events) do
		if event.bindable then
			event.bindable:Destroy()
		end
		if event.remoteEvent and self.isServer then
			event.remoteEvent:Destroy()
		end
	end
	for _, func in pairs(self.functions) do
		if func.remote and self.isServer then
			func.remote:Destroy()
		end
	end
	table.clear(self.connections)
	table.clear(self.events)
	table.clear(self.remoteEvents)
	table.clear(self.functions)
	table.clear(self.remoteFunctions)
	table.clear(self.warnedEvents)
	table.clear(self.eventConfigs)
	table.clear(self.pendingEvents)
	table.clear(self.pendingFunctions)
	table.clear(self.debounceTimers)
end

Event.Connect = Event.On
Event.FireClient = Event.FireTo
Event.Disconnect = function(connection)
	connection:Disconnect()
end

return Event
