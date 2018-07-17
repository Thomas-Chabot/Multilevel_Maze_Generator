--[[
	This is the main generator for the grid. It handles building a grid made up of
	 some number of columns & some number of rows, along with a few extra options.

	Generator takes three arguments:
	  numRows - Integer - The number of rows to have in the grid
	  numCols - Integer - The number of columns to have in the grid
	  options - Dictionary - Various options from the following (OPTIONAL):
	    StartSpace - Space - The Space to use as the starting spot for the generator.
	                         All paths will be generated from this position. If not provided,
	                          this is decided randomly
	    IsBottomFloor - Boolean - Indicates that this floor is the bottom;
	                                If so, the start will be a spawn;
	                                otherwise, start will be empty.
	    Direction - Direction - The direction of the previous exit.
	                             Must be given if IsBottomFloor is false.
	
	This returns a new Grid object representing the generated grid.
	
	SEEALSO: Generator -> Classes -> Grid for the Grid object
--]]

local Generator = { };
local G         = { };

local objects = script.Parent;
local main    = objects.Parent;
local classes = main.Classes;

-- Dependencies
local Grid  = require (classes.Grid);
local Space = require (classes.Space);
local SpaceType = require (classes.SpaceType);
local GenHelper = require (script.GeneratorHelper);

-- ** Constructor ** --
function G.generate (numRows, numColumns, options)
	if (not options) then options = { } end
	
	if (numRows % 2 == 0) then numRows = numRows + 1; end
	if (numColumns % 2 == 0) then numColumns = numColumns + 1; end
	
	local generator = setmetatable ({
		_nr = numRows,
		_nc = numColumns,
		
		_start = options.StartSpace,
		_isRoof = options.isRoof,
		
		_grid = Grid.new (numRows, numColumns),
		_helper = nil
	}, Generator);
	
	generator:_init (options.IsBottomFloor, options.Direction);
	
	return generator:getGrid ();
end

-- ** Public Methods ** --
function Generator:getGrid ()
	return self._grid;
end

-- ** Private Methods ** --
-- Initialization
function Generator:_init (isBottom, direction)
	self:_initStartSpace (isBottom, direction);
	self:_setupHelper ();
	self:_generate ();
end

-- Start Space
function Generator:_initStartSpace (isBottom, direction)
	local startSpace = self:_generateStartSpace ();
	
	if (isBottom == false) then
		-- Make sure that in case the grid has to be reset,
		-- The two start spaces won't be altered
		self._grid:setResettable (startSpace, false);
		self._grid:setResettable (startSpace + direction, false);		
		
		-- Now set up the start
		self._grid:setSpaceType (startSpace, SpaceType.None);
		self._grid:setSpaceType (startSpace + direction, SpaceType.Floor);
		startSpace = startSpace + direction + direction;
	end
	
	self._grid:setStartSpace (startSpace);
end
function Generator:_generateStartSpace ()
	if (self._start) then
		-- If it's already a Space
		if (typeof (self._start) ~= "Vector2") then
			return self._start;
		end		
		
		-- Convert it into a Space
		return Space.new (self._start)
	end

	-- This is 2 to nr - 1 because there must be a border on all sides;
	-- same with nc
	local possibleRows = Vector2.new (1, self._nr);
	local possibleCols = Vector2.new (1, self._nc);
	
	-- Initialize the random space
	local space = Space.random (possibleRows, possibleCols);
	return space;
end

-- Helper
function Generator:_setupHelper ()
	self._helper = GenHelper.new (self._grid);
end

-- Main generator
function Generator:_generate ()
	self._helper:generate (self._isRoof);
end

Generator.__index = Generator;
return G;