local TweenService = game:GetService("TweenService")
local LuaUtils = require("../../../Utils/LuaUtils")
local ScreenKeyboardState = require("./ScreenKeyboardState")

local KeyboardClosed = LuaUtils:extends(ScreenKeyboardState)
KeyboardClosed.__index = KeyboardClosed

function KeyboardClosed.new(Keyboard: {})
	local self = ScreenKeyboardState.new(Keyboard)
	setmetatable(self, KeyboardClosed)
	return self
end

-- Jarona State Methods
function KeyboardClosed:Start()
	ScreenKeyboardState.Start(self)

	local tweenLower = TweenService:Create(
		self.Keyboard.GUI.Tudo,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5, 1.402) }
	)
	tweenLower:Play()

	local spinButton = TweenService:Create(
		self.Keyboard.Joana,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Rotation = 180 }
	)
	spinButton:Play()

	self:Connect(self.Keyboard.Joana.MouseButton1Click:Once(function()
		self.Keyboard:ChangeState("KeyboardOpened")
	end))
end

function KeyboardClosed:Update(deltaTime: number)
	ScreenKeyboardState.Update(self, deltaTime)
end

function KeyboardClosed:Exit()
	ScreenKeyboardState.Exit(self)
end
--

return KeyboardClosed
