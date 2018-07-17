--[[
	This is the main interface to the Grid generator. It has two main purposes:
		First, the generate function generates a new maze;
		Then, the build method can be used to build the maze.
	
	The Generate function requires three arguments:
		numRows     integer     The number of rows to have in the grid;
		numColumns  integer     The number of columns to have in the grid;
		options     dictionary  Any of the following options [OPTIONAL]:
		  StartSpace - Space - The Space to use as the starting spot for the generator.
		                       All paths will be generated from this position. If not provided,
		                         this is decided randomly
		  NumFloors - Integer - The number of floors to have in the maze.
		                          Defaults to 1.
	
	The Build method takes only a single argument:
		settings  Dictionary  Any of the following:
	 	 [ REQD ] SpaceSize  Vector3  The Size for a single space in the grid.
			                            Should be (columnSize, height, rowSize).
			
		 [ OPT ] Parent  Instance  The main object to parent the built maze to;
			                    it will be placed into a new Model within this parent.
			                    Defaults to Workspace.
		 [ OPT ] Name    String    The name to give to the main model containing the maze.
			                    Defaults to Maze
			                      
		 [ OPT ]  Offset     Vector3  The place at which to place the origin of the maze.
			                            Everything will be built from this position forward;
		                                Defaults to (0, 0, 0)
		
		 [ OPT ] Deadend  Dictionary  Any of the following:
		    [ REQD ] Model   Instance  The model to be placed at every deadend of the maze.
		    [ OPT ]  Offset  Vector3   The Offset (from the middle of the floor) to place
		                                 the model. Defaults to (0, 0, 0).
	  
	     [ OPT ] Grid  Dictionary  Alters the looks of the maze for all parts.
	       [ OPT ]  Material   The Material to be used on all parts.
	       [ OPT ]  BrickColor The BrickColor for all parts in the maze.
	       [ OPT ]  Color3     The Color of all parts in the maze.
		   [ OPT ]  Friction   The Friction to apply to parts in the grid.
	
		 [ OPT ] Floor  Dictionary  Alters the looks of floors in the maze.
	       [ OPT ]  Material   The Material to be used on all floors.
	       [ OPT ]  BrickColor The BrickColor for all floors in the maze.
	       [ OPT ]  Color3     The Color of all floors in the maze.
		   [ OPT ]  Friction   The Friction to apply to floors in the grid.
	
	     [ OPT ] Wall  Dictionary  Alters the looks of walls in the maze.
	       [ OPT ]  Material   The Material to be used on all walls.
	       [ OPT ]  BrickColor The BrickColor for all walls in the maze.
	       [ OPT ]  Color3     The Color of all walls in the maze.
		   [ OPT ]  Friction   The Friction to apply to walls in the grid.
--]]

local Grid = { };
local G    = { };

-- Dependencies
local main = script.Parent;
local objects = main.Objects;
local Generator = require (objects.Generator);
local Builder   = require (objects.Builder);

-- Defaults
local DEF_NUM_FLOORS = 1;
local DEF_BUILD_OFFSET = Vector3.new (0, 0, 0);

-- The Generate function
function G.generate (numRows, numColumns, options)
	local grid = setmetatable ({
		_numRows = numRows,
		_numColumns = numColumns,
		_numFloors  = options.NumFloors or DEF_NUM_FLOORS,
		
		_floors = { }
	}, Grid);
	
	grid:_generateFloors (options);
	assert (grid._numFloors >= 1, "Could not generate a valid grid.");
	
	return grid;
end

-- ** Public Methods ** --
-- The Build method
function Grid:build (settings)
	self:_build (settings);
end

-- ** Private Methods ** --

-- Generator
function Grid:_generateFloors (options)
	local _generate = function (floor, isRoof)
		options.isRoof = isRoof;
		local grid = self:_generateFloor (floor, options)
		
		-- Possible error case: Couldn't generate a valid grid
		if (not grid) then
			self._numFloors = floor - 1;
			return false;
		end
		
		self._floors [floor] = grid;
		
		self:_setPreviousFloor (options, grid);
		return true;
	end
	
	for floor = 1,self._numFloors do
		if (not _generate (floor, false)) then
			break;
		end
	end
	
	local result = _generate (self._numFloors + 1, true);
	print ("Generator completed with ", self._numFloors, " floors")
end
function Grid:_generateFloor (floorNum, options)
	local grid;
	
	-- Try to generate the grid
	-- If it throws an error, just return nil
	pcall (function ()
		grid = Generator.generate (self._numRows, self._numColumns, options);
	end)
	
	return grid;
end
function Grid:_setPreviousFloor (optionsDict, previousFloor)
	optionsDict.IsBottomFloor = false;
	optionsDict.StartSpace = previousFloor:getEndSpace ();
	optionsDict.Direction = previousFloor:getExitDirection ();
end

-- Builder
function Grid:_build (settings)
	if (not settings.Offset) then settings.Offset = DEF_BUILD_OFFSET; end
	
	for floorNum = 1,self._numFloors do
		settings.FloorNumber = floorNum;
		Builder.build (self._floors [floorNum], settings);
		
		-- Build the next floor on top
		settings.Offset = settings.Offset + Vector3.new (0, settings.SpaceSize.Y, 0);
	end
	
	settings.isRoof = true;
	Builder.build (self._floors [self._numFloors + 1], settings);
end

-- ** Metamethods ** --
function Grid:__tostring ()
	print ("The grid ends at ", self._grid:getEndSpace ());

	return tostring (self._grid);
end

Grid.__index = Grid;
return G;