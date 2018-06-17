-- This is the class representing the possible directions ;
--   Mainly used by the Generator.

local Direction = {
	Up = Vector2.new (0, -1),
	Down = Vector2.new (0, 1),
	Left = Vector2.new (-1, 0),
	Right = Vector2.new (1, 0)
};

return Direction;