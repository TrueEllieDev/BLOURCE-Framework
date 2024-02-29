local module = {}

function module:GoTo(NPC:Model?, Position:Vector3?, PathFinding:boolean?, NPCModule:any)
	if NPC:IsA("Model") and NPC:FindFirstChildOfClass("Humanoid") then
		local Hum = NPC:FindFirstChildOfClass("Humanoid")
		if PathFinding == true then
			local path = game:GetService("PathfindingService"):CreatePath({
				AgentRadius = 3,
				AgentHeight = 6,
				AgentCanJump = false,
				Costs = {
					Water = math.huge;
				}
			})
			local waypoints
			local nextWaypointIndex
			local reachedConnection
			local blockedConnection

			local function followPath(destination)
				-- Compute the path
				local success, errorMessage = pcall(function()
					path:ComputeAsync(NPC.PrimaryPart.Position, destination)
				end)

				if success and path.Status == Enum.PathStatus.Success then
					-- Get the path waypoints
					waypoints = path:GetWaypoints()
					-- Detect when movement to next waypoint is complete
					if not reachedConnection then
						reachedConnection = Hum.MoveToFinished:Connect(function(reached)
							if reached and nextWaypointIndex < #waypoints then
								-- Increase waypoint index and move to next waypoint
								nextWaypointIndex += 1
								Hum:MoveTo(waypoints[nextWaypointIndex].Position)
							else
								reachedConnection:Disconnect()
							end
						end)
					end

					-- Initially move to second waypoint (first waypoint is path start; skip it)
					nextWaypointIndex = 2
					Hum:MoveTo(waypoints[nextWaypointIndex].Position)
				else
					warn("Path not computed!", errorMessage)
				end
				
			end
			followPath(Position)
			NPCModule.Status.Idle = true
		end
	else
		warn("Given model ("..(NPC.Name)..") is not a model or an humanoid.")
	end
end

function module:AddHostileComponent(NPC:Model?)
	local NPCModule = require(NPC.Parent)
	local function Hostile()
		local RootPart = NPC.PrimaryPart
		local Target:Model? = nil
		local TooClose = false
		local Lock = false
		local Node:BasePart? = nil
		local PastNode = nil
		local IsToSafety = true
		local function Loop()
			--Functions
			local function CheckDistance()
				local targetDistance = 5
				local targetHRP = Target
				local Mag = (RootPart.Position- targetHRP.Position).Magnitude
				if Mag <= targetDistance then
					targetDistance = Mag
				end
				return targetDistance
			end
			local function GoToNearestNode(ExcludeNode:BasePart?)
				IsToSafety = false
				local targetDistance = 100
				local PrevNode = Node
				local Success = false
				for i,v in pairs(workspace:GetDescendants()) do
					if v:IsA("BasePart") and v.Name == "ai_node" and v ~= ExcludeNode and v ~= PastNode then
						local targetHRP = v
						local Mag = (RootPart.Position-v.Position).Magnitude
						if Mag <= targetDistance then
							targetDistance = Mag
							Node = targetHRP
							Success = true
						end
					end
				end
				if Success == true then
					print("Success.")
					module:GoTo(NPC, Node.Position, true, NPCModule)
					NPCModule.Status.Idle = true
					PastNode = PrevNode
				else
					NPCModule.Status.Idle = true
				end
			end
			local function CheckForEnemies()
				local targetDistance = 25
				for i,v in pairs(workspace:GetDescendants()) do
					if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Name ~= NPC.Name and v:FindFirstChild("HumanoidRootPart") then
						if game:GetService("Players"):GetPlayerFromCharacter(v) then
							local targetHRP = v.HumanoidRootPart
							local Mag = (RootPart.Position- targetHRP.Position).Magnitude
							if Mag <= targetDistance then
								targetDistance = Mag
								Target = targetHRP
							end
						end
					end
				end
				if Target then
					NPCModule.Status.Alerted = true
					print(Target.Parent.Name)
				else
					NPCModule.Status.Alerted = false
				end
			end
			--Actual loop code
			if NPCModule.Status.Alerted == false or Target == nil then
				CheckForEnemies()
			elseif NPCModule.Status.Alerted == true and NPCModule.Status.Idle == true and IsToSafety == true then
				local Distance = CheckDistance()
				if Distance <= 6 then
					NPCModule.Status.Idle = false
					GoToNearestNode(Node)
					repeat
						wait()
					until NPCModule.Status.Idle == true
				end
			end
			task.wait()
		end
		repeat
			Loop()
			if NPCModule.Died == true then
				break
			end
			task.wait()
		until true == false
	end
	if NPC:IsA("Model") and NPC:FindFirstChildOfClass("Humanoid") then
		spawn(Hostile)
	else
		warn("Given model ("..(NPC.Name)..") is not a model or an humanoid.")
	end
end

local function Animate(Figure:Model?)
	local Torso = Figure:WaitForChild("Torso")
	local RightShoulder = Torso:WaitForChild("Right Shoulder")
	local LeftShoulder = Torso:WaitForChild("Left Shoulder")
	local RightHip = Torso:WaitForChild("Right Hip")
	local LeftHip = Torso:WaitForChild("Left Hip")
	local Neck = Torso:WaitForChild("Neck")
	local Humanoid = Figure:WaitForChild("Humanoid")
	local pose = "Standing"

	local currentAnim = ""
	local currentAnimInstance = nil
	local currentAnimTrack = nil
	local currentAnimKeyframeHandler = nil
	local currentAnimSpeed = 1.0
	local animTable = {}
	local animNames = { 
		idle = 	{	
			{ id = "http://www.roblox.com/asset/?id=9855834122", weight = 9 },
			{ id = "http://www.roblox.com/asset/?id=9855834122", weight = 1 }
		},
		walk = 	{ 	
			{ id = "http://www.roblox.com/asset/?id=9855810276", weight = 10 } 
		}, 
		run = 	{
			{ id = "http://www.roblox.com/asset/?id=9402703295", weight = 10 } 
		}, 
		jump = 	{
			{ id = "http://www.roblox.com/asset/?id=125750702", weight = 10 } 
		}, 
		fall = 	{
			{ id = "http://www.roblox.com/asset/?id=180436148", weight = 10 } 
		}, 
		climb = {
			{ id = "http://www.roblox.com/asset/?id=180436334", weight = 10 } 
		}, 
		sit = 	{
			{ id = "http://www.roblox.com/asset/?id=178130996", weight = 10 } 
		},	
		toolnone = {
			{ id = "http://www.roblox.com/asset/?id=9855842591", weight = 10 } 
		},
		toolslash = {
			{ id = "http://www.roblox.com/asset/?id=129967390", weight = 10 } 
			--				{ id = "slash.xml", weight = 10 } 
		},
		toollunge = {
			{ id = "http://www.roblox.com/asset/?id=129967478", weight = 10 } 
		},
		wave = {
			{ id = "http://www.roblox.com/asset/?id=128777973", weight = 10 } 
		},
		point = {
			{ id = "http://www.roblox.com/asset/?id=128853357", weight = 10 } 
		},
		dance1 = {
			{ id = "http://www.roblox.com/asset/?id=182435998", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=182491037", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=182491065", weight = 10 } 
		},
		dance2 = {
			{ id = "http://www.roblox.com/asset/?id=182436842", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=182491248", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=182491277", weight = 10 } 
		},
		dance3 = {
			{ id = "http://www.roblox.com/asset/?id=182436935", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=182491368", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=182491423", weight = 10 } 
		},
		laugh = {
			{ id = "http://www.roblox.com/asset/?id=129423131", weight = 10 } 
		},
		cheer = {
			{ id = "http://www.roblox.com/asset/?id=129423030", weight = 10 } 
		},
	}
	local dances = {"dance1", "dance2", "dance3"}

	-- Existance in this list signifies that it is an emote, the value indicates if it is a looping emote
	local emoteNames = { wave = false, point = false, dance1 = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

	local function configureAnimationSet(name, fileList)
		if (animTable[name] ~= nil) then
			for _, connection in pairs(animTable[name].connections) do
				connection:disconnect()
			end
		end
		animTable[name] = {}
		animTable[name].count = 0
		animTable[name].totalWeight = 0	
		animTable[name].connections = {}

		-- check for config values
		local config = script:FindFirstChild(name)
		if (config ~= nil) then
			--		print("Loading anims " .. name)
			table.insert(animTable[name].connections, config.ChildAdded:connect(function(child) configureAnimationSet(name, fileList) end))
			table.insert(animTable[name].connections, config.ChildRemoved:connect(function(child) configureAnimationSet(name, fileList) end))
			local idx = 1
			for _, childPart in pairs(config:GetChildren()) do
				if (childPart:IsA("Animation")) then
					table.insert(animTable[name].connections, childPart.Changed:connect(function(property) configureAnimationSet(name, fileList) end))
					animTable[name][idx] = {}
					animTable[name][idx].anim = childPart
					local weightObject = childPart:FindFirstChild("Weight")
					if (weightObject == nil) then
						animTable[name][idx].weight = 1
					else
						animTable[name][idx].weight = weightObject.Value
					end
					animTable[name].count = animTable[name].count + 1
					animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
					--			print(name .. " [" .. idx .. "] " .. animTable[name][idx].anim.AnimationId .. " (" .. animTable[name][idx].weight .. ")")
					idx = idx + 1
				end
			end
		end

		-- fallback to defaults
		if (animTable[name].count <= 0) then
			for idx, anim in pairs(fileList) do
				animTable[name][idx] = {}
				animTable[name][idx].anim = Instance.new("Animation")
				animTable[name][idx].anim.Name = name
				animTable[name][idx].anim.AnimationId = anim.id
				animTable[name][idx].weight = anim.weight
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
				--			print(name .. " [" .. idx .. "] " .. anim.id .. " (" .. anim.weight .. ")")
			end
		end
	end

	-- Setup animation objects
	local function scriptChildModified(child)
		local fileList = animNames[child.Name]
		if (fileList ~= nil) then
			configureAnimationSet(child.Name, fileList)
		end	
	end

	script.ChildAdded:connect(scriptChildModified)
	script.ChildRemoved:connect(scriptChildModified)


	for name, fileList in pairs(animNames) do 
		configureAnimationSet(name, fileList)
	end	

	-- ANIMATION

	-- declarations
	local toolAnim = "None"
	local toolAnimTime = 0

	local jumpAnimTime = 0
	local jumpAnimDuration = 0.3

	local toolTransitionTime = 0.1
	local fallTransitionTime = 0.3
	local jumpMaxLimbVelocity = 0.75

	-- functions

	local function stopAllAnimations()
		local oldAnim = currentAnim

		-- return to idle if finishing an emote
		if (emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false) then
			oldAnim = "idle"
		end

		currentAnim = ""
		currentAnimInstance = nil
		if (currentAnimKeyframeHandler ~= nil) then
			currentAnimKeyframeHandler:disconnect()
		end

		if (currentAnimTrack ~= nil) then
			currentAnimTrack:Stop()
			currentAnimTrack:Destroy()
			currentAnimTrack = nil
		end
		return oldAnim
	end

	local function setAnimationSpeed(speed)
		if speed ~= currentAnimSpeed then
			currentAnimSpeed = speed
			currentAnimTrack:AdjustSpeed(currentAnimSpeed)
		end
	end
	-- Preload animations
	local function playAnimation(animName, transitionTime, humanoid) 

		local roll = math.random(1, animTable[animName].totalWeight) 
		local origRoll = roll
		local idx = 1
		while (roll > animTable[animName][idx].weight) do
			roll = roll - animTable[animName][idx].weight
			idx = idx + 1
		end
		--		print(animName .. " " .. idx .. " [" .. origRoll .. "]")
		local anim = animTable[animName][idx].anim

		-- switch animation		
		if (anim ~= currentAnimInstance) then

			if (currentAnimTrack ~= nil) then
				currentAnimTrack:Stop(transitionTime)
				currentAnimTrack:Destroy()
			end

			currentAnimSpeed = 1.0

			-- load it to the humanoid; get AnimationTrack
			currentAnimTrack = humanoid:LoadAnimation(anim)
			currentAnimTrack.Priority = Enum.AnimationPriority.Core

			-- play the animation
			currentAnimTrack:Play(transitionTime)
			currentAnim = animName
			currentAnimInstance = anim

			-- set up keyframe name triggers
			if (currentAnimKeyframeHandler ~= nil) then
				currentAnimKeyframeHandler:disconnect()
			end
			--currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:Connect(keyFrameReachedFunc)

		end

	end
	local function keyFrameReachedFunc(frameName)
		if (frameName == "End") then

			local repeatAnim = currentAnim
			-- return to idle if finishing an emote
			if (emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false) then
				repeatAnim = "idle"
			end

			local animSpeed = currentAnimSpeed
			playAnimation(repeatAnim, 0.0, Humanoid)
			setAnimationSpeed(animSpeed)
		end
	end
	-------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------

	local toolAnimName = ""
	local toolAnimTrack = nil
	local toolAnimInstance = nil
	local currentToolAnimKeyframeHandler = nil
	local function playToolAnimation(animName, transitionTime, humanoid, priority)	 

		local roll = math.random(1, animTable[animName].totalWeight) 
		local origRoll = roll
		local idx = 1
		while (roll > animTable[animName][idx].weight) do
			roll = roll - animTable[animName][idx].weight
			idx = idx + 1
		end
		--		print(animName .. " * " .. idx .. " [" .. origRoll .. "]")
		local anim = animTable[animName][idx].anim

		if (toolAnimInstance ~= anim) then

			if (toolAnimTrack ~= nil) then
				toolAnimTrack:Stop()
				toolAnimTrack:Destroy()
				transitionTime = 0
			end

			-- load it to the humanoid; get AnimationTrack
			toolAnimTrack = humanoid:LoadAnimation(anim)
			if priority then
				toolAnimTrack.Priority = priority
			end

			-- play the animation
			toolAnimTrack:Play(transitionTime)
			toolAnimName = animName
			toolAnimInstance = anim

			currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:connect(toolKeyFrameReachedFunc)
		end
	end
	local function toolKeyFrameReachedFunc(frameName)
		if (frameName == "End") then
			--		print("Keyframe : ".. frameName)	
			playToolAnimation(toolAnimName, 0.0, Humanoid)
		end
	end

	local function stopToolAnimations()
		local oldAnim = toolAnimName

		if (currentToolAnimKeyframeHandler ~= nil) then
			currentToolAnimKeyframeHandler:disconnect()
		end

		toolAnimName = ""
		toolAnimInstance = nil
		if (toolAnimTrack ~= nil) then
			toolAnimTrack:Stop()
			toolAnimTrack:Destroy()
			toolAnimTrack = nil
		end


		return oldAnim
	end

	-------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------


	local function onRunning(speed)
		if speed > 0.01 then
			playAnimation("walk", 0.1, Humanoid)
			if currentAnimInstance and currentAnimInstance.AnimationId == "http://www.roblox.com/asset/?id=180426354" then
				setAnimationSpeed(speed / 14.5)
			end
			pose = "Running"
		else
			if emoteNames[currentAnim] == nil then
				playAnimation("idle", 0.1, Humanoid)
				pose = "Standing"
			end
		end
	end

	local function onDied()
		pose = "Dead"
	end

	local function onJumping()
		playAnimation("jump", 0.1, Humanoid)
		jumpAnimTime = jumpAnimDuration
		pose = "Jumping"
	end

	local function onClimbing(speed)
		playAnimation("climb", 0.1, Humanoid)
		setAnimationSpeed(speed / 12.0)
		pose = "Climbing"
	end

	local function onGettingUp()
		pose = "GettingUp"
	end

	local function onFreeFall()
		if (jumpAnimTime <= 0) then
			playAnimation("fall", fallTransitionTime, Humanoid)
		end
		pose = "FreeFall"
	end

	local function onFallingDown()
		pose = "FallingDown"
	end

	local function onSeated()
		pose = "Seated"
	end

	local function onPlatformStanding()
		pose = "PlatformStanding"
	end

	local function onSwimming(speed)
		if speed > 0 then
			pose = "Running"
		else
			pose = "Standing"
		end
	end

	local function getTool()	
		for _, kid in ipairs(Figure:GetChildren()) do
			if kid.className == "Tool" then return kid end
		end
		return nil
	end

	local function getToolAnim(tool)
		for _, c in ipairs(tool:GetChildren()) do
			if c.Name == "toolanim" and c.className == "StringValue" then
				return c
			end
		end
		return nil
	end

	local function animateTool()

		if (toolAnim == "None") then
			playToolAnimation("toolnone", toolTransitionTime, Humanoid, Enum.AnimationPriority.Idle)
			return
		end

		if (toolAnim == "Slash") then
			playToolAnimation("toolslash", 0, Humanoid, Enum.AnimationPriority.Action)
			return
		end

		if (toolAnim == "Lunge") then
			playToolAnimation("toollunge", 0, Humanoid, Enum.AnimationPriority.Action)
			return
		end
	end

	local function moveSit()
		RightShoulder.MaxVelocity = 0.15
		LeftShoulder.MaxVelocity = 0.15
		RightShoulder:SetDesiredAngle(3.14 /2)
		LeftShoulder:SetDesiredAngle(-3.14 /2)
		RightHip:SetDesiredAngle(3.14 /2)
		LeftHip:SetDesiredAngle(-3.14 /2)
	end

	local lastTick = 0

	local function move(time)
		local amplitude = 1
		local frequency = 1
		local deltaTime = time - lastTick
		lastTick = time

		local climbFudge = 0
		local setAngles = false

		if (jumpAnimTime > 0) then
			jumpAnimTime = jumpAnimTime - deltaTime
		end

		if (pose == "FreeFall" and jumpAnimTime <= 0) then
			playAnimation("fall", fallTransitionTime, Humanoid)
		elseif (pose == "Seated") then
			playAnimation("sit", 0.5, Humanoid)
			return
		elseif (pose == "Running") then
			playAnimation("walk", 0.1, Humanoid)
		elseif (pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding") then
			--		print("Wha " .. pose)
			stopAllAnimations()
			amplitude = 0.1
			frequency = 1
			setAngles = true
		end

		if (setAngles) then
			local desiredAngle = amplitude * math.sin(time * frequency)

			RightShoulder:SetDesiredAngle(desiredAngle + climbFudge)
			LeftShoulder:SetDesiredAngle(desiredAngle - climbFudge)
			RightHip:SetDesiredAngle(-desiredAngle)
			LeftHip:SetDesiredAngle(-desiredAngle)
		end

		-- Tool Animation handling
		local tool = getTool()
		if tool and tool:FindFirstChild("Handle") then

			local animStringValueObject = getToolAnim(tool)

			if animStringValueObject then
				toolAnim = animStringValueObject.Value
				-- message recieved, delete StringValue
				animStringValueObject.Parent = nil
				toolAnimTime = time + .3
			end

			if time > toolAnimTime then
				toolAnimTime = 0
				toolAnim = "None"
			end

			animateTool()		
		else
			stopToolAnimations()
			toolAnim = "None"
			toolAnimInstance = nil
			toolAnimTime = 0
		end
	end

	-- connect events
	Humanoid.Died:connect(onDied)
	Humanoid.Running:connect(onRunning)
	Humanoid.Jumping:connect(onJumping)
	Humanoid.Climbing:connect(onClimbing)
	Humanoid.GettingUp:connect(onGettingUp)
	Humanoid.FreeFalling:connect(onFreeFall)
	Humanoid.FallingDown:connect(onFallingDown)
	Humanoid.Seated:connect(onSeated)
	Humanoid.PlatformStanding:connect(onPlatformStanding)
	Humanoid.Swimming:connect(onSwimming)

	-- setup emote chat hook
	game:GetService("Players").LocalPlayer.Chatted:connect(function(msg)
		local emote = ""
		if msg == "/e dance" then
			emote = dances[math.random(1, #dances)]
		elseif (string.sub(msg, 1, 3) == "/e ") then
			emote = string.sub(msg, 4)
		elseif (string.sub(msg, 1, 7) == "/emote ") then
			emote = string.sub(msg, 8)
		end

		if (pose == "Standing" and emoteNames[emote] ~= nil) then
			playAnimation(emote, 0.1, Humanoid)
		end

	end)


	-- main program

	-- initialize to idle
	playAnimation("idle", 0.1, Humanoid)
	pose = "Standing"

	while Figure.Parent ~= nil do
		local _, time = wait(0.1)
		move(time)
	end
end

local function AnimateR15(Figure:Model?)
	local Character = Figure
	local Humanoid = Character:WaitForChild("Humanoid")
	local pose = "Standing"

	local userNoUpdateOnLoopSuccess, userNoUpdateOnLoopValue = pcall(function() return UserSettings():IsUserFeatureEnabled("UserNoUpdateOnLoop") end)
	local userNoUpdateOnLoop = userNoUpdateOnLoopSuccess and userNoUpdateOnLoopValue
	local userAnimationSpeedDampeningSuccess, userAnimationSpeedDampeningValue = pcall(function() return UserSettings():IsUserFeatureEnabled("UserAnimationSpeedDampening") end)
	local userAnimationSpeedDampening = userAnimationSpeedDampeningSuccess and userAnimationSpeedDampeningValue

	local AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")

	local currentAnim = ""
	local currentAnimInstance = nil
	local currentAnimTrack = nil
	local currentAnimKeyframeHandler = nil
	local currentAnimSpeed = 1.0

	local runAnimTrack = nil
	local runAnimKeyframeHandler = nil

	local animTable = {}
	local animNames = { 
		idle = 	{	
			{ id = "http://www.roblox.com/asset/?id=507766666", weight = 1 },
			{ id = "http://www.roblox.com/asset/?id=507766951", weight = 1 },
			{ id = "http://www.roblox.com/asset/?id=507766388", weight = 9 }
		},
		walk = 	{ 	
			{ id = "http://www.roblox.com/asset/?id=507777826", weight = 10 } 
		}, 
		run = 	{
			{ id = "http://www.roblox.com/asset/?id=507767714", weight = 10 } 
		}, 
		swim = 	{
			{ id = "http://www.roblox.com/asset/?id=507784897", weight = 10 } 
		}, 
		swimidle = 	{
			{ id = "http://www.roblox.com/asset/?id=507785072", weight = 10 } 
		}, 
		jump = 	{
			{ id = "http://www.roblox.com/asset/?id=507765000", weight = 10 } 
		}, 
		fall = 	{
			{ id = "http://www.roblox.com/asset/?id=507767968", weight = 10 } 
		}, 
		climb = {
			{ id = "http://www.roblox.com/asset/?id=507765644", weight = 10 } 
		}, 
		sit = 	{
			{ id = "http://www.roblox.com/asset/?id=2506281703", weight = 10 } 
		},	
		toolnone = {
			{ id = "http://www.roblox.com/asset/?id=507768375", weight = 10 } 
		},
		toolslash = {
			{ id = "http://www.roblox.com/asset/?id=522635514", weight = 10 } 
		},
		toollunge = {
			{ id = "http://www.roblox.com/asset/?id=522638767", weight = 10 } 
		},
		wave = {
			{ id = "http://www.roblox.com/asset/?id=507770239", weight = 10 } 
		},
		point = {
			{ id = "http://www.roblox.com/asset/?id=507770453", weight = 10 } 
		},
		dance = {
			{ id = "http://www.roblox.com/asset/?id=507771019", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=507771955", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=507772104", weight = 10 } 
		},
		dance2 = {
			{ id = "http://www.roblox.com/asset/?id=507776043", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=507776720", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=507776879", weight = 10 } 
		},
		dance3 = {
			{ id = "http://www.roblox.com/asset/?id=507777268", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=507777451", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=507777623", weight = 10 } 
		},
		laugh = {
			{ id = "http://www.roblox.com/asset/?id=507770818", weight = 10 } 
		},
		cheer = {
			{ id = "http://www.roblox.com/asset/?id=507770677", weight = 10 } 
		},
	}

	-- Existance in this list signifies that it is an emote, the value indicates if it is a looping emote
	local emoteNames = { wave = false, point = false, dance = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

	local PreloadAnimsUserFlag = false
	local PreloadedAnims = {}
	local successPreloadAnim, msgPreloadAnim = pcall(function()
		PreloadAnimsUserFlag = UserSettings():IsUserFeatureEnabled("UserPreloadAnimations")
	end)
	if not successPreloadAnim then
		PreloadAnimsUserFlag = false
	end

	math.randomseed(tick())

	function findExistingAnimationInSet(set, anim)
		if set == nil or anim == nil then
			return 0
		end

		for idx = 1, set.count, 1 do 
			if set[idx].anim.AnimationId == anim.AnimationId then
				return idx
			end
		end

		return 0
	end

	function configureAnimationSet(name, fileList)
		if (animTable[name] ~= nil) then
			for _, connection in pairs(animTable[name].connections) do
				connection:disconnect()
			end
		end
		animTable[name] = {}
		animTable[name].count = 0
		animTable[name].totalWeight = 0	
		animTable[name].connections = {}

		local allowCustomAnimations = true
		local AllowDisableCustomAnimsUserFlag = false

		local success, msg = pcall(function()
			AllowDisableCustomAnimsUserFlag = UserSettings():IsUserFeatureEnabled("UserAllowDisableCustomAnims2")
		end)

		if (AllowDisableCustomAnimsUserFlag) then
			local success, msg = pcall(function() allowCustomAnimations = game:GetService("StarterPlayer").AllowCustomAnimations end)
			if not success then
				allowCustomAnimations = true
			end
		end

		-- check for config values
		local config = script:FindFirstChild(name)
		if (allowCustomAnimations and config ~= nil) then
			table.insert(animTable[name].connections, config.ChildAdded:connect(function(child) configureAnimationSet(name, fileList) end))
			table.insert(animTable[name].connections, config.ChildRemoved:connect(function(child) configureAnimationSet(name, fileList) end))

			local idx = 0
			for _, childPart in pairs(config:GetChildren()) do
				if (childPart:IsA("Animation")) then
					local newWeight = 1
					local weightObject = childPart:FindFirstChild("Weight")
					if (weightObject ~= nil) then
						newWeight = weightObject.Value
					end
					animTable[name].count = animTable[name].count + 1
					idx = animTable[name].count
					animTable[name][idx] = {}
					animTable[name][idx].anim = childPart
					animTable[name][idx].weight = newWeight
					animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
					table.insert(animTable[name].connections, childPart.Changed:connect(function(property) configureAnimationSet(name, fileList) end))
					table.insert(animTable[name].connections, childPart.ChildAdded:connect(function(property) configureAnimationSet(name, fileList) end))
					table.insert(animTable[name].connections, childPart.ChildRemoved:connect(function(property) configureAnimationSet(name, fileList) end))
				end
			end
		end

		-- fallback to defaults
		if (animTable[name].count <= 0) then
			for idx, anim in pairs(fileList) do
				animTable[name][idx] = {}
				animTable[name][idx].anim = Instance.new("Animation")
				animTable[name][idx].anim.Name = name
				animTable[name][idx].anim.AnimationId = anim.id
				animTable[name][idx].weight = anim.weight
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
			end
		end

		-- preload anims
		if PreloadAnimsUserFlag then
			for i, animType in pairs(animTable) do
				for idx = 1, animType.count, 1 do
					if PreloadedAnims[animType[idx].anim.AnimationId] == nil then
						Humanoid:LoadAnimation(animType[idx].anim)
						PreloadedAnims[animType[idx].anim.AnimationId] = true
					end				
				end
			end
		end
	end

	------------------------------------------------------------------------------------------------------------

	function configureAnimationSetOld(name, fileList)
		if (animTable[name] ~= nil) then
			for _, connection in pairs(animTable[name].connections) do
				connection:disconnect()
			end
		end
		animTable[name] = {}
		animTable[name].count = 0
		animTable[name].totalWeight = 0	
		animTable[name].connections = {}

		local allowCustomAnimations = true
		local AllowDisableCustomAnimsUserFlag = false

		local success, msg = pcall(function()
			AllowDisableCustomAnimsUserFlag = UserSettings():IsUserFeatureEnabled("UserAllowDisableCustomAnims2")
		end)

		if (AllowDisableCustomAnimsUserFlag) then
			local success, msg = pcall(function() allowCustomAnimations = game:GetService("StarterPlayer").AllowCustomAnimations end)
			if not success then
				allowCustomAnimations = true
			end
		end

		-- check for config values
		local config = script:FindFirstChild(name)
		if (allowCustomAnimations and config ~= nil) then
			table.insert(animTable[name].connections, config.ChildAdded:connect(function(child) configureAnimationSet(name, fileList) end))
			table.insert(animTable[name].connections, config.ChildRemoved:connect(function(child) configureAnimationSet(name, fileList) end))
			local idx = 1
			for _, childPart in pairs(config:GetChildren()) do
				if (childPart:IsA("Animation")) then
					table.insert(animTable[name].connections, childPart.Changed:connect(function(property) configureAnimationSet(name, fileList) end))
					animTable[name][idx] = {}
					animTable[name][idx].anim = childPart
					local weightObject = childPart:FindFirstChild("Weight")
					if (weightObject == nil) then
						animTable[name][idx].weight = 1
					else
						animTable[name][idx].weight = weightObject.Value
					end
					animTable[name].count = animTable[name].count + 1
					animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
					idx = idx + 1
				end
			end
		end

		-- fallback to defaults
		if (animTable[name].count <= 0) then
			for idx, anim in pairs(fileList) do
				animTable[name][idx] = {}
				animTable[name][idx].anim = Instance.new("Animation")
				animTable[name][idx].anim.Name = name
				animTable[name][idx].anim.AnimationId = anim.id
				animTable[name][idx].weight = anim.weight
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
				-- print(name .. " [" .. idx .. "] " .. anim.id .. " (" .. anim.weight .. ")")
			end
		end

		-- preload anims
		if PreloadAnimsUserFlag then
			for i, animType in pairs(animTable) do
				for idx = 1, animType.count, 1 do 
					Humanoid:LoadAnimation(animType[idx].anim)
				end
			end
		end
	end

	-- Setup animation objects
	function scriptChildModified(child)
		local fileList = animNames[child.Name]
		if (fileList ~= nil) then
			configureAnimationSet(child.Name, fileList)
		end	
	end

	script.ChildAdded:connect(scriptChildModified)
	script.ChildRemoved:connect(scriptChildModified)


	for name, fileList in pairs(animNames) do 
		configureAnimationSet(name, fileList)
	end	

	-- ANIMATION

	-- declarations
	local toolAnim = "None"
	local toolAnimTime = 0

	local jumpAnimTime = 0
	local jumpAnimDuration = 0.31

	local toolTransitionTime = 0.1
	local fallTransitionTime = 0.2

	-- functions

	function stopAllAnimations()
		local oldAnim = currentAnim

		-- return to idle if finishing an emote
		if (emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false) then
			oldAnim = "idle"
		end

		currentAnim = ""
		currentAnimInstance = nil
		if (currentAnimKeyframeHandler ~= nil) then
			currentAnimKeyframeHandler:disconnect()
		end

		if (currentAnimTrack ~= nil) then
			currentAnimTrack:Stop()
			currentAnimTrack:Destroy()
			currentAnimTrack = nil
		end

		-- clean up walk if there is one
		if (runAnimKeyframeHandler ~= nil) then
			runAnimKeyframeHandler:disconnect()
		end

		if (runAnimTrack ~= nil) then
			runAnimTrack:Stop()
			runAnimTrack:Destroy()
			runAnimTrack = nil
		end

		return oldAnim
	end

	function getHeightScale()
		if Humanoid then
			local scale = Humanoid.HipHeight / 1.35
			if userAnimationSpeedDampening then
				if AnimationSpeedDampeningObject == nil then
					AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")
				end
				if AnimationSpeedDampeningObject ~= nil then
					scale = 1 + (Humanoid.HipHeight - 1.35) * AnimationSpeedDampeningObject.Value / 1.35
				end
			end
			return scale
		end	
		return 1
	end

	local smallButNotZero = 0.0001
	function setRunSpeed(speed)
		local speedScaled = speed * 1.25
		local heightScale = getHeightScale()
		local runSpeed = speedScaled / heightScale

		if runSpeed ~= currentAnimSpeed then
			if runSpeed < 0.33 then
				currentAnimTrack:AdjustWeight(1.0)		
				runAnimTrack:AdjustWeight(smallButNotZero)
			elseif runSpeed < 0.66 then
				local weight = ((runSpeed - 0.33) / 0.33)
				currentAnimTrack:AdjustWeight(1.0 - weight + smallButNotZero)
				runAnimTrack:AdjustWeight(weight + smallButNotZero)
			else
				currentAnimTrack:AdjustWeight(smallButNotZero)
				runAnimTrack:AdjustWeight(1.0)
			end
			currentAnimSpeed = runSpeed
			runAnimTrack:AdjustSpeed(runSpeed)
			currentAnimTrack:AdjustSpeed(runSpeed)
		end	
	end

	function setAnimationSpeed(speed)
		if currentAnim == "walk" then
			setRunSpeed(speed)
		else
			if speed ~= currentAnimSpeed then
				currentAnimSpeed = speed
				currentAnimTrack:AdjustSpeed(currentAnimSpeed)
			end
		end
	end

	function keyFrameReachedFunc(frameName)
		if (frameName == "End") then
			if currentAnim == "walk" then
				if userNoUpdateOnLoop == true then
					if runAnimTrack.Looped ~= true then
						runAnimTrack.TimePosition = 0.0
					end
					if currentAnimTrack.Looped ~= true then
						currentAnimTrack.TimePosition = 0.0
					end
				else
					runAnimTrack.TimePosition = 0.0
					currentAnimTrack.TimePosition = 0.0
				end
			else
				local repeatAnim = currentAnim
				-- return to idle if finishing an emote
				if (emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false) then
					repeatAnim = "idle"
				end

				local animSpeed = currentAnimSpeed
				playAnimation(repeatAnim, 0.15, Humanoid)
				setAnimationSpeed(animSpeed)
			end
		end
	end

	function rollAnimation(animName)
		local roll = math.random(1, animTable[animName].totalWeight) 
		local origRoll = roll
		local idx = 1
		while (roll > animTable[animName][idx].weight) do
			roll = roll - animTable[animName][idx].weight
			idx = idx + 1
		end
		return idx
	end

	function playAnimation(animName, transitionTime, humanoid) 	
		local idx = rollAnimation(animName)
		local anim = animTable[animName][idx].anim

		-- switch animation		
		if (anim ~= currentAnimInstance) then

			if (currentAnimTrack ~= nil) then
				currentAnimTrack:Stop(transitionTime)
				currentAnimTrack:Destroy()
			end

			if (runAnimTrack ~= nil) then
				runAnimTrack:Stop(transitionTime)
				runAnimTrack:Destroy()
				if userNoUpdateOnLoop == true then
					runAnimTrack = nil
				end
			end

			currentAnimSpeed = 1.0

			-- load it to the humanoid; get AnimationTrack
			currentAnimTrack = humanoid:LoadAnimation(anim)
			currentAnimTrack.Priority = Enum.AnimationPriority.Core

			-- play the animation
			currentAnimTrack:Play(transitionTime)
			currentAnim = animName
			currentAnimInstance = anim

			-- set up keyframe name triggers
			if (currentAnimKeyframeHandler ~= nil) then
				currentAnimKeyframeHandler:disconnect()
			end
			currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)

			-- check to see if we need to blend a walk/run animation
			if animName == "walk" then
				local runAnimName = "run"
				local runIdx = rollAnimation(runAnimName)

				runAnimTrack = humanoid:LoadAnimation(animTable[runAnimName][runIdx].anim)
				runAnimTrack.Priority = Enum.AnimationPriority.Core
				runAnimTrack:Play(transitionTime)		

				if (runAnimKeyframeHandler ~= nil) then
					runAnimKeyframeHandler:disconnect()
				end
				runAnimKeyframeHandler = runAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)	
			end
		end

	end

	-------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------

	local toolAnimName = ""
	local toolAnimTrack = nil
	local toolAnimInstance = nil
	local currentToolAnimKeyframeHandler = nil

	function toolKeyFrameReachedFunc(frameName)
		if (frameName == "End") then
			playToolAnimation(toolAnimName, 0.0, Humanoid)
		end
	end


	function playToolAnimation(animName, transitionTime, humanoid, priority)	 		
		local idx = rollAnimation(animName)
		local anim = animTable[animName][idx].anim

		if (toolAnimInstance ~= anim) then

			if (toolAnimTrack ~= nil) then
				toolAnimTrack:Stop()
				toolAnimTrack:Destroy()
				transitionTime = 0
			end

			-- load it to the humanoid; get AnimationTrack
			toolAnimTrack = humanoid:LoadAnimation(anim)
			if priority then
				toolAnimTrack.Priority = priority
			end

			-- play the animation
			toolAnimTrack:Play(transitionTime)
			toolAnimName = animName
			toolAnimInstance = anim

			currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:connect(toolKeyFrameReachedFunc)
		end
	end

	function stopToolAnimations()
		local oldAnim = toolAnimName

		if (currentToolAnimKeyframeHandler ~= nil) then
			currentToolAnimKeyframeHandler:disconnect()
		end

		toolAnimName = ""
		toolAnimInstance = nil
		if (toolAnimTrack ~= nil) then
			toolAnimTrack:Stop()
			toolAnimTrack:Destroy()
			toolAnimTrack = nil
		end

		return oldAnim
	end

	-------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------
	-- STATE CHANGE HANDLERS

	function onRunning(speed)
		if speed > 0.5 then
			local scale = 16.0
			playAnimation("walk", 0.2, Humanoid)
			setAnimationSpeed(speed / scale)
			pose = "Running"
		else
			if emoteNames[currentAnim] == nil then
				playAnimation("idle", 0.2, Humanoid)
				pose = "Standing"
			end
		end
	end

	function onDied()
		pose = "Dead"
	end

	function onJumping()
		playAnimation("jump", 0.1, Humanoid)
		jumpAnimTime = jumpAnimDuration
		pose = "Jumping"
	end

	function onClimbing(speed)
		local scale = 5.0
		playAnimation("climb", 0.1, Humanoid)
		setAnimationSpeed(speed / scale)
		pose = "Climbing"
	end

	function onGettingUp()
		pose = "GettingUp"
	end

	function onFreeFall()
		if (jumpAnimTime <= 0) then
			playAnimation("fall", fallTransitionTime, Humanoid)
		end
		pose = "FreeFall"
	end

	function onFallingDown()
		pose = "FallingDown"
	end

	function onSeated()
		pose = "Seated"
	end

	function onPlatformStanding()
		pose = "PlatformStanding"
	end

	-------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------

	function onSwimming(speed)
		if speed > 1.00 then
			local scale = 10.0
			playAnimation("swim", 0.4, Humanoid)
			setAnimationSpeed(speed / scale)
			pose = "Swimming"
		else
			playAnimation("swimidle", 0.4, Humanoid)
			pose = "Standing"
		end
	end

	function animateTool()
		if (toolAnim == "None") then
			playToolAnimation("toolnone", toolTransitionTime, Humanoid, Enum.AnimationPriority.Idle)
			return
		end

		if (toolAnim == "Slash") then
			playToolAnimation("toolslash", 0, Humanoid, Enum.AnimationPriority.Action)
			return
		end

		if (toolAnim == "Lunge") then
			playToolAnimation("toollunge", 0, Humanoid, Enum.AnimationPriority.Action)
			return
		end
	end

	function getToolAnim(tool)
		for _, c in ipairs(tool:GetChildren()) do
			if c.Name == "toolanim" and c.className == "StringValue" then
				return c
			end
		end
		return nil
	end

	local lastTick = 0

	function stepAnimate(currentTime)
		local amplitude = 1
		local frequency = 1
		local deltaTime = currentTime - lastTick
		lastTick = currentTime

		local climbFudge = 0
		local setAngles = false

		if (jumpAnimTime > 0) then
			jumpAnimTime = jumpAnimTime - deltaTime
		end

		if (pose == "FreeFall" and jumpAnimTime <= 0) then
			playAnimation("fall", fallTransitionTime, Humanoid)
		elseif (pose == "Seated") then
			playAnimation("sit", 0.5, Humanoid)
			return
		elseif (pose == "Running") then
			playAnimation("walk", 0.2, Humanoid)
		elseif (pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding") then
			stopAllAnimations()
			amplitude = 0.1
			frequency = 1
			setAngles = true
		end

		-- Tool Animation handling
		local tool = Character:FindFirstChildOfClass("Tool")
		if tool and tool:FindFirstChild("Handle") then
			local animStringValueObject = getToolAnim(tool)

			if animStringValueObject then
				toolAnim = animStringValueObject.Value
				-- message recieved, delete StringValue
				animStringValueObject.Parent = nil
				toolAnimTime = currentTime + .3
			end

			if currentTime > toolAnimTime then
				toolAnimTime = 0
				toolAnim = "None"
			end

			animateTool()		
		else
			stopToolAnimations()
			toolAnim = "None"
			toolAnimInstance = nil
			toolAnimTime = 0
		end
	end

	-- connect events
	Humanoid.Died:connect(onDied)
	Humanoid.Running:connect(onRunning)
	Humanoid.Jumping:connect(onJumping)
	Humanoid.Climbing:connect(onClimbing)
	Humanoid.GettingUp:connect(onGettingUp)
	Humanoid.FreeFalling:connect(onFreeFall)
	Humanoid.FallingDown:connect(onFallingDown)
	Humanoid.Seated:connect(onSeated)
	Humanoid.PlatformStanding:connect(onPlatformStanding)
	Humanoid.Swimming:connect(onSwimming)

	-- setup emote chat hook
	game:GetService("Players").LocalPlayer.Chatted:connect(function(msg)
		local emote = ""
		if (string.sub(msg, 1, 3) == "/e ") then
			emote = string.sub(msg, 4)
		elseif (string.sub(msg, 1, 7) == "/emote ") then
			emote = string.sub(msg, 8)
		end

		if (pose == "Standing" and emoteNames[emote] ~= nil) then
			playAnimation(emote, 0.1, Humanoid)
		end
	end)



	-- initialize to idle
	playAnimation("idle", 0.1, Humanoid)
	pose = "Standing"

	-- loop to handle timed state transitions and tool animations
	while Character.Parent ~= nil do
		local _, currentGameTime = wait(0.1)
		stepAnimate(currentGameTime)
	end
end

local function LookAt(Figure:Model?)
	--/// Written by: NyaRemi
	--/// Original Head/Waist Script: [https://www.roblox.com/library/1000161193]
	--/// Description: Head/Waist movement script for NPC
	--/// Updates: 6


	------------------ [[ Cofigurations ]] ------------------

	-- [ BASIC ] --
	local LookAtPlayerRange = 30 -- Distance away that NPC can looks
	local LookAtNonPlayer = true -- Looks at other humanoid that isn't player

	-- [Head, Torso, HumanoidRootPart], "Torso" and "UpperTorso" works with both R6 and R15.
	-- Also make sure to not misspell it.
	local PartToLookAt = "Head" -- What should the npc look at. If player doesn't has the specific part it'll looks for RootPart instead.

	local LookBackOnNil = true -- Should the npc look at back straight when player is out of range.

	local SearchLoc = {workspace} -- Will get player from these locations


	-- [ ADVANCED ] --
--[[
	[Horizontal and Vertical limits for head and body tracking.]
	Setting to 0 negates tracking, setting to 1 is normal tracking, and setting to anything higher than 1 goes past real life head/body rotation capabilities.
--]]
	local HeadHorFactor = 1
	local HeadVertFactor = 1
	local BodyHorFactor = 1
	local BodyVertFactor = 1

	-- Don't set this above 1, it will cause glitchy behaviour.
	local UpdateSpeed = 0.3 -- How fast the body will rotates.
	local UpdateDelay = 0.05 -- How fast the heartbeat will update.

	-------------------------------------------------------
	wait(1)



	--
	local Ang = CFrame.Angles
	local aTan = math.atan
	--
	local Players = game:GetService("Players")
	--------------------------------------------
	local Body = Figure

	local Head = Body:WaitForChild("Head")
	local Hum = Body:WaitForChild("Humanoid")
	local Core = Body:WaitForChild("HumanoidRootPart")
	local IsR6 = (Hum.RigType.Value==0)
	local Trso = (IsR6 and Body:WaitForChild("Torso")) or Body:WaitForChild("UpperTorso")
	local Neck = (IsR6 and Trso:WaitForChild("Neck")) or Head:WaitForChild("Neck")	
	local Waist = (not IsR6 and Trso:WaitForChild("Waist"))

	local NeckOrgnC0 = Neck.C0
	local WaistOrgnC0 = (not IsR6 and Waist.C0)

	local LookingAtValue = Instance.new("ObjectValue"); LookingAtValue.Parent = Body; LookingAtValue.Name = "LookingAt"
	--------------------------------------------


	-- Necessery Functions

	local ErrorPart = nil
	local function GetValidPartToLookAt(Char, bodypart)
		local pHum = Char:FindFirstChild("Humanoid")
		if not Char and pHum then return nil end
		local pIsR6 = (pHum.RigType.Value==0)
		if table.find({"Torso", "UpperTorso"}, bodypart) then
			if pIsR6 then bodypart = "Torso" else bodypart = "UpperTorso" end
		end
		local ValidPart = Char:FindFirstChild(bodypart) or Char:FindFirstChild("HumanoidRootPart")
		if ValidPart then return ValidPart else
			if ErrorPart ~= bodypart then
				--warn(Body.Name.." can't find part to look: "..tostring(bodypart))
				ErrorPart = bodypart
			end
			return nil end
	end

	local function getClosestPlayer() -- Get the closest player in the range.
		local closest_player, closest_distance = nil, LookAtPlayerRange
		for i = 1, #SearchLoc do
			for _, player in pairs(SearchLoc[i]:GetChildren()) do
				if player:FindFirstChild("Humanoid") and player ~= Body 
					and (Players:GetPlayerFromCharacter(player) or LookAtNonPlayer) 
					and GetValidPartToLookAt(player, PartToLookAt) then

					local distance = (Core.Position - player.PrimaryPart.Position).Magnitude
					if distance < closest_distance then
						closest_player = player
						closest_distance = distance
					end
				end
			end
		end
		return closest_player
	end

	local function rWait(n)
		n = n or 0.05
		local startTime = os.clock()

		while os.clock() - startTime < n do
			game:GetService("RunService").Heartbeat:Wait()
		end
	end

	local function LookAt(NeckC0, WaistC0)
		if not IsR6 then
			if Neck then Neck.C0 = Neck.C0:lerp(NeckC0, UpdateSpeed/2) end
			if Waist then Waist.C0 = Waist.C0:lerp(WaistC0, UpdateSpeed/2) end
		else
			if Neck then Neck.C0 = Neck.C0:lerp(NeckC0, UpdateSpeed/2) end
		end
	end

	--------------------------------------------

	game:GetService("RunService").Heartbeat:Connect(function()
		rWait(UpdateDelay)
		local TrsoLV = Trso.CFrame.lookVector
		local HdPos = Head.CFrame.p
		local player = getClosestPlayer()
		local LookAtPart
		if Neck or Waist then
			if player then
				local success, err = pcall(function()
					LookAtPart = GetValidPartToLookAt(player, PartToLookAt)
					if LookAtPart then
						local Dist = nil;
						local Diff = nil;
						local is_in_front = Core.CFrame:ToObjectSpace(LookAtPart.CFrame).Z < 0
						if is_in_front then
							if LookingAtValue.Value ~= player then
								LookingAtValue.Value = player
							end

							Dist = (Head.CFrame.p-LookAtPart.CFrame.p).magnitude
							Diff = Head.CFrame.Y-LookAtPart.CFrame.Y

							if not IsR6 then
								LookAt(NeckOrgnC0*Ang(-(aTan(Diff/Dist)*HeadVertFactor), (((HdPos-LookAtPart.CFrame.p).Unit):Cross(TrsoLV)).Y*HeadHorFactor, 0), 
									WaistOrgnC0*Ang(-(aTan(Diff/Dist)*BodyVertFactor), (((HdPos-LookAtPart.CFrame.p).Unit):Cross(TrsoLV)).Y*BodyHorFactor, 0))
							else	
								LookAt(NeckOrgnC0*Ang((aTan(Diff/Dist)*HeadVertFactor), 0, (((HdPos-LookAtPart.CFrame.p).Unit):Cross(TrsoLV)).Y*HeadHorFactor))
							end
						elseif LookBackOnNil then
							LookAt(NeckOrgnC0, WaistOrgnC0)
							if LookingAtValue.Value then
								LookingAtValue.Value = nil
							end
						end
					end
				end)
			elseif LookBackOnNil then
				LookAt(NeckOrgnC0, WaistOrgnC0)
				if LookingAtValue.Value then
					LookingAtValue.Value = nil
				end
			end
		end
	end)
end

function module:AddAnimateComponent(NPC:Model?)
	task.spawn(Animate, NPC)
end

function module:AddAnimateR15Component(NPC:Model?)
	task.spawn(AnimateR15, NPC)
end

function module:AddLookAtComponent(NPC:Model?)
	task.spawn(LookAt, NPC)
end
return module
