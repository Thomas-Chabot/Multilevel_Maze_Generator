--[[
	The Space class is used to represent a single space in the grid.
	Constructors:
		Space.new (row : int, col : int)
		   This will generate a new Space object for the given row & column.
		
		Space.new (position : Vector2)
		   Will generate a new Space object from a vector representing (column, row)
		
		Space.random (possibleRows : Vector2, possibleColumns : Vector2)
		  Generates a random Space given vectors for the possible rows & possible cols.
		  The Vectors should be (min, max), representing the minimum & maximum value.
		    eg. (1, 5) will generate a random space for rows between 1 & 5.
		  Note: This has special logic to work correctly with the generator;
		         one assumption made is that the max row number is odd (eg. 5).
		        It will only generate spots that would be valid for the generator
		         within the grid.
		
	Public Methods:
		Getters & Setters for the row & column number:
			getRow () : Integer
			getCol () : Integer
			setRow (row : Integer)
			setCol (col : Integer)
		
		The following methods move the space up, down, left or right, respectively:
			up ()
			down ()
			left ()
			right ()
			
	Metamethods:
		Space + Vector2
			The Space class can be added to from a Vector2 object.
			The Vector2 should represent (colOffset, rowOffset);
			  This will offset the current col / row by the given values.
		
		tostring (Space)
			Returns a string representing the Space class in the format
			 (column, row).
			
		Space == Space
			Compares the spaces to determine if they represent the same space.
--]]
local Space = { };
local S     = { };

-- ** Constructor ** --
function S.new (row, col)
	-- If it's a Vector2, grab the individual pieces
	if (col == nil and typeof (row) == "Vector2") then
		-- Note: Follows the format (column, row) - column is X
		col = row.X;
		row = row.Y;
	end
	
	return setmetatable ({
		_row = row,
		_col = col,
		
		-- For the relational metamethods
		X = row,
		Y = col 
	}, Space);
end

function S.random (possRows, possCols)
	-- The row & column must be even. If we have four columns (1 - 5),
	--   Taking row 1, 3 or 5 as the start space will mean we go outside the border.
	-- So we must instead take 2 or 4 -> This will give us 2 & 4 as options
	--   and we cannot go to 1, 3 or 5, so we will have a border.
	
	-- Therefore - we can randomize over possRows / 2 - in the 1 - 5, this gives us
	--   either 1 or 2.	By multiplying the result by 2, we get the row / col number.
	
	-- Trying again - if we have 11 columns - this gives us 10 options = 5 possible;
	--   Resulting in 2, 4, 6, 8 or 10. Each of which is a valid option.
	
	local minRow = possRows.X;
	local minCol = possCols.X;
	
	local maxRow = possRows.Y;
	local maxCol = possCols.Y;
	
	local rowN = math.random (minRow, (maxRow - 1) / 2);
	local colN = math.random (minCol, (maxCol - 1) / 2);
	
	local row  = rowN * 2;
	local col  = colN * 2;
	
	return S.new (row, col);
end

-- ** Public Methods ** --
function Space:getRow () return self._row; end
function Space:getCol () return self._col; end
function Space:setRow (row) self._row = row; end
function Space:setCol (col) self._col = col; end

function Space:up ()
	return S.new (self._row - 1, self._col);
end
function Space:down ()
	return S.new (self._row + 1, self._col);
end
function Space:left ()
	return S.new (self._row, self._col - 1);
end
function Space:right ()
	return S.new (self._row, self._col + 1);
end

-- ** Metamethods ** --
function Space:__add (directionVec2)
	local curPos = Vector2.new (self._col, self._row);
	local newPos = curPos + directionVec2;
	
	return S.new (newPos.Y, newPos.X);
end
function Space:__sub (directionVec2)
	return self + (directionVec2 * -1);
end

function Space:__lt (other)
	return self.X < other.X and self.Y < other.Y;
end
function Space:__le (other)
	return self.X <= other.X and self.Y <= other.Y;
end

function Space:__tostring ()
	return "(" .. self._row .. ", " .. self._col .. ")";
end

function Space:__eq (other)
	return other:getRow() == self:getRow() and other:getCol() == self:getCol();
end

Space.__index = Space;
return S;