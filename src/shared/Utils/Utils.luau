local Utils = {}

function Utils.sameTypeGatherer(folder)
	local route = {}
	for _, obj in ipairs(folder:GetChildren()) do
		obj.Anchored = true

		route[tonumber(string.match(obj.Name, "%d+"))] = obj.Position
	end
	return route
end

function Utils.reached(currentWaypoint, chosenRouteWaypoints, humanoid)
	currentWaypoint += 1

	if currentWaypoint <= #chosenRouteWaypoints then
		humanoid:MoveTo(chosenRouteWaypoints[currentWaypoint])
	end

	return currentWaypoint
end

return Utils
