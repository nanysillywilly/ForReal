local TweenService = game:GetService("TweenService")
local LuaUtils = require("../../../Utils/LuaUtils")
local ScreenKeyboardState = require("./ScreenKeyboardState")

local KeyboardOpened = LuaUtils:extends(ScreenKeyboardState)
KeyboardOpened.__index = KeyboardOpened

function KeyboardOpened.new(Keyboard: {})
	local self = ScreenKeyboardState.new(Keyboard)
	setmetatable(self, KeyboardOpened)
	return self
end

-- Jarona State Methods
function KeyboardOpened:Start()
	ScreenKeyboardState.Start(self)

	local tweenOpen = TweenService:Create(
		self.Keyboard.GUI.Tudo,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5, 1) }
	)
	tweenOpen:Play()

	local spinButton = TweenService:Create(
		self.Keyboard.Joana,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Rotation = 0 }
	)
	spinButton:Play()

	self:Connect(self.Keyboard.Joana.MouseButton1Click:Once(function()
		self.Keyboard:ChangeState("KeyboardClosed")
	end))
end

function KeyboardOpened:Update(deltaTime: number)
	ScreenKeyboardState.Update(self, deltaTime)
end

function KeyboardOpened:Exit()
	ScreenKeyboardState.Exit(self)
end
--

return KeyboardOpened
