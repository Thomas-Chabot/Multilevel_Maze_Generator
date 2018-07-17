--[[
	This provides the main logic to generating the grid,
	  keeping it separate from the rest of the Generator.
	
	The constructor takes a single element - the Grid object.

	There is a single available method:
		generate ()
			Purpose: Generates the grid.
			Returns: Nothing ; however, the grid object will have many paths -
			          floors available throughout the grid.
			NOTE: The StartSpace must be set in the Grid when generate is fired;
			        if it is not, this will fire an error.
--]]

local GenHelper = { };
local GH        = { };

-- The main hierarchy
local generator = script.Parent;
local objects = generator.Parent;
local main    = objects.Parent;
local classes = main.Classes;

-- Dependencies
local Grid  = require (classes.Grid);
local Space = require (classes.Space);
local SpaceType = require (classes.SpaceType);
local Direction = require (classes.Direction);

local Array    = require (objects.Array);

-- The possible directions that can be taken
local directions = {Direction.Up, Direction.Down, Direction.Left, Direction.Right};
      directions = Array.new (directions);

-- ** Constants ** --
local MIN_EXIT_COLS  = 2;
local MIN_EXIT_ROWS  = 2;
local MIN_EXIT_SPACE = Space.new (MIN_EXIT_COLS, MIN_EXIT_ROWS);

local MAX_REGEN_COUNT = 10;

-- ** Constructor ** --
function GH.new (grid)
	return setmetatable ({
		_grid = grid,
		
		_isRoof = nil,
		
		_deadends = Array.new (),
		
		_minDeadend = MIN_EXIT_SPACE,
		_maxDeadend = Space.new (grid:numColumns() - MIN_EXIT_COLS + 1, grid:numRows() - MIN_EXIT_ROWS + 1)
	}, GenHelper);
end

-- ** Public Methods ** --
function GenHelper:generate (isRoof)
	self._isRoof = isRoof;
	
	local start = self._grid:getStartSpace ();
	self._start = start;
	
	self:_regenerate ();
end

-- ** Private Methods ** --
function GenHelper:_regenerate (counter)
	if (not counter) then counter = 0; end
	assert (counter < MAX_REGEN_COUNT, "Could not create a valid grid.");
	
	local start = self._start;
	
	local success = pcall (function ()
		self:_generateRecursive (start);
		self:_setGridEnd ();
	end)
	
	if (not success) then
		print ("The failed grid is ", self._grid);
		print ("Failed to find an exit ... Regenerating");
		print ("Start space is ", self._start)
		
		self._grid:reset ();
		print ("After resetting: ", self._grid)
		self:_regenerate (counter + 1);
	end
end

-- The recursive generator function
function GenHelper:_generateRecursive (position)
	local grid = self._grid;
	
	-- Make sure the spot hasn't been taken already
	if (not self:_isEmpty (position)) then return end
	self:_setSpace (position, SpaceType.Floor);
	
	-- Randomly traverse over the directions
	-- & Proceed to turn them into the floor spaces
	local dirs  = self:_getDirections ();
	self:_traverse (position, dirs);
end

-- Traverses through a given set of directions from a starting position
--  to create new paths
function GenHelper:_traverse (position, directions)
	local pathFound = self:_isStart (position);
	directions:each (function (direction)
		if (self:_check (position, direction)) then
			pathFound = true;
		end
	end)
	
	if (not pathFound) then
		self:_deadend (position);
	end
end

-- Check if a path can be started from a given position going in a given direction;
--   If it can, creates the path and returns true;
--   If not, returns false.
function GenHelper:_check (position, direction)
	local grid = self._grid;
	
	-- Want to ensure everything has a wall between it ...
	-- If moving twice will break into a previous path -> do not move
	local nextSpot  = position + direction;
	local checkSpot = nextSpot + direction;
	
	if (not self:_isEmpty (nextSpot)) then return false end
	if (not self:_isEmpty (checkSpot)) then return false end
	
	self:_setSpace (nextSpot, SpaceType.Floor);
	self:_generateRecursive (checkSpot);
	
	return true;
end

-- Set the space type at a given position
function GenHelper:_setSpace (position, spaceType)
	self._grid:setSpaceType (position, spaceType);
end
-- Check if a given position has been used already
function GenHelper:_isEmpty (position)
	local spaceType = self._grid:getSpaceType (position);
	return spaceType == SpaceType.Wall or spaceType == SpaceType.Start;
end
function GenHelper:_isStart (position)
	return position == self._start;
end

-- Returns the directions in a random order
function GenHelper:_getDirections ()
	return directions:randomized ();
end

-- Dead ends
function GenHelper:_deadend (position)
	self:_setSpace (position, SpaceType.Deadend);
	
	-- only add the position as possible exit if it's within the borders,
	-- meaning a start space can be placed for the next floor
	local direction = self._grid:getExitDirection (position)
	local nextPos   = position + direction;
	local validCheck = (nextPos >= self._minDeadend and nextPos <= self._maxDeadend);
	
	print ("Deadend added at ", position)
	
	if (validCheck) then
		print ("Valid position at ", position)
		self._deadends:add (position);
	end
end

-- End of the grid
function GenHelper:_setGridEnd ()
	if (self._isRoof) then
		self._grid:setEndSpace (Space.new (1, 1))
		return;
	end
	
	print (self._deadends);
	
	local endPos = self._deadends:random ();
	assert (endPos, "could not find a valid exit");
	
	self._grid:setEndSpace (endPos);
end


GenHelper.__index = GenHelper;
return GH;