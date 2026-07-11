local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterState = require("./CharacterState")
local LuaUtils = require(ReplicatedStorage.Modules.Utils.LuaUtils)

local CharDialogue = LuaUtils:extends(CharacterState)
CharDialogue.__index = CharDialogue

function CharDialogue.new(character)
	local self = CharacterState.new(character)
	setmetatable(self, CharDialogue)
	return self
end

-- State Functions --
function CharDialogue:Start()
	CharacterState.Start(self)
end

function CharDialogue:Update(deltaTime)
	CharacterState.Update(self, deltaTime)
end

function CharDialogue:Exit()
	CharacterState.Exit(self)
end
--

return CharDialogue
