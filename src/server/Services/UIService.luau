local UIService = {}

local Services
local _Modules

UIService.Dependencies = { "Event", "Data" }
UIService.Events = {
	LoadedSettings = {
		validate = true,
		client = true,
		server = false,
		schema = {
			data = "table",
		},
	},
	ChangeSetting = {
		validate = true,
		client = false,
		server = true,
		schema = {
			id = "string",
			newValue = "any",
		},
	},
}
UIService.Listeners = {
	["Data.Init"] = function(self, cleanData)
		self:SetData(cleanData)
	end,
	["UI.ChangeSetting"] = function(self, player, data)
		local id = data.id
		local newValue = data.newValue
		Services.Data:SetData(player.UserId, newValue, id)
	end,
}

function UIService:Init(services, modules)
	Services = services
	_Modules = modules
	return true
end

function UIService:Start()
	return true
end

function UIService:SetData(allData)
	if self.CurrentSave then
		return
	end

	local cleanedData = allData.data
	local player: Player = allData.player
	if cleanedData.Language == "" or cleanedData.Language == nil then
		cleanedData.Language = player.LocaleId
		Services.Data:SetData(player.UserId, player.LocaleId, "Language")
	end

	Services.Event:FireClient(player, "UI.LoadedSettings", { data = cleanedData })
end

return UIService
