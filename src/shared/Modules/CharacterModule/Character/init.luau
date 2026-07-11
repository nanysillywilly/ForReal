local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerExecutorController = require("../../Controllers/Executors/ServerExecutorController")
local InputModule = require("../InputModule")
local Promise = require(ReplicatedStorage.Packages.Promise)

local Character = {}
Character.__index = Character
Character.script = script
Character.ModuleName = script.Name

Character.CURRENT_STATE = nil

Character.OnServer = {
	LoadCharacter = function(player: Player, data)
		local HumanoidDescription
		if data.loadAppearance and player.UserId > 0 then
			HumanoidDescription = Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
		end

		player.CharacterAdded:Once(function(char)
			if data.initialPosition then
				char:PivotTo(CFrame.new(data.initialPosition))
			end

			for _, descendant in char:GetDescendants() do
				if descendant:IsA("Sound") then
					descendant:Destroy()
					continue
				end

				if not descendant:IsA("BasePart") then
					continue
				end

				local isAccessory = descendant.Parent and descendant.Parent:IsA("Accessory")
				if not isAccessory then
					descendant.CanQuery = true
				else
					descendant.CanCollide = false
					descendant.CanQuery = false
					descendant.CanTouch = false
				end

				descendant.CollisionGroup = "Players"
			end
		end)

		player:LoadCharacterWithHumanoidDescriptionAsync(
			HumanoidDescription and HumanoidDescription or Instance.new("HumanoidDescription")
		)
	end,
	UnloadCharacter = function(player: Player, data)
		local character = player.Character

		if character then
			character:Destroy()
		end
	end,
}

function Character.new(args: {}?)
	local self = setmetatable({}, Character)

	if args then
		for property, value in args do
			self[property] = value
		end
	end

	self:_Init()
	return self
end

-- Functions --

--[[
    Destroys the Character Controller
]]
function Character:Destroy(callback)
	if self._cleaning then
		return
	end

	self:Cleanup()

	print("[Character] Character destroyed successfully!")
	if callback then
		callback()
	end
end

--[[
	Kills the character
]]
function Character:Kill()
	if not self._initialized then
		return
	end

	self.Humanoid:TakeDamage(9999)
end

--[[
	Changes Character Controller State
]]
function Character:ChangeState(newState: string, args: {}?)
	-- Don't change state if it is already no que precisa estar
	--[[if self.CURRENT_STATE and self.CURRENT_STATE.Name == newState then
		return
	end]]

	local newStateRequire = self.script:FindFirstChild(newState)
	if not newStateRequire then
		warn("[Character] Can't change CharacterController to state " .. newState .. ", it does not exist!")
		return
	end
	newStateRequire = require(newStateRequire)

	self:ExitState()
	local newStateInstance = newStateRequire.new(self, args or {})
	newStateInstance:Start()
	self.CURRENT_STATE = { Name = newState, Instance = newStateInstance }
	self:OnStateChanged(newStateInstance)
end

--[[
	Exit the current state
]]
function Character:ExitState()
	if not (self.CURRENT_STATE and self.CURRENT_STATE.Instance) then
		return
	end

	local oldState = self.CURRENT_STATE and self.CURRENT_STATE.Instance
	if oldState then
		oldState:Exit()
		self.CURRENT_STATE = nil
	end
end

--

-- Events --

--[[
	Is called when the Controller is ready
]]
function Character:Start()
	if not self._initialized then
		return
	end
end

--[[
	Called on every RenderStepped frame
]]
function Character:Update(deltaTime: number)
	if not self._initialized then
		return
	end

	if self.CURRENT_STATE then
		self.CURRENT_STATE.Instance:Update(deltaTime)
	end
end

--[[
	Is called when player destroys the Controller
]]
function Character:Cleanup()
	if self._cleaning then
		return
	end
	self._cleaning = true

	self:ExitState()
	self:ToggleShiftLock(false)

	if self._promises then
		for _, promise in self._promises do
			if not promise then
				continue
			end

			promise:cancel()
		end
	end

	if self._connections then
		for _, conn in self._connections do
			if not conn then
				continue
			end

			conn:Disconnect()
		end
	end

	ServerExecutorController:Exec(self, "UnloadCharacter")
	self._cleaning = false
end

--[[
	Is called when the player Humanoid dies
]]
function Character:OnDeath()
	self.Controller:ChangeController(self.Type, nil, true)
end

--[[
	Called when the character Root Part collides with something (client-sided)
]]
function Character:OnTouchClient(otherPart: BasePart)
	if self.CURRENT_STATE ~= nil then
		self.CURRENT_STATE.Instance:OnTouchClient(otherPart)
	end
end

--[[
	Called when the state changes, it sends the new state instance
]]
function Character:OnStateChanged(newStateInstance)
	if not self.InputContext then
		return
	end

	local inputActions = InputModule.Get(self.InputContext)
	if not inputActions then
		return
	end

	if not newStateInstance.Connect then
		return
	end
	for _, action in inputActions do
		if newStateInstance.OnActionPressed ~= nil then
			newStateInstance:Connect(action.Pressed:Connect(function()
				newStateInstance:OnActionPressed(action.Name)
			end))
		end

		if newStateInstance.OnActionReleased ~= nil then
			newStateInstance:Connect(action.Released:Connect(function()
				newStateInstance:OnActionReleased(action.Name)
			end))
		end
	end
end

-- Internal --

--[[
    Initializes the Character Controller
]]
function Character:_Init()
	if self._initialized then
		return
	end

	print("[Character] Initializing character '" .. (self.Type and self.Type or "Default") .. "' for localplayer!")
	task.wait(0.25)
	self._initialized = false
	self:Promise(Promise.new(function(resolve, reject)
		local loadAppearance = self.LoadAppearence == nil and true or self.LoadAppearence
		ServerExecutorController:Exec(
			self,
			"LoadCharacter",
			{ loadAppearance = loadAppearance, initialPosition = self.InitialPosition }
		)

		-- Waits for character to be added
		local char = (Players.LocalPlayer.Character and Players.LocalPlayer.Character:IsDescendantOf(game.Workspace))
				and Players.LocalPlayer.Character
			or nil
		while char == nil do
			task.wait(0)
			char = (Players.LocalPlayer.Character and Players.LocalPlayer.Character:IsDescendantOf(game.Workspace))
					and Players.LocalPlayer.Character
				or nil
		end

		resolve(char)
	end)
		:andThen(function(char)
			-- initializes vars
			self.Model = char
			self.RootPart = char:WaitForChild("HumanoidRootPart")
			self.RootPart.Anchored = true
			self.Humanoid = char:WaitForChild("Humanoid")
			self.Player = Players.LocalPlayer
			self.Player:SetAttribute("Prompts_CanInteract", false)

			local collisionPart: BasePart = char:WaitForChild("CollisionPart")
			if not collisionPart then
				return
			end
			self.Collision = collisionPart

			-- Setup Humanoid
			self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
			self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			self.Humanoid.AutoJumpEnabled = false
			self.Humanoid.BreakJointsOnDeath = false
			self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			self.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

			-- make essential connections
			self:Connect(self.Model.Destroying:Connect(function()
				self:Destroy()
			end))
			self:Connect(self.Humanoid.Died:Connect(function()
				self:OnDeath()
			end))
			self:Connect(self.RootPart.Touched:Connect(function(otherPart: BasePart)
				self:OnTouchClient(otherPart)
			end))
			self:Connect(RunService.RenderStepped:Connect(function(deltaTime)
				self:Update(deltaTime)
			end))

			self:_SetupAnimator()
			self:_SetupSounds()

			self.RootPart.Anchored = false

			-- Call Initialization Event
			self._initialized = true
			self:Start()

			print("[Character] Character initialized successfully!")
		end)
		:catch(function(err)
			warn(err)
		end))
end

function Character:_SetupAnimator()
	-- Destroy default animate and stops all animations
	--[[local animateScript = self.Model:FindFirstChild("Animate")
	if animateScript then
		animateScript:Destroy()
	end

	local humanoid = self.Model:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end]]
	--

	--[[local defaultAnimations = AnimationModule.GetAll(self.DefaultAnimations and self.DefaultAnimations or "DefaultR15")
	if not defaultAnimations then
		warn("[Character] Can't initialize AnimateController, default animations are invalid!")
		return
	end

	local formatted = AnimationModule.FormatToAnimate(defaultAnimations)

	local animateParams = self.AnimateParams and self.AnimateParams or defaultAnimations
	local defaultParams = {
		ApplyRigScale = false,
		SprintDetectSpeed = 24,
		SprintSpeedDividend = 16,
		RunDetectSpeed = 14,
		RunSpeedDividend = 12,
		WalkSpeedDividend = 8,
		JumpDuration = 0.3,
		ClimbSpeedDividend = 12,
		SwimSpeedDividend = 16,
		LandedDuration = 0.6,
	}

	for property, value in defaultParams do
		if animateParams[property] ~= nil then
			continue
		end

		animateParams[property] = value
	end

	self.AnimateController = AnimateController.new(self.Model, formatted, animateParams)
	self.AnimateController:Load()]]
end

function Character:_SetupSounds()
	local soundsScript = self.Player.PlayerScripts:FindFirstChild("RbxCharacterSounds")
	if soundsScript then
		soundsScript:Destroy()
	end

	for _, sound in self.RootPart:GetChildren() do
		if not sound:IsA("Sound") then
			continue
		end

		sound:Destroy()
	end
end

function Character:Connect(connection)
	if not self._connections then
		self._connections = {}
	end

	if not connection then
		return
	end

	table.insert(self._connections, connection)
end

function Character:Promise(promise)
	if not self._promises then
		self._promises = {}
	end

	if not promise then
		return
	end

	table.insert(self._promises, promise)
end

--

return Character
