local LocalizationService = game:GetService("LocalizationService")
local RunService = game:GetService("RunService")
local Signal = require("../../Packages/Signal")

local LocaleUtils = { Dicionario = nil, LanguageChanged = Signal.new() }

function LocaleUtils:GetText(key: string): string
	if RunService:IsServer() then
		warn("[Locale] Por que você está chamando isso no servidor seu maluco")
		return "[LOCALIZATION ERROR]"
	end

	if not LocaleUtils.Dicionario then
		return "[LOCALIZATION ERROR]"
	end

	return LocaleUtils.Dicionario:FormatByKey(key)
end

function LocaleUtils:LoadEntries(lang: string)
	task.spawn(function()
		LocaleUtils.Dicionario = LocalizationService:GetTranslatorForLocaleAsync(lang)
		LocaleUtils.LanguageChanged:Fire()
	end)
end

return LocaleUtils
