local Workspace = game:GetService("Workspace")

local WorkspaceUtils = {}

function WorkspaceUtils:FindOrCreateFolder(name: string): Folder
	local found = Workspace:FindFirstChild(name)

	if not found then
		found = Instance.new("Folder")
		found.Parent = workspace
		found.Name = name
		return found
	end

	return found
end

function WorkspaceUtils:FindOrCreate(name: string, type: string)
	local found = Workspace:FindFirstChild(name)

	if not found or not found:IsA(type) then
		found = Instance.new(type)
		found.Parent = workspace
		found.Name = name
		return found
	end

	return found
end

return WorkspaceUtils
