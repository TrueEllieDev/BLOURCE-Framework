local module = {}
local BLOURCE = require(game:GetService("ReplicatedStorage").Blource_Main)

local GUIDir = BLOURCE.GameRessources.GUI

function module:CampaignGUI(GUIName:string?)
	if GUIDir:FindFirstChild(GUIName) then
		local SG = GUIDir:FindFirstChild(GUIName)
		if SG:IsA("ScreenGui") then
			local ScreenGui = SG:Clone()
			ScreenGui.Parent = BLOURCE.PlayerData.Player.PlayerGui
			ScreenGui.Name = "TempGUI"
			if ScreenGui:FindFirstChild("ClientGUI") then
				local ClientGUI = ScreenGui:FindFirstChild("ClientGUI")
				if ClientGUI:IsA("LocalScript") then
					ClientGUI.Enabled = true
				else
					warn(ClientGUI.Name.." ("..ScreenGui.Name..") is not a valid LocalScript.")
				end
			else
				warn(ScreenGui.Name.." does not have a ClientGUI local script, while it is highly recommended to have one!")
			end
		else
			warn(GUIName.." is not a valid ScreenGui instance.")
		end
	else
		warn(GUIName.." is not a valid instance.")
	end
end

return module
