local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputModule = {}

local INPUTS_PATH = ReplicatedStorage.Inputs

function InputModule.Get(context: string): {}
	local dict = {}

	local foundContext: InputContext = INPUTS_PATH:FindFirstChild(context)
	if not foundContext then
		return {}
	end

	for _, action in foundContext:GetChildren() do
		if not action:IsA("InputAction") then
			continue
		end

		dict[action.Name] = action
	end

	return dict
end

return InputModule