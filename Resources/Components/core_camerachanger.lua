local module = {}

local Camera = game.Workspace.CurrentCamera

local Player = game.Players.LocalPlayer

function CheckCameraType()
	 local CameraType = game.Workspace.CurrentCamera.CameraType
	if CameraType == Enum.CameraType.Scriptable then
		print("Camera Type is set to scriptable.")
	end
	if CameraType == Enum.CameraType.Attach then
		print("Camera Type is set to attach.")
	end
	if CameraType == Enum.CameraType.Custom then
		print("Camera Type is set to attach.")
	end
end

function module:SwapCameraTypeTo(CameraType:Enum.CameraType) --Warning: CameraType must be set to Enum.CameraType.[CameraTypeNameHere], or else it will not work!
	Camera.CameraType = CameraType
	CheckCameraType()
end

function module:SetCameraToMenuMap()
	repeat wait()
		Camera.CameraType = Enum.CameraType.Scriptable
	until Camera.CameraType == Enum.CameraType.Scriptable
	CheckCameraType()
	Camera.CFrame = workspace.MenuMap:WaitForChild("CameraPart").CFrame
end

function module:ChangeToFPSCamera()
	repeat wait()
		Camera.CameraType = Enum.CameraType.Follow
	until Camera.CameraType == Enum.CameraType.Follow
	repeat wait()
		Player.CameraMode = Enum.CameraMode.LockFirstPerson
	until Player.CameraMode == Enum.CameraMode.LockFirstPerson
	CheckCameraType()
end

return module