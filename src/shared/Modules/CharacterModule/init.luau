local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterModule = {}

local SUFFIX = "Character"

function CharacterModule.Get(typeName: string): {}?
	for _, charModule in script:GetChildren() do
		if string.lower(charModule.Name) == string.lower(typeName .. SUFFIX) then
			return require(charModule)
		end
	end

	return nil
end

function CharacterModule.GetPlayerModulePatch(): ModuleScript
	return ReplicatedStorage.Patchs.PlayerModule
end

return CharacterModule