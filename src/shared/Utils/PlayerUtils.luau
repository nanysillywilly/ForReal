local PlayerUtils = {}

function PlayerUtils:GetHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	return humanoid
end

function PlayerUtils:GetCollision(player: Player): Part?
	local character = player.Character
	if not character then
		return nil
	end

	local collision = character:FindFirstChild("CollisionPart")
	if not collision then
		return character.PrimaryPart
	end

	return collision
end

return PlayerUtils
