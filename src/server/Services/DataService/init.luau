local DataService = {}
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")

DataService.Dependencies = { "Event" }

local ProfileStore = require("../ServerPackages/ProfileStore")
local Config = require(script.Config)
local Template = require(script.Template)

-- ============================================
-- TESTING
-- ============================================

local RESET_DATA_LIST = {
	[868871214] = false,
}

-- ============================================
-- EVENTS
-- ============================================

DataService.Events = {
	Init = { validate = true },
	Save = { validate = true },
	Global = { validate = true },
}

DataService.GLOBAL_KEYS = Config.GLOBAL_KEYS

local Services
local State = { players = {}, global = {} }

function DataService:Init(services, modules)
	Services = services
	if not ProfileStore then
		return false
	end
	local Store = ProfileStore.New(Config.DATASTORE_NAME, Template)
	local GlobalStore = ProfileStore.New(Config.GLOBAL_DATASTORE_NAME)
	self._store = Store
	self._globalStore = GlobalStore
	return true
end

function DataService:Start()
	game.Players.PlayerAdded:Connect(function(player)
		self:LoadAllData(player)
	end)
	game.Players.PlayerRemoving:Connect(function(player)
		self:SaveAllData(player)
		self:ClearCache(player)
	end)
	self:SubscribeGlobal()
	return true
end

local function deepCopy(original, seen)
	seen = seen or {}
	if seen[original] then
		return nil
	end
	if type(original) ~= "table" then
		return original
	end
	if typeof(original) == "Instance" or type(original) == "userdata" or type(original) == "function" then
		return nil
	end
	seen[original] = true
	local copy = {}
	for key, value in pairs(original) do
		if key ~= "_profile" and key ~= "parent" and key ~= "children" then
			local copiedValue = deepCopy(value, seen)
			if copiedValue ~= nil then
				copy[key] = copiedValue
			end
		end
	end
	return copy
end

function DataService:CleanData(data)
	local success = pcall(function()
		HttpService:JSONEncode(data)
	end)
	if not success then
		return {}
	end
	return data
end

function DataService:GenerateId(idType: string?, length: number?): string
	if idType == "UUID" then
		return HttpService:GenerateGUID(false)
	elseif idType == "Short" then
		local id = ""
		for i = 1, Config.SHORT_ID_LENGTH do
			local p = math.random(1, #Config.SHORT_ID_ALPHABET)
			id = id .. string.sub(Config.SHORT_ID_ALPHABET, p, p)
		end
		return id
	elseif idType == "Number" then
		return tostring(math.random(1000, 999999))
	elseif idType == "Hex" then
		local id = ""
		for i = 1, length or 6 do
			local p = math.random(1, #Config.HEX_ALPHABET)
			id = id .. string.sub(Config.HEX_ALPHABET, p, p)
		end
		return id
	elseif idType == "Readable" then
		local id = ""
		for i = 1, length or 6 do
			local p = (i % 2 == 0) and math.random(1, #Config.READABLE_VOWELS)
				or math.random(1, #Config.READABLE_CONSONANTS)
			local s = (i % 2 == 0) and Config.READABLE_VOWELS or Config.READABLE_CONSONANTS
			id = id .. string.sub(s, p, p)
		end
		return id
	end
	return tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
end

function DataService:LoadAllData(player)
	if not player then
		return
	end
	local userId = tostring(player.UserId)
	State.players[userId] = {}
	local profile = self._store:StartSessionAsync(userId)
	if not profile then
		warn("Failed to load profile for player:", player.Name)
		return
	end
	profile:AddUserId(player.UserId)
	profile:Reconcile()

	local savedVersion = profile.Data.SchemaVersion
	if savedVersion ~= Template.SchemaVersion then
		warn(
			`[DataService] Schema version mismatch for {player.Name} — resetting (had={tostring(savedVersion)}, expected={tostring(
				Template.SchemaVersion
			)})`
		)
		for key, value in pairs(Template) do
			profile.Data[key] = value
		end
		profile.Data.SchemaVersion = Template.SchemaVersion
	end

	if RESET_DATA_LIST[player.UserId] then
		warn(`[DataService] Resetting data for {player.Name} ({player.UserId})`)
		for key, value in pairs(Template) do
			profile.Data[key] = value
		end
		profile.Data.SchemaVersion = Template.SchemaVersion
	end

	local cleanData = deepCopy(profile.Data)
	if not cleanData then
		warn("Failed to copy data for player:", player.Name)
		return
	end

	print(`[DataService] Loaded data for {player.Name}:`, cleanData)

	State.players[userId] = cleanData
	State.players[userId]._profile = profile

	pcall(function()
		Services.Event:Fire("Data.Init", {
			player = player,
			userId = userId,
			data = cleanData,
		})
	end)
end

function DataService:SaveAllData(player)
	if not player then
		return
	end
	local userId = tostring(player.UserId)
	if not State.players[userId] then
		return
	end
	local playerData = State.players[userId]
	if type(playerData) ~= "table" then
		return
	end
	local profile = playerData._profile
	if profile then
		profile:EndSession()
		if Services and Services.Event and Services.Event._isInitialized then
			for dataType, data in pairs(playerData) do
				if dataType ~= "_profile" then
					pcall(function()
						Services.Event:Fire("Data.Save", {
							player = player,
							userId = userId,
							data = self:CleanData(data),
							dataType = dataType,
						})
					end)
				end
			end
		end
	end
end

function DataService:GetData(userId, dataType)
	if not userId or not dataType then
		return nil
	end
	local playerCache = State.players[tostring(userId)]
	if not playerCache then
		return nil
	end
	return playerCache[dataType]
end

function DataService:SetData(userId, data, dataType)
	if not userId or not data or not dataType then
		return false
	end
	local playerCache = State.players[tostring(userId)]
	if not playerCache then
		return false
	end
	playerCache[dataType] = data
	local profile = playerCache._profile
	if
		profile
		and dataType ~= "_profile"
		and dataType ~= "profile"
		and dataType ~= "parent"
		and dataType ~= "children"
	then
		profile.Data[dataType] = data
	end
	return true
end

function DataService:UpdateData(userId, dataType, updateFunc)
	local currentData = self:GetData(userId, dataType)
	if not currentData then
		return false
	end
	local newData = updateFunc(currentData)
	if not newData then
		return false
	end
	return self:SetData(userId, newData, dataType)
end

function DataService:ClearCache(player)
	if not player then
		return
	end
	local userId = tostring(player.UserId)
	local playerData = State.players[userId]
	if playerData and playerData._profile then
		playerData._profile:EndSession()
	end
	State.players[userId] = nil
end

function DataService:GetGlobal(key)
	if not State.global then
		State.global = {}
	end
	if State.global[key] == nil then
		local globalProfile = self._globalStore:GetAsync("GLOBAL_" .. key)
		State.global[key] = (globalProfile and globalProfile.Data) or {}
	end
	return State.global[key]
end

function DataService:SetGlobal(key, data)
	if not State.global then
		State.global = {}
	end
	if type(data) == "table" then
		data.lastUpdate = os.time()
	end
	State.global[key] = data
	local globalProfile = self._globalStore:GetAsync("GLOBAL_" .. key)
	if globalProfile then
		globalProfile.Data = data
		globalProfile:SetAsync()
	else
		local newProfile = self._globalStore:StartSessionAsync("GLOBAL_" .. key)
		if newProfile then
			newProfile.Data = data
			newProfile:EndSession()
		end
	end
	Services.Event:Fire("Data.Global", { key = key, data = self:CleanData(data) })
	self:PublishGlobal(key)
	return true
end

function DataService:SubscribeGlobal()
	pcall(function()
		MessagingService:SubscribeAsync(Config.MESSAGE_TOPIC, function(message)
			if type(message) ~= "table" or type(message.Data) ~= "table" then
				return
			end
			local data = message.Data
			if not data.key or (data.serverId and data.serverId == game.JobId) then
				return
			end
			if
				State.global[data.key]
				and data.timestamp
				and State.global[data.key].lastUpdate
				and data.timestamp <= State.global[data.key].lastUpdate
			then
				return
			end
			State.global[data.key] = nil
			local freshData = self:GetGlobal(data.key)
			if freshData then
				Services.Event:Fire("Data.Global", { key = data.key, data = self:CleanData(freshData) })
			end
		end)
	end)
end

function DataService:PublishGlobal(key)
	if not State.global[key] then
		return
	end
	pcall(function()
		MessagingService:PublishAsync(Config.MESSAGE_TOPIC, { key = key, serverId = game.JobId, timestamp = os.time() })
	end)
end

function DataService:GetAllData(userId)
	local playerCache = State.players[tostring(userId)]
	if not playerCache then
		return nil
	end
	local result = {}
	for key, value in pairs(playerCache) do
		if key ~= "_profile" then
			result[key] = value
		end
	end
	return result
end

function DataService:PrintPlayerData(player: Player)
	local data = self:GetAllData(player.UserId)
	if not data then
		warn(`[DataService] No data found for {player.Name}`)
		return
	end
	print(`\n========== DATA: {player.Name} ({player.UserId}) ==========`)
	for key, value in pairs(data) do
		if type(value) == "table" then
			print(`  {key}:`)
			for k, v in pairs(value) do
				print(`    [{k}] = {tostring(v)}`)
			end
		else
			print(`  {key} = {tostring(value)}`)
		end
	end
	print("=========================================================\n")
end

function DataService:ValidateGlobal(key)
	if not self.GLOBAL_KEYS[key] then
		return nil
	end
	local globalData = self:GetGlobal(key)
	if not globalData then
		globalData = {}
		self:SetGlobal(key, globalData)
	end
	return globalData
end

return DataService
