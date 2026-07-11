local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local ModelUtils = {}

local ENABLED_TYPES = {
	["ParticleEmitter"] = true,
	["Trail"] = true,
	["Beam"] = true,
	["Fire"] = true,
	["Smoke"] = true,
	["Sparkles"] = true,
	["BillboardGui"] = true,
	["SurfaceGui"] = true,
	["PointLight"] = true,
	["SpotLight"] = true,
	["SurfaceLight"] = true,
}

local visibilityState = {}
function ModelUtils:ToggleModelVisibility(model: Model, enabled: boolean)
	if not model then
		return
	end

	if not enabled then
		if visibilityState[model] then
			return
		end

		local state = {
			transparency = {},
			enabled = {},
		}

		visibilityState[model] = state

		for _, obj in ipairs(model:GetDescendants()) do
			if obj:IsA("BasePart") or obj:IsA("Decal") or obj:IsA("Texture") then
				state.transparency[obj] = obj.Transparency
				obj.Transparency = 1
			elseif ENABLED_TYPES[obj.ClassName] then
				state.enabled[obj] = obj.Enabled
				obj.Enabled = false
			end
		end
	else
		local state = visibilityState[model]
		if not state then
			return
		end

		for obj, transparency in pairs(state.transparency) do
			if obj and obj.Parent then
				obj.Transparency = transparency
			end
		end

		for obj, wasEnabled in pairs(state.enabled) do
			if obj and obj.Parent then
				obj.Enabled = wasEnabled
			end
		end

		visibilityState[model] = nil
	end
end

function ModelUtils:ToggleMassless(model: Model, massless: boolean)
	ModelUtils:ChangePartsValue(model, { Massless = massless })
end

function ModelUtils:ToggleAnchored(model: Model, anchored: boolean)
	ModelUtils:ChangePartsValue(model, { Anchored = anchored })
end

function ModelUtils:ToggleCollision(model: Model, cancollide: boolean)
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		local attr = part:GetAttribute("_CanCollide")
		if attr == nil then
			part:SetAttribute("_CanCollide", part.CanCollide)
		end

		if cancollide and attr then
			part.CanCollide = true
			part.CanQuery = true
		else
			part.CanCollide = false
			part.CanQuery = false
		end
	end
end

function ModelUtils:ChangePartsValue(model: Model, propertyAndValues: {})
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		for property, value in propertyAndValues do
			if part[property] == nil then
				continue
			end

			part[property] = value
		end
	end
end

function ModelUtils:AnchorOnStop(model: Model, primaryPart: BasePart?)
	return Promise.new(function(resolve, _reject, onCancel)
		local cancelled = false
		onCancel(function()
			cancelled = true
		end)
		local primario: BasePart = primaryPart or model.PrimaryPart

		task.wait(2)
		while cancelled or primario.AssemblyLinearVelocity ~= Vector3.zero do
			task.wait(0)
		end

		if not cancelled then
			resolve()
		end
	end):andThen(function()
		ModelUtils:ChangePartsValue(model, { Anchored = true, CanCollide = false, CanQuery = false })
	end)
end

return ModelUtils
