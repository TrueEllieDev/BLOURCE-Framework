local BLOURCE = require(game:GetService("ReplicatedStorage").Blource_Main)
local module = {
	Weapons = {
		BLOURCE.GameRessources.Scripts.weapon_base
	};
	CurrentViewModel = "";
	Idle = nil;
	LastShot = tick();
	Reloading = false
}
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local ScriptDirectory = BLOURCE.GameRessources.Scripts
local RunService = game:GetService("RunService")
local OriginalFOV = Camera.FieldOfView
function module:UpdateWeaponList()
	table.clear(module.Weapons)
	for i, v in pairs(ScriptDirectory:GetChildren()) do
		if v.Name:match("weapon_") then
			table.insert(module.Weapons, v)
		end
	end
end

local function WeaponHandle()
	local ViewModel = workspace.weapons:FindFirstChild(module.CurrentViewModel)
	if ViewModel and BLOURCE.PlayerData.IsLoaded then
		--local cf = workspace.CurrentCamera.CFrame
		--ViewModel.PrimaryPart.CFrame = cf
		ViewModel:MoveTo(workspace.CurrentCamera.CFrame.Position)
		local cf = ViewModel.PrimaryPart.CFrame:Lerp(workspace.CurrentCamera.CFrame, .9)
		ViewModel.PrimaryPart.CFrame = cf
	end
end

function module:ClearWeapons()
	workspace.weapons:ClearAllChildren()
end

function module:StartWeaponHandle()
	RunService.PreRender:Connect(WeaponHandle)
end

function module:GetWeaponData()
	if BLOURCE.PlayerData.CurrentWeapon then
		local WeaponModule = BLOURCE.GameRessources.Scripts:FindFirstChild(BLOURCE.PlayerData.CurrentWeapon)
		if WeaponModule then
			local WeaponData = require(WeaponModule)
			return WeaponData
		else
			return nil
		end
	end
	return nil
end

function module:UnequipWeapon()
	local ViewModel = workspace.weapons:FindFirstChild(module.CurrentViewModel)
	if ViewModel then
		ViewModel:MoveTo(Vector3.zero)
	end
	if module.Idle then
		module.Idle:Stop()
	end
	module.CurrentViewModel = nil
end

function module:Reload()
	local ViewModel = workspace.weapons:FindFirstChild(module.CurrentViewModel)
	if ViewModel and module.Reloading == false then
		local WeaponModule = require(BLOURCE.GameRessources.Scripts:FindFirstChild(BLOURCE.PlayerData.CurrentWeapon))
		local WeaponScript = BLOURCE.GameRessources.Scripts:FindFirstChild(BLOURCE.PlayerData.CurrentWeapon)
		local WeaponID = WeaponScript:GetAttribute("WeaponID")
		local InventorySlot = game:GetService("ReplicatedStorage").Blource_Main.Inventory:FindFirstChild(WeaponID)
		local ClipAmmo = InventorySlot:GetAttribute("BulletsInClip")
		local TotalAmmo = InventorySlot.Value
		if WeaponModule.ShootSound and WeaponModule.ReloadAnimation and ClipAmmo <= WeaponModule.PrincipalAmmo then
			module.Reloading = true
			local ReloadAnim = ViewModel:FindFirstChildOfClass("AnimationController"):LoadAnimation(BLOURCE.GameRessources.Animations:FindFirstChild(WeaponModule.ReloadAnimation))
			ReloadAnim:Play(0)
			task.wait(ReloadAnim.Length)
			if InventorySlot.Value <= WeaponModule.PrincipalAmmo then
				InventorySlot:SetAttribute("BulletsInClip", InventorySlot.Value)
			else
				InventorySlot:SetAttribute("BulletsInClip", WeaponModule.PrincipalAmmo)
			end
			module.Reloading = false
		end
	end
end
function module:CreateWorldmodel(Weapon:string?)
	if BLOURCE.GameRessources.Scripts:FindFirstChild(Weapon) then
		local ScriptModule = BLOURCE.GameRessources.Scripts:FindFirstChild(Weapon)
		local WeaponModule = require(ScriptModule)
		if WeaponModule.WorldModel then
			if BLOURCE.GameRessources.Models:FindFirstChild(WeaponModule.WorldModel) then
				local WM = BLOURCE.GameRessources.Models:FindFirstChild(WeaponModule.WorldModel):Clone()
				WM.Parent = workspace
				return WM
			else
				
			end
		else
			return nil
		end
	end
end
function module:ShootWeapon()
	local ViewModel = workspace.weapons:FindFirstChild(module.CurrentViewModel)
	if ViewModel then
		local WeaponModule = require(BLOURCE.GameRessources.Scripts:FindFirstChild(BLOURCE.PlayerData.CurrentWeapon))
		local WeaponScript = BLOURCE.GameRessources.Scripts:FindFirstChild(BLOURCE.PlayerData.CurrentWeapon)
		local TimeSinceLastShot = tick()-module.LastShot
		if WeaponModule.ShootSound and WeaponModule.ShootAnimation and (TimeSinceLastShot>=WeaponModule.Cooldown or TimeSinceLastShot==WeaponModule.Cooldown) then
			local Spread = WeaponModule.Spread
			local Range = WeaponModule.EffectiveRange
			local WeaponID = WeaponScript:GetAttribute("WeaponID")
			local InventorySlot = game:GetService("ReplicatedStorage").Blource_Main.Inventory:FindFirstChild(WeaponID)
			local ClipAmmo = InventorySlot:GetAttribute("BulletsInClip")
			local TotalAmmo = InventorySlot.Value
			local Effect = false
			module.LastShot = tick()
			local function Shoot()
				BLOURCE:PlaySound(WeaponModule.ShootSound, 1)
				if WeaponModule.CustomBehavior == false then
					ViewModel:FindFirstChildOfClass("AnimationController"):LoadAnimation(BLOURCE.GameRessources.Animations:FindFirstChild(WeaponModule.ShootAnimation)):Play()
					Camera.FieldOfView = Camera.FieldOfView + 5
					TweenService:Create(Camera, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {FieldOfView = OriginalFOV}):Play()
					if ViewModel:IsA("Model") then
						if ViewModel.PrimaryPart:FindFirstChild("Muzzleflash") then
							Effect = true
							local Particles = ViewModel.PrimaryPart:FindFirstChild("Muzzleflash"):GetChildren()
							for i, v in pairs(Particles) do
								if v:IsA("ParticleEmitter") then
									v:Emit(45)
								end
							end
						end
					end
					BLOURCE:ShootBullet(workspace.CurrentCamera.CFrame, Spread, Effect, ViewModel.PrimaryPart:FindFirstChild("Muzzleflash").WorldCFrame.Position, Range, nil, ViewModel, BLOURCE.PlayerData.Player, WeaponModule.BulletsPerShot, WeaponModule.Damage)
				else
					WeaponModule:PrimaryShot(ViewModel)
				end
			end
			if WeaponModule.UsesClip == true and ClipAmmo >= WeaponModule.AmmoPerShot or ClipAmmo == WeaponModule.AmmoPerShot then
				InventorySlot:SetAttribute("BulletsInClip", ClipAmmo-WeaponModule.AmmoPerShot)
				InventorySlot.Value = TotalAmmo-WeaponModule.AmmoPerShot
				Shoot()
			elseif WeaponModule.UsesClip == false and TotalAmmo>=WeaponModule.AmmoPerShot or TotalAmmo==WeaponModule.AmmoPerShot then
				InventorySlot.Value = TotalAmmo-WeaponModule.AmmoPerShot
				Shoot()
			elseif WeaponModule.UsesClip == false and WeaponModule.PrincipalAmmo == 0 then
				Shoot()
			else
				BLOURCE:PlaySound("wp_emptyclip",1)
			end
		end
	end
end

function module:ShootSecondary()
	local ViewModel = workspace.weapons:FindFirstChild(module.CurrentViewModel)
	if ViewModel then
		local WeaponModule = require(BLOURCE.GameRessources.Scripts:FindFirstChild(BLOURCE.PlayerData.CurrentWeapon))
		local WeaponScript = BLOURCE.GameRessources.Scripts:FindFirstChild(BLOURCE.PlayerData.CurrentWeapon)
		local TimeSinceLastShot = tick()-module.LastShot
		if WeaponModule.ShootSound and WeaponModule.ShootAnimation and (TimeSinceLastShot>=WeaponModule.Cooldown or TimeSinceLastShot==WeaponModule.Cooldown) then
			local Spread = WeaponModule.Spread
			local Range = WeaponModule.EffectiveRange
			local WeaponID = WeaponScript:GetAttribute("WeaponID")
			local InventorySlot = game:GetService("ReplicatedStorage").Blource_Main.Inventory:FindFirstChild(WeaponID)
			local ClipAmmo = InventorySlot:GetAttribute("BulletsInClip")
			local TotalAmmo = InventorySlot.Value
			module.LastShot = tick()
			local function Shoot()
				BLOURCE:PlaySound(WeaponModule.ShootSound, 1)
				ViewModel:FindFirstChildOfClass("AnimationController"):LoadAnimation(BLOURCE.GameRessources.Animations:FindFirstChild(WeaponModule.ShootAnimation)):Play()
				Camera.FieldOfView = Camera.FieldOfView + 5
				if WeaponModule.CustomBehavior == true then
					WeaponModule:SecondaryShot(ViewModel)
				end
			end
			if WeaponModule.UsesClip == true and ClipAmmo >= WeaponModule.AmmoPerShot or ClipAmmo == WeaponModule.AmmoPerShot then
				InventorySlot:SetAttribute("BulletsInClip", ClipAmmo-WeaponModule.AmmoPerShot)
				InventorySlot.Value = TotalAmmo-WeaponModule.AmmoPerShot
				Shoot()
			elseif WeaponModule.UsesClip == false and TotalAmmo>=WeaponModule.AmmoPerShot or TotalAmmo==WeaponModule.AmmoPerShot then
				InventorySlot.Value = TotalAmmo-WeaponModule.AmmoPerShot
				Shoot()
			elseif WeaponModule.UsesClip == false and WeaponModule.PrincipalAmmo == 0 then
				Shoot()
			else
				BLOURCE:PlaySound("wp_emptyclip",1)
			end
		end
	end
end

function module:EquipWeapon(Weapon:string?)
	if BLOURCE.GameRessources.Scripts:FindFirstChild(Weapon) then
		local OriginalWeapon = BLOURCE.PlayerData.CurrentWeapon
		local WeaponModule = require(BLOURCE.GameRessources.Scripts:FindFirstChild(Weapon))
		if WeaponModule.ViewModel and Weapon ~= OriginalWeapon then
			BLOURCE:PlaySound("suit_equipweapon", 1)
			module.LastShot = 0
			module:UnequipWeapon()
			BLOURCE.PlayerData.CurrentWeapon = Weapon
			module.CurrentViewModel = require(BLOURCE.GameRessources.Scripts:FindFirstChild(Weapon)).ViewModel
			local ViewModel = workspace.weapons:FindFirstChild(module.CurrentViewModel)
			if ViewModel then
				if ViewModel:FindFirstChildOfClass("AnimationController") then
					module.Idle = ViewModel:FindFirstChildOfClass("AnimationController"):LoadAnimation(BLOURCE.GameRessources.Animations:FindFirstChild(WeaponModule.IdleAnimation))
					module.Idle:Play(0)
					ViewModel:FindFirstChildOfClass("AnimationController"):LoadAnimation(BLOURCE.GameRessources.Animations:FindFirstChild(WeaponModule.DrawAnimation)):Play(0)
				end
			end
			--[[warn(Weapon.." has been equipped successfully to player.")]]
		else
			--[[warn("Weapon "..Weapon.." doesn't have a valid ViewModel or was already equipped. Item not equipped.")]]
		end
	--[[else
		warn(Weapon.." isn't valid or has been mispelled.")]]
	end
end

function module:LoadWeapons()
	for i, v in pairs(module.Weapons) do
		local WeaponClass = require(v)
		if WeaponClass.ViewModel then
			local OgModel = BLOURCE.GameRessources.Models:FindFirstChild(WeaponClass.ViewModel)
			if OgModel then
				local Model = OgModel:Clone()
				if Model:IsA("Model") then
					Model:MoveTo(Vector3.zero)
				elseif Model:IsA("BasePart") then
					Model.Position =  Vector3.zero
				end
				Model.Parent = workspace.weapons
			else
				warn("Could not find ViewModel for "..v.Name..".")
			end
		else
			warn(v.Name.." does not have a ViewModel or is not a valid Weapon class.")
		end
	end
end

return module