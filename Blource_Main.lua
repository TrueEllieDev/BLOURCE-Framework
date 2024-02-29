local blource = {
	PlayerData = {
		Player = game.Players.LocalPlayer,
		Health = 100,
		Armor = 0,
		Inventory = {},
		CurrentWeapon = "",
		CanRun = false,
		IsLoaded = false,
		Map = "devtest",
		PrevMap = "devtest",
		IsRunning = false,
		Language = "english";
		NewCharacterControllerEnabled = false;
		SaveFile = "basesave00";
		Immune = false;
		Stamina = 3;
		MaxStamina = 3;
		JumpHeight = 15
	};
	WeaponList = {
	};
	GameRessources = game:GetService("ReplicatedStorage").Resources;
	LevelLoadConfig = {
		TextureLessWall = {
			"trigger";
			"dev_collider";
			"ai_node";
			"reverb_node"
		};
		InfoInstances = {
			"Info_PlayerSpawn";
			"Info_env_skybox"
		}
	};
}

local Menu = blource.PlayerData.Player.PlayerGui.Menu
local Debris = game:GetService("Debris")
local InputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

function blource:PlaySound(SoundName:string?,Type:number?,Part:BasePart?)
	local Sound = blource.GameRessources.Sounds:FindFirstChild(SoundName)
	if Sound then
		if Type then
			if Type == 1 then
				if Sound:IsA("Sound") then
					local S = Sound:Clone()
					S.Parent = game:GetService("SoundService")
					S:Play()
					wait()
					local LifeTime = S.TimeLength+2
					Debris:AddItem(S, LifeTime)
				else
					warn("Tried to play sound "..SoundName.." but it is not a sound, and should therefore be moved to another folder (ex: Models).")
				end
			elseif Type == 2 then
				if Part then
					if Sound:IsA("Sound") then
						local S = Sound:Clone()
						S.Parent = Part
						S:Play()
						wait()
						local LifeTime = S.TimeLength+2
						Debris:AddItem(S, LifeTime)
					else
						warn("Tried to play sound "..SoundName.." but it is not a sound, and should therefore be moved to another folder (ex: Models).")
					end
				else
					warn("Tried to play sound "..SoundName.." with type 2 (played on part) but Part value is invalid.")
				end
			else
				warn("Tried to play sound "..SoundName..", but type is invalid (must be 0 or 1).")
			end
		else
			warn("Tried to play sound "..SoundName..", but type is nil.")
		end
	else
		warn("The sound "..SoundName.." wasn't found or does not exist.")
		local S = blource.GameRessources.Sounds.vc_error:Clone()
		S.Parent = game:GetService("SoundService")
		S:Play()
		wait()
		local LifeTime = S.TimeLength+2
		Debris:AddItem(S, LifeTime)
	end
end

function blource:SetLevelMusic(SoundName:string?)
	local Sound = blource.GameRessources.Sounds:FindFirstChild(SoundName)
	if Sound and not workspace:FindFirstChild("GLOBALLVLMUS") then
		if game:GetService("Workspace"):FindFirstChild("GLOBALLVLMUS") then
			game:GetService("Workspace"):FindFirstChild("GLOBALLVLMUS"):Destroy()
		end
		local S = Sound:Clone()
		S.Name = "GLOBALLVLMUS"
		S.Parent = game:GetService("Workspace")
		S.Looped = true
		S:Play()
		wait()
	else
		blource:PlaySound("vc_error", 1)
	end
end

function blource:StopSound(Sound:string?)
	if game:GetService("SoundService"):FindFirstChild(Sound) then
		local S = game:GetService("SoundService"):FindFirstChild(Sound)
		if S:IsA("Sound") then
			S:Stop()
		end
		S:Destroy()
	else
		warn("Sound not found.")
	end
end

function blource:StopAllSound()
	game:GetService("SoundService"):ClearAllChildren()
end

local function BindInputTo(input:Enum.KeyCode,inputscript:ModuleScript?,OnlyIfLoaded:boolean?)
	if OnlyIfLoaded == true then
		InputService.InputBegan:Connect(function(Input, Process)
			local InputScript = require(inputscript)
			if blource.PlayerData.IsLoaded == true and Input.KeyCode == input and Menu.Enabled == false then
				InputScript:OnInput()
			end
		end)
		InputService.InputEnded:Connect(function(Input, Process)
			local InputScript = require(inputscript)
			if blource.PlayerData.IsLoaded == true and Input.KeyCode == input and Menu.Enabled == false then
				InputScript:OnRelease()
			end
		end)
	else
		InputService.InputBegan:Connect(function(Input, Process)
			local InputScript = require(inputscript)
			if Input.KeyCode == input then
				InputScript:OnInput()
			end
		end)
		InputService.InputEnded:Connect(function(Input, Process)
			local InputScript = require(inputscript)
			if Input.KeyCode == input then
				InputScript:OnRelease()
			end
		end)
	end
end

function blource:GetSound(SoundName)
	local Sound = blource.GameRessources.Sounds:FindFirstChild(SoundName)
	if Sound then
		return Sound	
	else
		return nil
	end
end

local function BindInputInputGroup(inputscript:ModuleScript?,OnlyIfLoaded:boolean?)
	if OnlyIfLoaded == true then
		InputService.InputBegan:Connect(function(Input, Process)
			local InputScript = require(inputscript)
			if blource.PlayerData.IsLoaded == true and Menu.Enabled == false then
				InputScript:OnInput(Input)
			end
		end)
		InputService.InputEnded:Connect(function(Input, Process)
			local InputScript = require(inputscript)
			if blource.PlayerData.IsLoaded == true and Menu.Enabled == false then
				InputScript:OnRelease(Input)
			end
		end)
	else
		InputService.InputBegan:Connect(function(Input, Process)
			local InputScript = require(inputscript)
			InputScript:OnInput()
		end)
		InputService.InputEnded:Connect(function(Input, Process)
			local InputScript = require(inputscript)
			InputScript:OnRelease()
		end)
	end
end

function blource:RunCommand(Command:string, Arg:string)
	print(Command)
	if blource.GameRessources.Components.Commands:FindFirstChild(Command) then
		require(blource.GameRessources.Components.Commands:FindFirstChild(Command)):Command(Arg)
	else
		warn("Command "..Command.." is not a valid command.")
	end
end

local function map(from:number?)
	local WeaponModule = require(blource.GameRessources.Components.core_weapons)
	game.Lighting.ClockTime = 14.5
	WeaponModule:ClearWeapons()
	blource:StopAllSound()
	print("Loading "..blource.PlayerData.Map)
	local AlreadyLoaded = false
	if workspace:FindFirstChild("Map") then
		workspace.Map:Destroy()
	end
	local Music = game:GetService("Workspace"):FindFirstChild("GLOBALLVLMUS")
	if blource.PlayerData.Map == blource.PlayerData.PrevMap then
		AlreadyLoaded = true
		print("Same level, no change to currently playing OST.")
	elseif Music and not(blource.PlayerData.Map == blource.PlayerData.PrevMap) then
		Music:Destroy()
	end
	local scriptLoader = require(blource.GameRessources.Components.script_lvl_loader)
	blource.PlayerData.Player.PlayerGui.Menu.Enabled = false
	local Map = game:GetService("ReplicatedStorage").Maps:WaitForChild(blource.PlayerData.Map):Clone()
	Map.Parent = workspace
	local GUI:Frame?
	if from then
		if from == 1 then
			GUI = blource.PlayerData.Player.PlayerGui.LoadingScreens.BOOT
		else
			GUI = blource.PlayerData.Player.PlayerGui.LoadingScreens.FROMMENU
		end
	end
	if GUI then
		GUI.Visible = true
	end
	blource.PlayerData.IsLoaded = false
	blource.PlayerData.IsRunning = false
	WeaponModule:UpdateWeaponList()
	repeat
		wait()
	until blource.PlayerData.Player.Character:FindFirstChildOfClass("Humanoid")
	if not blource.PlayerData.Player.Character:FindFirstChild("HumanoidRootPart") then
		repeat
			wait()
		until blource.PlayerData.Player.Character:FindFirstChild("HumanoidRootPart")
	end
	Map.Name = "Map"
	blource.PlayerData.Player.Character.HumanoidRootPart.Anchored = true
	workspace.Gravity = 0
	game:GetService("ContentProvider"):PreloadAsync(Map:GetDescendants())
	WeaponModule:LoadWeapons()
	repeat 
		wait()
	until game:GetService("ContentProvider").RequestQueueSize < 2
	scriptLoader:StartLevelScripts(Map)
	blource.GameRessources.Events.TpChar:FireServer(Map.Info.Info_PlayerSpawn.CFrame)
	blource.PlayerData.IsLoaded = true
	workspace.Gravity = 145
	local CamModule = require(blource.GameRessources.Components.core_camerachanger)
	CamModule:SwapCameraTypeTo(Enum.CameraType.Scriptable)
	workspace.Camera.CFrame = Map.Info.Info_PlayerSpawn.CFrame
	blource.PlayerData.Player.Character.HumanoidRootPart.Anchored = false
	blource.GameRessources.Events.TpChar:FireServer(Map.Info.Info_PlayerSpawn.CFrame)
	print("Finished loading "..blource.PlayerData.Map)
	blource.GameRessources.Events.MapLoaded:Fire(blource.PlayerData.Map)
	CamModule:ChangeToFPSCamera()
	local humanoid = blource.PlayerData.Player.Character:FindFirstChildOfClass("Humanoid")
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid.JumpHeight = blource.PlayerData.JumpHeight
	game:GetService("UserInputService").MouseIconEnabled = false
	if GUI then
		GUI.Visible = false
	end
	blource.PlayerData.PrevMap = blource.PlayerData.Map
	if Map.Info:FindFirstChild("ScriptedSequencing") then
		task.spawn(require(Map.Info:FindFirstChild("ScriptedSequencing")).LevelSequencing, AlreadyLoaded)
	end
	WeaponModule:EquipWeapon(blource.PlayerData.CurrentWeapon)
end

function blource:LoadMap(MapName:string?,from:number)
	if blource.GameRessources.Parent.Maps:FindFirstChild(MapName) then
		if blource.GameRessources.Parent.Maps:FindFirstChild(MapName).Info.CanLoad.Value == true then
			blource.PlayerData.Map = MapName
			task.spawn(map, from)
		else
			warn("Map "..MapName.." couldn't load: access denied.")
		end
	else
		warn("Map "..MapName.." doesn't exist or was not named correctly.")
	end
end

function blource:AddSubtitle(text:string?, length:number?, colorid:number?)
	local SubtitleCopy = blource.GameRessources.GUI.sub:Clone()
	SubtitleCopy.Text  =  (" "..text.." ")
	game:GetService("Debris"):AddItem(SubtitleCopy, length) 
	SubtitleCopy.Parent = blource.PlayerData.Player.PlayerGui.Subtitle.Frame
	SubtitleCopy.Visible = true
	SubtitleCopy.Transparency = 1
	if SubtitleCopy:FindFirstChildOfClass("UICorner") then
		
	else
		local uicorner = Instance.new("UICorner")
		uicorner.Parent = SubtitleCopy
		uicorner.CornerRadius = UDim.new(0,8)
	end
	local colorids = require(blource.GameRessources.Components.gui_subcolors)
	if colorid then
		SubtitleCopy.TextColor3 = colorids[colorid]
	end
	local TweenService = game:GetService("TweenService")
	TweenService:Create(SubtitleCopy, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0}):Play()
	spawn(function()
		task.wait((length-0.3))
		TweenService:Create(SubtitleCopy, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 1}):Play()
	end)
end

local function BindMouseInput(Module:ModuleScript?)
	local MouseInput = require(Module)
	local Mouse = blource.PlayerData.Player:GetMouse()
	Mouse.Button1Down:Connect(function()
		if blource.PlayerData.IsLoaded == true then
			MouseInput:OnInput(1)
		end
	end)
	Mouse.Button2Down:Connect(function()
		if blource.PlayerData.IsLoaded == true then
			MouseInput:OnInput(2)
		end
	end)
	Mouse.Button1Up:Connect(function()
		if blource.PlayerData.IsLoaded == true then
			MouseInput:OnRelease(1)
		end
	end)
	Mouse.Button2Up:Connect(function()
		if blource.PlayerData.IsLoaded == true then
			MouseInput:OnRelease(2)
		end
	end)
end

function blource:Startup()
	blource.GameRessources.Events.FreezeChar:FireServer()
	local ContentProvider = game:GetService("ContentProvider")
	ContentProvider:PreloadAsync(blource.GameRessources:GetDescendants())
	repeat
		wait()
	until ContentProvider.RequestQueueSize <= 30
	for i, v in pairs(blource.GameRessources.Scripts:GetChildren()) do
		if v.Name:match("input_") and v:IsA("ModuleScript") and not v.Name:match("inputgroup_") then
			local InputScript = require(v)
			BindInputTo(InputScript.InputEnum,v,InputScript.CantRunOutOfLoadedMap)
			print("Binded "..v.Name.." successfully")
		elseif v.Name:match("ammo_") or v.Name:match("weapon_") then
			
		elseif v.Name:match("mouse_") then
			BindMouseInput(v)
		elseif v.Name:match("inputgroup_") and v:IsA("ModuleScript") and not v.Name:match("input_") then
			local InputScript = require(v)
			BindInputInputGroup(v,InputScript.CantRunOutOfLoadedMap)
		elseif require(v).Start then
			local Script = require(v)
			task.spawn(Script.Start)
		end
	end
	local humanoid = blource.PlayerData.Player.Character:FindFirstChildOfClass("Humanoid")
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	blource.PlayerData.Player.CharacterAdded:Connect(function()
		local humanoid = blource.PlayerData.Player.Character:FindFirstChildOfClass("Humanoid")
		blource.GameRessources.Events.FreezeChar:FireServer()
		if blource.PlayerData.IsLoaded == true then
			map()
		end
	end)
	local WeaponCore = require(blource.GameRessources.Components.core_weapons)
	WeaponCore:StartWeaponHandle()
	print("Game loaded")
end

function blource:ShootBullet(startcframe:CFrame?,spread:number?,effect:boolean?,effectoriginpoint:Vector3?,distance:number?,ammomodule:ModuleScript?,model:Model?,player:Player?,BulletAmount:number?,damage:number?)
	local RaycastParam = RaycastParams.new()
	RaycastParam.FilterType = Enum.RaycastFilterType.Exclude
	if player then
		RaycastParam.FilterDescendantsInstances = {
			model,
			player.Character
		}
	else
		RaycastParam.FilterDescendantsInstances = {
			model,
		}
	end
	RaycastParam.IgnoreWater = false
	local function Shoot()
		local SpreadCFrame = startcframe * CFrame.Angles(math.rad(math.random(-spread, spread)), math.rad(math.random(-spread, spread)), math.rad(math.random(-spread, spread)))
		local RayResult = workspace:Raycast(SpreadCFrame.Position, SpreadCFrame.LookVector * distance,RaycastParam)
		if RayResult then
			if RayResult.Distance <= distance and RayResult.Instance then
				if effect then
					local effect = blource.GameRessources.Effects.shot:Clone()
					effect.Parent = workspace
					effect.origin.WorldPosition = effectoriginpoint
					effect.shot.WorldPosition = RayResult.Position
					TweenService:Create(effect.Beam, TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Width0 = 0; Width1 = 0}):Play()
					Debris:AddItem(effect, 0.2)
				end
				if RayResult.Instance.Parent:FindFirstChildOfClass("Humanoid") then
					task.spawn(blource.PlaySound, nil,"wp_hit", 2, RayResult.Instance)
					if RayResult.Instance.Name == "Head" then
						if game:GetService("Players"):GetPlayerFromCharacter( RayResult.Instance.Parent) then
							blource:DamagePlayer(damage*3)
						else
							RayResult.Instance.Parent:FindFirstChildOfClass("Humanoid"):TakeDamage(damage*3)
						end
					else
						if game:GetService("Players"):GetPlayerFromCharacter( RayResult.Instance.Parent) then
							blource:DamagePlayer(damage)
						else
							RayResult.Instance.Parent:FindFirstChildOfClass("Humanoid"):TakeDamage(damage)
						end
					end
				end
				local TestPart = Instance.new("Part")
				TestPart.Parent = workspace
				TestPart.Size = Vector3.new(0.1,0.1,0.1)
				TestPart.Anchored = true
				TestPart.Position = RayResult.Position
				TestPart.Rotation = RayResult.Normal
				TestPart.Color = Color3.fromRGB(255,0,0)
				TestPart.Material = Enum.Material.ForceField
				TestPart.CanCollide = false
				TestPart.CanTouch = false
				TestPart.CanQuery = false
				Debris:AddItem(TestPart, 5)
				if RayResult.Instance.Parent:FindFirstChildOfClass("Humanoid") then
					local BloodPrtcls = blource.GameRessources.Effects.blood:GetChildren()
					for i, v in pairs(BloodPrtcls) do
						if v:IsA("ParticleEmitter") then
							local Blood = v:Clone()
							Blood.Parent = TestPart
							Blood:Emit(2)
						end
					end
				end
			end
		end
	end
	for i = 1, BulletAmount do
		Shoot()
	end
end

function blource:DamagePlayer(Value:number?)
	if blource.PlayerData.Immune == false then
		blource.GameRessources.Events.DamagePlayer:FireServer(Value)
	end
end

function blource:entCreate(entityname:string?)
	if blource.GameRessources.GameplayObjects:FindFirstChild(entityname) then
		local module = blource.GameRessources.GameplayObjects:FindFirstChild(entityname)
		if module:IsA("ModuleScript") then
			local scriptLoader = require(blource.GameRessources.Components.script_lvl_loader)
			local newmod = module:Clone()
			newmod.Parent = workspace
			scriptLoader:StartScriptsForModule(newmod)
			return newmod
		else
			print("GameObject "..entityname.." is not a modulescript.")
			return nil
		end
	else
		print("GameObject "..entityname.." is not a valid entity and therefore, does not exist.")
		return nil
	end
end

function blource:createTestPart(CFrame1:CFrame?, Transparency:number?, Lifetime:number?)
	local TestPart = Instance.new("Part")
	TestPart.Parent = workspace
	TestPart.Size = Vector3.new(0.1,0.1,0.1)
	TestPart.Anchored = true
	TestPart.CFrame = CFrame1
	TestPart.Color = Color3.fromRGB(255,0,0)
	TestPart.Material = Enum.Material.ForceField
	TestPart.CanCollide = false
	TestPart.CanTouch = false
	TestPart.CanQuery = false
	if Transparency then
		TestPart.Transparency = Transparency
	else
		TestPart.Transparency = 0.5
	end
	Debris:AddItem(TestPart, 5)
	return TestPart
end

function blource:LoadCloudPreset(preset:string?)
	if workspace.Terrain:FindFirstChildOfClass("Clouds") then
		print("cloud instance ig")
	else
		warn("no cloud instance")
		local clouds = Instance.new("Clouds")
		clouds.Parent = workspace.Terrain
	end
	local CloudPres = blource.GameRessources.Scripts:FindFirstChild(preset)
	if string.match(CloudPres.Name, "cloud_") then
		
	else
		warn(preset.." is not a valid preset, and is therefore ignored!")
	end
end

return blource