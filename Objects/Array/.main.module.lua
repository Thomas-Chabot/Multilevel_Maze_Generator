--[[
	General class to store an array of some object.
	Returns:
		new()					Creates the array class using an empty table.
		new(objects: table)		Creates the array class using the given table.
		new(objects: model,      Creates the array class using the children of the given
		    class: ModuleScript) model. If provided, creates class using each child.
		get(i : int)			Gets the element at position i.
		get(f : function)       Gets the first element that satisfies f, such that
		                          f returns true.
		size()					Returns the size of the array.
		random()				Returns a random element from the array.
		randomized()            Returns a new Array containing elements from this 
		                          array in a random order.
		each(f : function)		Runs the function f on each element of the array.
		                          Exits on receiving false
		find(element)			Finds the index of the given element, or -1 if not found.
		remove(element,         Removes the given element from the table.
		  isIndex)                If isIndex is true, removes element at given position.
		add (ele)				If this is an array class, adds all elements from the
		                          array; otherwise adds element to the end of the array.
	Also works with metamethods:
		print (Array)			Returns Array as {v1, v2, v3} format
		Array + Array           Returns a new Array containing all items from both
								  arrays
		Array[i]				Gets the element at position i.
--]]

local arrayObj = { };

-- Constructor
function arrayObj.new (objects, class)
	local function constructClass (objects)
		for i,v in pairs(objects) do
			objects[i] = class.new(v)
		end
	end
	
	-- Was nothing given? If not, just default to { }
	objects = objects or { };
	
	-- If its a model, convert it into a table
	if (typeof (objects) == "Instance") then
		objects = objects:GetChildren()
		
		-- Is a class provided? Run constructor
		if (class) then
			constructClass(objects, class);
		end
	end
	
	-- Build the array with objects
	return setmetatable({objs = objects}, arrayObj);
end

-- Get the element at given index / function
function arrayObj:get (i)
	if (not self.objs) then return nil end
	if (typeof(i) ~= "function") then
		return self.objs[i];
	end
	
	-- at this point, its a function, so let's find it
	local ret = nil;
	self:each(function(element)
		if (i(element)) then
			ret = element;
			return false;
		end
	end)
	
	return ret;
end

-- Get the size of the array
function arrayObj:size ()
	if (not self.objs) then return nil end
	return #self.objs
end

-- Return a random child of the array
function arrayObj:random ()
	if (not self.objs or #self.objs == 0) then return nil end
	return self.objs[math.random(1, #self.objs)];
end

-- Randomize the Array
function arrayObj:randomized ()
	if (not self.objs or #self.objs == 0) then return false end;
	local objects = {unpack (self.objs)};
	
	-- requires a new table to store elements in
	local newElements = { };
	local nElements = self:size ();
	
	for i = 1, nElements do
		-- get a random element & add to the table
		-- note: have to remove from original so won't grab twice
		local randIndex = math.random (1, #objects);
		local element   = objects [randIndex];
		
		table.remove (objects, randIndex);
		table.insert (newElements, element);
	end
	
	-- and reset the objs table
	return arrayObj.new (newElements);
end

-- Run a function on each element of the array
function arrayObj:each (f)
	if (not self.objs) then return nil end
	for i,v in pairs (self.objs) do
		if (f(v) == false) then -- end if return value is false
			break;
		end
	end
end

-- Find an element in the array
function arrayObj:find (el)
	for i,v in pairs (self.objs) do
		if (v == el) then
			return i;
		end
	end
	return -1;
end

-- Remove an element from the array
function arrayObj:remove (el, isIndex)
	-- if its an index, just remove it
	if (isIndex) then
		table.remove(self.objs, el)
		return true
	end
	
	-- its not, so find the index
	local index = self:find (el)
	if (index == -1) then
		return false
	end
	
	-- take it out
	table.remove(self.objs, index)
	return true
end

-- Add elements into the array
function arrayObj:add (arr2, isClass)
	if (typeof (arr2) ~= "table" or not isClass) then
		-- just add it to the end of the array
		table.insert(self.objs, arr2);
	else
		-- convert it to an array, if its not
		if (not arr2.isArrayClass) then
			arr2 = arrayObj.new (arr2);
		end
		
		-- add event element from the array to this one
		arr2:each(function(v)
			table.insert(self.objs, v)
		end)
	end
end

arrayObj.isArrayClass = true;

-- Array + Array
function arrayObj:__add (arr2)
	local newArray = arrayObj.new(self.objs);
	newArray:add(arr2);
	return newArray;
end

-- Turn the array into a string.
function arrayObj:__tostring ()
	local str = "Array Containing Elements:\n";
	for i,v in pairs(self.objs) do
		str = str .. "\t" .. tostring(v) .. "\n";
	end
	return str;
end

-- #Array
-- Return the size of the array
-- ...apparently does not get fired. rip
function arrayObj:__len()
	return self:size();
end

arrayObj.__index = arrayObj;
return arrayObj;