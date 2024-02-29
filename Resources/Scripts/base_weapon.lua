local module = {
	Name = "SIL Co. 9mm Handgun",
	ViewModel = "vm_pistol",
	PrincipalAmmo = 12,
	SecondaryAmmo = 0,
	EffectiveRange = 250,
	IdleAnimation = "pistol_idle",
	DrawAnimation = "pistol_draw",
	ReloadAnimation = "pistol_reload",
	ShootAnimation = "pistol_shoot",
	ShootSound = "wp_pistol_shoot",
	AmmoPerShot = 1,
	Spread = 0,
	BulletsPerShot = 1,
	UsesClip = true,
	BulletsPerClip = nil,
	Automatic = false,
	Cooldown = .1,
	Damage = 15,
	CustomBehavior = false,
}

return module