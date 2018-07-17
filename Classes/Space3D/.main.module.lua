-- Represents a Space in the 3D environment.
local Space3D = { };

-- Static Variables
Space3D.Offset = Vector3.new (0, 0, 0);

-- Constructor
function Space3D.position (row, column, spaceSize)
	assert (row, "Row is a required argument");
	assert (column, "Column is a required argument");
	assert (spaceSize, "SpaceSize is a required argument");
	
	return positionOf (row, column, spaceSize, Space3D.Offset);
end

-- Helper Functions
function positionOf (row, column, spaceSize, offset)
	local posX = (column - 1) * spaceSize.X;
	local posZ = (row - 1) * spaceSize.Z;
	
	return Vector3.new (posX, 0, posZ) + offset;
end

return Space3D;