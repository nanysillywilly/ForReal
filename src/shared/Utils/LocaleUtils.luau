local LocalizationService = game:GetService("LocalizationService")
local RunService = game:GetService("RunService")
local Signal = require("../../Packages/Signal")
local Languages = require("../Modules/Language")

local LocaleUtils = { Dicionario = nil, LanguageChanged = Signal.new() }

function LocaleUtils:GetText(key: string): string
	if RunService:IsServer() then
		warn("[Locale] Por que você está chamando isso no servidor seu maluco")
		return "[LOCALIZATION ERROR]"
	end

	if not LocaleUtils.Dicionario then
		return "[LOCALIZATION ERROR]"
	end

	local sucesso, resultado = pcall(function()
		return LocaleUtils.Dicionario:FormatByKey(key)
	end)

	if not sucesso then
		warn("[Locale] No translation for this key/locale, returning to English:", key)
		local ok, textoIngles = pcall(function()
			return LocalizationService:GetTranslatorForLocaleAsync("en-us"):FormatByKey(key)
		end)
		return ok and textoIngles or "[LOCALIZATION ERROR]"
	end

	return resultado
end

function LocaleUtils:LoadEntries(lang: string)
	task.spawn(function()
		LocaleUtils.Dicionario = LocalizationService:GetTranslatorForLocaleAsync(lang)
		LocaleUtils.LanguageChanged:Fire()
	end)
end

function LocaleUtils:GetNameByCodeID(codeID: string): string?
    for nome, dados in Languages do
        if dados.CodeID == codeID then
            return nome
        end
    end
    return nil 
end

return LocaleUtils
