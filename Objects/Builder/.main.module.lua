--[[
	Options:
		Parent   -> Instance
		Name     -> String    Indicates Name of main model
		SpaceSize -> Vector3
		Offset   -> Vector3
		
		Deadend:
			Model  -> Model
			Offset -> Vector3
			
			Note: Automatically set to middle of floor.
		
		- EITHER -
		Grid:
			Material -> Enum.Material
			Color3   -> Color3
			BrickColor -> BrickColor
		
		- OR -
		
		Floor:
			Material -> Enum.Material
			Color3   -> Color3
			BrickColor -> BrickColor
			
		Wall:
			Material -> Enum.Material
			Color3   -> Color3
			BrickColor -> BrickColor
		
		
	
	Builder:
		- Takes Grid, set of options
		-> Creates Base Floor, Wall parts - built from size, material, Color3 settings
		-> For every part in the grid:
			  If Wall: Build Wall
			  If Floor: Build Floor
			  If Deadend: Build DeadendPart
		
--]]
local Builder = { };
local B       = { };

-- ** Default Values ** --
local DEF_OFFSET = Vector3.new (0, 0, 0) -- Default to the origin
local DEF_PART_OFFSET = Vector3.new (0, 0, 0) -- Offset for a model vs. floor

-- ** Structure ** --
local objects = script.Parent;
local main    = objects.Parent;
local classes = main.Classes;

-- ** Dependencies ** --
local Grid    = require (classes.Grid);
local Space3D = require (classes.Space3D);
local Space   = require (classes.Space);
local SpaceType = require (classes.SpaceType);
local fixExitRotation = require (script.WedgeRotation);


-- ** Global Functions ** --
function reposition (object, position, offset)
	if (not offset) then offset = Vector3.new (0, 0, 0) end
	
	-- Try to get a part
	local pPart = object;
	if (object:IsA("Model")) then pPart = object.PrimaryPart; end
	
	-- If we have one => Can set part's CFrame
	-- Otherwise, just use :MoveTo() of the model
	if (pPart) then
		pPart.CFrame = CFrame.new (position) + offset;
	else
		object:MoveTo (position + offset);
	end
end

-- Merges two dictionaries into one
function merge (dict1, dict2)
	if (not dict1) then return dict2; end
	if (not dict2) then return dict1; end
	
	-- If an option exists in dict2 but not in dict1, set the value
	-- Otherwise, we ignore the value of dict2 as dict1 takes precedence
	for option,value in pairs (dict2) do
		if (not dict1 [option]) then
			dict1 [option] = value;
		end
	end
	
	return dict1;
end

-- ** Static Functions ** --
local parts = script.Parts;
local floor = parts.Floor;
local wall  = parts.Wall;
local mazeSpawn = parts.Spawn;
local exitWedge = parts.ExitWedge;

function B._wall (settings)
	local wallSettings = merge (settings.Wall, settings.Grid);
	return B._create (wall, settings, wallSettings);
end
function B._floor (settings)
	local floorSettings = merge (settings.Floor, settings.Grid);
	local newFloor = B._create (floor, settings, floorSettings);
	
	-- Resize the floor - should be only Y = 1 (allowing players to walk on it)
	newFloor.Size = Vector3.new (newFloor.Size.X, 1, newFloor.Size.Z);
	return newFloor;
end
function B._spawn (settings)
	-- Note - Special case - If it's not the bottom floor, just put in a floor
	if (settings.FloorNumber ~= 1) then
		return B._floor (settings);
	end
	
	local newSpawn = B._create (mazeSpawn, settings, settings.Grid);
	
	-- Resize the spawn - same as floor
	newSpawn.Size = Vector3.new (newSpawn.Size.X, 1, newSpawn.Size.Z);
	return newSpawn;
end
function B._exit (settings)
	-- No special settings - just the wedge
	return B._create (exitWedge, settings, settings.Grid);
end
function B._deadend (floor, settings)
	-- Easiest case: If no deadend, just use the floor
	if (not settings.Deadend) then return floor:Clone (); end
	
	-- Trickier case: combine the floor & deadend model
	local mainModel = Instance.new ("Model");
	local newFloor  = floor:Clone ();
	local dendModel = settings.Deadend.Model;
	local dendOffset = settings.Deadend.Offset or Vector3.new (0, 0, 0);
	
	assert (dendModel, "Deadend Model must be provided for the deadend");
	
	-- Position the model with the floor & given offset
	reposition (dendModel, newFloor.Position + dendOffset);
	
	-- Add both the deadend model & the floor to the main model
	-- To be treated as one
	dendModel.Parent = mainModel;
	newFloor.Parent  = mainModel;

	-- Set the floor as the primary part - this is what we want to position
	--  in the builder
	mainModel.Parent = newFloor;
	
	return mainModel;
end

function B._create (defPart, settings, mainSettings)
	if (not mainSettings) then mainSettings = { }; end
	
	local newPart = defPart:Clone ();
	if (not settings) then return newPart; end
	
	newPart.Size = settings.SpaceSize;
	if (mainSettings.Material) then newPart.Material = mainSettings.Material; end
	if (mainSettings.Color3) then newPart.Color3 = mainSettings.Color3; end
	if (mainSettings.BrickColor) then newPart.BrickColor = mainSettings.BrickColor; end
	if (mainSettings.Friction) then newPart.Friction = mainSettings.Friction; end
	
	return newPart;
end

-- ** Constructor ** --
function B.build (grid, settings)
	assert (settings, "Settings are required to start the builder.");
	
	-- Apply Defaults
	if (not settings.Offset) then settings.Offset = DEF_OFFSET; end
	
	-- Create the parts
	local wallPart  = B._wall (settings);
	local floorPart = B._floor (settings);
	local deadendMdl = B._deadend (floorPart, settings);
	local mazeSpawn  = B._spawn (settings);
	local exitWedge  = B._exit (settings);

	local mainModel  = Instance.new ("Model");
	mainModel.Name   = settings.Name or "Maze_Floor" .. settings.FloorNumber;
	mainModel.Parent = settings.Parent or workspace;
	
	-- Create the main object class
	local builder = setmetatable ({
		_grid  = grid,
		
		_parts = {
			wall = wallPart,
			floor = floorPart,
			deadEnd = deadendMdl,
			start = mazeSpawn,
			exit = exitWedge
		},
		
		_size   = settings.SpaceSize,
		_offset = settings.Offset,
		_parent = mainModel
	}, Builder);
	
	-- Set static variables
	Space3D.Offset = settings.Offset;
	
	-- Build the maze
	builder:_build ();
	return builder;
end

-- ** Builder / Private Methods ** --
-- Main
function Builder:_build ()
	local grid  = self._grid;
	local nCols = grid:numColumns ();
	local nRows = grid:numRows ();
	
	for row = 1, nRows do
		for col = 1, nCols do
			self:_place (row, col);
		end
	end
end

function Builder:_place (row, column)
	local part, spaceType = self:_partType (row, column);
	if (not part or spaceType == SpaceType.None) then return end
	
	local pos  = self:_calculatePosition (row, column);
	local offset = self:_calculateOffset (part)
	
	local newPart = part:Clone ();
	reposition(newPart, pos, offset);
	newPart.Parent = self._parent;
	
	if (spaceType == SpaceType.End) then
		fixExitRotation (self._grid, Space.new (row, column), newPart);
	end
end

-- Helpers
function Builder:_partType (row, column)
	local spaceType = self._grid:getSpaceTypeRC (row, column);
	local result;
	
	if (spaceType == SpaceType.Floor) then result = self._parts.floor; end
	if (spaceType == SpaceType.Wall) then result = self._parts.wall; end
	if (spaceType == SpaceType.Deadend) then result = self._parts.deadEnd; end
	if (spaceType == SpaceType.Start) then result = self._parts.start; end
	if (spaceType == SpaceType.End) then result = self._parts.exit; end
	if (spaceType == SpaceType.None) then result = false; end
	
	if (result == nil) then
		return error ("Could not find part type for SpaceType: " .. tostring(spaceType));
	end
	
	return result, spaceType;
end

function Builder:_calculatePosition (row, column)
	return Space3D.position (row, column, self._size);
end

function Builder:_calculateOffset (part)
	-- The position has to be vertically centered so everything aligns correctly
	if (part:IsA("Model")) then return DEF_PART_OFFSET; end
	return Vector3.new (0, part.Size.Y / 2, 0);
end


Builder.__index = Builder;
return B;