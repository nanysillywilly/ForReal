local LuaUtils = {}

function LuaUtils:extends(Base)
	local Class = setmetatable({}, { __index = Base })
	Class.__index = Class
	return Class
end

function LuaUtils:switch(element)
	local Table = {
		["Value"] = element,
		["DefaultFunction"] = nil,
		["Functions"] = {},
	}

	Table.case = function(testElement, callback)
		Table.Functions[testElement] = callback
		return Table
	end

	Table.default = function(callback)
		Table.DefaultFunction = callback
		return Table
	end

	Table.process = function()
		local Case = Table.Functions[Table.Value]
		if Case then
			Case()
		elseif Table.DefaultFunction then
			Table.DefaultFunction()
		end
	end

	return Table
end

function LuaUtils:CompareFloat(a: number, b: number, tolerance: number): boolean
	return math.abs(a - b) <= tolerance
end

function LuaUtils:CompareCFrames(cf1: CFrame, cf2: CFrame): number
	local posDiff = (cf1.Position - cf2.Position).Magnitude
	local _, _, _, r00, _r01, _r02, _r10, r11, _r12, _r20, _r21, r22 = (cf1:ToObjectSpace(cf2)):GetComponents()
	local trace = r00 + r11 + r22
	local angle = math.acos(math.clamp((trace - 1) / 2, -1, 1))

	local POSITION_WEIGHT = 1
	local ROTATION_WEIGHT = 1

	return (posDiff * POSITION_WEIGHT) + (angle * ROTATION_WEIGHT)
end

function LuaUtils:CollectArgs(table, args)
	for property, value in args do
		table[property] = value
	end
end

function LuaUtils:deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = LuaUtils:deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

return LuaUtils
