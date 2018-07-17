local serverScriptService = game:GetService ("ServerScriptService");
local modules = serverScriptService.Modules;
local debounce = modules.Debounce;

script.Parent.Touched:connect (debounce (function (hit)
	local character = hit and hit.Parent;
	local human = character and character:FindFirstChild ("Humanoid");
	
	if (not human) then return end
	print (character.Name, " has won the game!");
end));