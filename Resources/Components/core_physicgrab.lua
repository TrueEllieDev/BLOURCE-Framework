local module = {
	Holding = false,
	Selected = nil
}

local BLOURCE = require(game:GetService("ReplicatedStorage").Blource_Main)
local Player = BLOURCE.PlayerData.Player
local HOLD_DISTANCE = 8 --How far object is when being held
local DROP_MIN_DISTANCE = 5 --How far object needs to be dropped
local RaycastToWorldCF = CFrame.new(0, 0, -HOLD_DISTANCE)
local PickUpParams = RaycastParams.new()
PickUpParams.FilterType = Enum.RaycastFilterType.Exclude
local CollectionService = game:GetService("CollectionService")
local PICKABLE_TAG = "Pickable"
local PICKUP_DISTANCE = 10
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local function DropOBJ(Player: Player, Object: BasePart)	Object.AssemblyLinearVelocity = Vector3.new(0,0,0)
	Object.AssemblyAngularVelocity = Vector3.new(0,0,0)
	Object.CanCollide = true
	Object.Massless = false
	CollectionService:AddTag(Object, PICKABLE_TAG)
	if Player.Character:FindFirstChild("Humanoid") then
		Object.AssemblyLinearVelocity = Player.Character.Humanoid.MoveDirection*Player.Character.Humanoid.WalkSpeed * 2 
	end
end
local function Hold()
	local cf = Camera.CFrame --Camera CFrame
	PickUpParams.FilterDescendantsInstances = {Player.Character, Selected}
	local ray = workspace:Raycast(cf.Position, cf.LookVector.Unit*HOLD_DISTANCE, PickUpParams) -- checks if anything is in the way

	local pos = ray and ray.Position or cf:ToWorldSpace(RaycastToWorldCF).Position --Position of the object
	local rZ, rX, rY = cf:ToOrientation() --gets rotating of cf
	local rot = Vector3.new(0, math.deg(rX), math.deg(rY)) --Rotation for the object is the same as camera's btw. Also makes so object doesn't rotate on Z Axis
	Selected.Position = pos
	Selected.Orientation = rot
	if Selected.AssemblyLinearVelocity.Y >= 50 or Selected.AssemblyLinearVelocity.Y <= -50 then
		Selected.AssemblyLinearVelocity = Vector3.new(Selected.AssemblyLinearVelocity, 0, Selected.AssemblyLinearVelocity)
	end
end
local function PickUpOBJ(Player: Player, Object: BasePart, Force: boolean)
	local Model = Object:FindFirstAncestorOfClass("Model") --Pickable object has to be a model
	if Model and CollectionService:HasTag(Model, PICKABLE_TAG) then
		CollectionService:RemoveTag(Object, PICKABLE_TAG)
		Object.Anchored = false
		Object.CanCollide =false
		return true
	end
	return false
end
function module:Drop(obj:BasePart?)
	if obj then
		DropOBJ(Player, obj)
		for i, ncc in pairs(Player.Character.PickUpNCCs:GetChildren()) do
			ncc.Enabled = false
		end
		return true
	end
	return false
end

function module:UnSuccessfulPickUp(cf)
	local res = workspace:Raycast(cf.Position, cf.LookVector.Unit*PICKUP_DISTANCE, PickUpParams)
	if res then
		local Model = res.Instance:FindFirstAncestorOfClass("Model")
		local IntModule = res.Instance:FindFirstAncestorOfClass("ModuleScript")--Pickable object has to be a model
		if Model then
			local e = Model:FindFirstChild("func_interactable")
			if e then
				local Module = require(Model:FindFirstChild("func_interactable"))
				Module:Interact()
			else
				BLOURCE:PlaySound("interact_fail",1)
			end
		elseif IntModule then
			local IntM = require(IntModule)
			for i = 1, #IntM.ScriptType do
				if IntM.ScriptType[i] == "CanInteract" then
					IntM:Interact()
				end
			end
		else
			BLOURCE:PlaySound("interact_fail",1)
		end
	else
		BLOURCE:PlaySound("interact_fail",1)
	end
end
function module:UnSuccessfulDrop()
	BLOURCE:PlaySound("interact_fail",1)
	print("fuck off")
	wait(1)
end
function module:PickUp(cf: CFrame?, obj: BasePart?, Force: boolean)
	local PickNCC = Player.Character:FindFirstChild("PickUpNCCs")
	if not PickNCC then
		local PickNCC = Instance.new("Folder")
		PickNCC.Parent = Player.Character
		PickNCC.Name = "PickUpNCCs"
	end
	if not obj then
		if cf then
			PickUpParams.FilterDescendantsInstances = {Player.Character} --+Your stuff
			local res = workspace:Raycast(cf.Position, cf.LookVector.Unit*PICKUP_DISTANCE, PickUpParams)
			if res and res.Instance and CollectionService:HasTag(res.Instance, PICKABLE_TAG) then
				local res2 = PickUpOBJ(Player, res.Instance, Force)
				if res2 then
					for i, ncc in pairs(Player.Character.PickUpNCCs:GetChildren()) do --PickUpNCCs is a folder of NoColliderConstraints in character that is used to disable collision with picked up object. if you need script for that let me know
						ncc.Part1 = res.Instance
						ncc.Enabled = true
					end
				end
				return res2 and res.Instance
			end
		end
	else
		local res2 = PickUpOBJ(Player, obj, Force)
		if res2 then
			for i, ncc in pairs(Player.Character.PickUpNCCs:GetChildren()) do
				ncc.Part1 = obj
				ncc.Enabled = true
			end
		end
		return obj
	end
	return false
end
function module:SuccessfulPickUp(PickedUp)
	module.Holding = true
	Selected = PickedUp
	RunService:BindToRenderStep("Hold", Enum.RenderPriority.Input.Value-1, Hold)
end
function module:SuccessfulDrop()
	module:Drop(Selected)
	RunService:UnbindFromRenderStep("Hold")
	module.Holding = false
	module.Selected = nil
end
return module
