--[[
	Represents a single type at a given space in the grid.
	  The type can be either:
	    Floor   - This is a space players may walk on;
	    Wall    - This is a barrier in the maze;
	    Deadend - Same as a floor, but may be used for extra features in the maze
	                (walk to a dead end & something happens, for example)
	
	Also has a single metamethod. This converts a SpaceType into a stringified version.
--]]

local SpaceType = {
	None = 0,
	
	Floor   = 1,
	Wall    = 2,
	Deadend = 3,
	
	Start   = 4,
	End     = 5
};

SpaceType.Default = SpaceType.Wall; -- Spaces that have not been specified

function SpaceType.string (t)
	if (t == SpaceType.None) then return "" end
	if (t == SpaceType.Floor) then return " _ " end
	if (t == SpaceType.Wall) then return " # " end
	if (t == SpaceType.Start) then return " S " end
	if (t == SpaceType.End) then return " E " end
	
	return " D ";
end

function SpaceType.__tostring (self)
	return SpaceType.string (self);
end

return SpaceType;