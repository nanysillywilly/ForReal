local ScreenKeyboardModule = {}

function ScreenKeyboardModule.Get(type: string?)
	if type == nil then
		local scripto: ModuleScript = script:FindFirstChild("ScreenKeyboard")
		return require(scripto)
	end

	return require(script:FindFirstChild(type))
end

return ScreenKeyboardModule
