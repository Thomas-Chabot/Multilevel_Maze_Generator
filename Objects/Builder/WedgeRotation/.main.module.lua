-- This rotates the exit wedge so that it can be correctly applied
--  to the main maze.

-- ** Structure ** --
local builder = script.Parent;
local objects = builder.Parent;
local main    = objects.Parent;
local classes = main.Classes;

-- ** Dependencies ** --
local Direction = require (classes.Direction);

-- ** Global Variables ** --

-- The table of rotations to apply. These depend on the position of the exit
--  along with the corresponding entry point.
local rotations = {
	[Direction.Right] = Vector3.new (0, 90, 0),
	[Direction.Left] = Vector3.new (0, -90, 0),
	[Direction.Up] = Vector3.new (0, -180, 0),
	[Direction.Down] = Vector3.new (0, 0, 0)
}

-- ** Main Function ** --
function rotateWedge (grid, exitPosition, exitWedge)
	local direction = grid:getExitDirection ();
	local rotation = getRotation (direction);
	exitWedge.Orientation = rotation;
end

-- ** Helper Functions ** --
function getRotation (direction)
	return rotations [direction] or rotations [Direction.Right];
end

return rotateWedge;