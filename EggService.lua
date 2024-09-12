-------------------------- Framework --------------------------

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TextChatService = game:GetService("TextChatService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Camera = workspace.CurrentCamera
local Terrain = workspace.Terrain

-------------------------- Framework --------------------------

---------------------- Services ----------------------

local Network = Services:GetService("Network")
local MaidClass = Services:GetService("MaidClass")
local math = Services:GetService("MathUtility")
local TweenService = Services:GetService("TweenV2")
local GuiService = Services:GetService("GuiService")
local PetModule = Services:GetService("PetModule")
local PetColorService = Services:GetService("PetColorService")
local ApplyWordColor = Services:GetService("ApplyWordColor")
local Short = Services:GetService("Short")
local RichTextService = Services:GetService("RichTextService")
local InputManager = Services:GetService("InputManager")
local MutationModule = Services:GetService("MutationModule")
local TextAnimationService = Services:GetService("TextAnimationService")
local KeyframeService = Services:GetService("KeyframeService")
local SoundService = Services:GetService("SoundService")
local CameraShaker = Services:GetService("CameraShaker")
local RaritiesModule = Services:GetService("RaritiesModule")
local VFXService = Services:GetService("VFXService")

---------------------- Services ----------------------

local Hatching = false
local EggService = {}

function EggService:CalculateOffset(EggNumber)
	local HatchInfo = self.HatchInfo
	local Pets = HatchInfo.Pets or {}
	local EggCount = #Pets

	if (EggCount == 6) then
		local HalfCount = EggCount / 2
		local Row = math.floor((EggNumber - 1) / 3)
		local Number = -((HalfCount / 2 - (EggNumber - Row * 3)) / HalfCount + 0.5 / HalfCount)

		local yOffset = Row * 4 - 2
		local zOffset = 0 - (8 + math.abs(Number * 4))

		local BaseOffset = CFrame.new(Number * HalfCount * 3, yOffset, zOffset) * CFrame.Angles(0, math.rad(Number * 20), 0)

		local Z = (EggNumber ~= 2 and EggNumber ~= 5) and (-0.5) or (0.5)
		
		BaseOffset = BaseOffset * CFrame.new(0, 0, Z)

		return BaseOffset, Z
	end

	local Number = -((EggCount / 2 - EggNumber) / EggCount + 0.5 / EggCount)
	local BaseOffset = CFrame.new(Number * EggCount * 3, 0, 0 - (6 + math.abs(Number * 4))) * CFrame.Angles(0, math.rad(Number * 20), 0)

	if (EggCount == 3) then
		local Z = (EggNumber ~= 2) and (-0.5) or (0.5)
		
		BaseOffset = BaseOffset * CFrame.new(0, 0, Z)
		
		return BaseOffset, Z
	end

	return BaseOffset, 0
end

function EggService:GetTimerInfo(PetData)
	local HatchInfo = self.HatchInfo
	local Speed = HatchInfo.Speed
	
	local isSecret = (PetData.Rarity == "Secret") or (PetData.Rarity == "Mystic")
	
	return {
		DropTime = 1 / Speed,
		RotationCount = 20 * (isSecret and 2 or 1),
		RotateTime = .25 / Speed,
		SwitchTime = .75 / Speed,
		SpinTime = .15 / Speed
	}
end

function EggService:FinishHatchAnimation()
	local HatchInfo = self.HatchInfo
	
	if not HatchInfo then
		return self:CleanThread()
	end
	
	local Pets = HatchInfo.Pets or {}
	
	self.AnimationIndex += 1
	
	if self.AnimationIndex >= #Pets then
		return self:CleanThread()
	end
end

function EggService:FixModel(Model)
	for _, base in Model:GetDescendants() do
		if not base:IsA("BasePart") then
			continue
		end
		
		base.Anchored = true
		base.CanCollide = false
	end
end

function EggService:ApplyParticles(Holder, ParticleName, EmitCount, ParticleTime)
	local HatchInfo = self.HatchInfo
	
	local Particles = script.Particles
	local ParticleHolder = Particles:FindFirstChild(ParticleName)
	
	if HatchInfo.ContainsSecret and ((ParticleName ~= "Secret") and (ParticleName ~= "Mystic")) then
		return
	end
	
	if not ParticleHolder then
		return
	end
	
	HatchInfo.ParticleActive = true
	
	for _, Object in ParticleHolder:GetChildren() do
		local Particle = Object:Clone()

		Particle.Parent = Holder
		
		if EmitCount then
			Particle:Emit(EmitCount) continue
		end
		
		Particle.Enabled = true

		task.delay(ParticleTime or Random.new():NextNumber() / 2, function()
			Particle.Enabled = false
			Debris:AddItem(Particle, 1)
		end)
	end
end

function EggService:PlayHatchAnimation(i)
	local HatchInfo = self.HatchInfo
	local Maid = self.Maid
	local Egg = HatchInfo.Egg
	local Pets = HatchInfo.Pets or {}
	local Speed = HatchInfo.Speed or 0
	local Pet = Pets[i]
	
	if not Pet then
		return self:FinishHatchAnimation()
	end
	
	local PetModel = Assets.Pets:FindFirstChild(Pet.Name) or Assets.Melees:FindFirstChild(Pet.Name)
	local EggModel = Assets.Eggs:FindFirstChild(Egg)
	
	if not PetModel or not EggModel then
		return self:FinishHatchAnimation()
	end
	
	local PlayerData = Network:Call("GetClientData")
	local Settings = PlayerData.Settings
	local isLowQuality = Settings["Low Quality"]
	
	local AutoDelete = PlayerData.AutoDelete or {}
	
	local PetData = PetModule[Pet.Name]
	local PetRarity = PetData.Rarity
	
	local TimerInfo = self:GetTimerInfo({
		Rarity = PetRarity
	})
	
	local DropTime = TimerInfo.DropTime
	local SwitchTime = TimerInfo.SwitchTime
	local RotateTime = TimerInfo.RotateTime
	local SpinTime = TimerInfo.SpinTime
	
	local PetModel = Maid:GiveTask(PetModel:Clone())
	local EggModel = Maid:GiveTask(EggModel:Clone())
	
	if (Pet.Mutation ~= 0) then
		local MutationModel = Assets.Mutated_Pets:FindFirstChild(
			("%s_%s"):format(Pet.Name, Pet.Mutation)
		);
		
		if not MutationModel then
			return
		end
		
		PetModel = MutationModel:Clone()
	end
	
	PetModel.Name = Pet.Name
	
	self:FixModel(PetModel)
	self:FixModel(EggModel)
	
	local HatchDisplay = Maid:GiveTask(script.UI.HatchDisplay:Clone())
	
	for _, Label in HatchDisplay:GetChildren() do
		if not Label:IsA("TextLabel") then
			continue
		end

		Label.TextTransparency = 1
	end
	
	HatchDisplay.Parent = GuiService.MainGui
	
	local DeletedLabel = HatchDisplay.Deleted
	local PetLabel = HatchDisplay.PetName
	local RarityLabel = HatchDisplay.PetRarity
	local MutationLabel = HatchDisplay.PetMutation
	
	DeletedLabel.Visible = table.find(AutoDelete, Pet.Name) and true or false
	PetLabel.Text = Pet.Name
	RarityLabel.Text = PetRarity
	
	MutationLabel.Visible = Pet.Mutation ~= 0
	MutationLabel.Text = (Pet.Mutation == 1) and ("Mutated I") or ("Mutated II")
	
	TextAnimationService:AnimateText(
		MutationLabel,
		tostring(Pet.Mutation)
	)
	
	TextAnimationService:AnimateText(
		RarityLabel,
		PetRarity
	)
	
	local Start = tick()
	
	EggModel.Parent = Terrain
	
	local OffsetCFrame, ZOffset = self:CalculateOffset(i)
	
	local Positioner = Maid:GiveTask(Instance.new("CFrameValue"))
	Positioner.Value = CFrame.new(0, 5, 0)
	
	local TargetModels = {
		EggModel,
		PetModel
	}
	
	local PetOffset = CFrame.new(0, -1, 0)
	local AngularOffset = CFrame.Angles(0, math.rad(180), 0)

	Maid:GiveTask(RunService.RenderStepped:Connect(function()
		if self.ParticleHolder then
			self.ParticleHolder.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 1, -1)
		end

		for _, Target in TargetModels do
			Target:PivotTo(Camera.CFrame * OffsetCFrame * Positioner.Value * AngularOffset * ((Target == PetModel) and PetOffset or CFrame.new()))
		end

		if not PetModel or not PetModel.PrimaryPart then
			return
		end

		local DisplayLocation = Camera:WorldToScreenPoint(PetModel.PrimaryPart.Position)

		HatchDisplay.Size = UDim2.fromScale(
			0.6 - (DisplayLocation.Z / 10 - 0.6),
			0.6 - (DisplayLocation.Z / 10 - 0.6)
		)

		HatchDisplay.Position = UDim2.fromOffset(
			DisplayLocation.X,
			(DisplayLocation.Y - 50) + ZOffset
		)
	end))
	
	TweenService:Create(
		Positioner,
		TweenInfo.new(
			DropTime,
			Enum.EasingStyle.Bounce,
			Enum.EasingDirection.Out
		),
		{
			Value = CFrame.new()
		}
	):Play()
	
	task.wait(DropTime)
	
	local Origin = Positioner.Value
	
	local Start = tick()
	local EggGrowSpeed = 3
	
	local EggScale = EggModel:GetScale()
	
	Maid:GiveTask(RunService.RenderStepped:Connect(function()
		local Update = (tick() - Start) / EggGrowSpeed
		
		if PetRarity ~= "Secret" and PetRarity ~= "Mystic" then
			return
		end
		
		if Update >= 1 then
			return
		end

		EggModel:ScaleTo(
			math.Lerp(
				EggScale,
				EggScale + .4,
				Update
			)
		)
	end))
	
	local ShakeInstance = ((PetRarity == "Secret") or (PetRarity == "Mystic")) and CameraShaker.new(Enum.RenderPriority.Camera.Value, function(ShakeCFrame)
		Camera.CFrame = Camera.CFrame * ShakeCFrame
	end)
	
	local Shake
	
	local FadeTime = (RotateTime * (TimerInfo.RotationCount/2))/2
	
	if ShakeInstance then
		ShakeInstance:Start()
	
		Shake = ShakeInstance:StartShake(4, 6, FadeTime)
	end
	
	for i = 1, TimerInfo.RotationCount do
		local RotateTime = RotateTime / (i / 2)
		
		task.wait(RotateTime)
		
		TweenService:Create(
			Positioner,
			TweenInfo.new(
				RotateTime,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.Out
			),
			{
				Value = Origin * CFrame.Angles(0, 0, math.rad(((i % 2) - 0.5) * 2 * 20))
			}
		):Play()

		SoundService:PlaySound(
			"Pop_1",
			.05
		)
	end
	
	SoundService:PlaySound(
		"Pop_2",
		.2
	)
	
	for _, Label in HatchDisplay:GetChildren() do
		if not Label:IsA("TextLabel") then
			continue
		end
		
		TweenService:Create(
			Label,
			TweenInfo.new(
				SwitchTime,
				Enum.EasingStyle.Sine
			),
			{
				TextTransparency = 0
			}
		):Play()
	end
	
	Positioner.Value = Origin * CFrame.Angles(0, -(45 / 2)/math.pi, 0)
	
	pcall(function()
		EggModel.Parent = nil
		PetModel.Parent = Terrain
	end)
	
	local PauseTime = 5

	local ParticleHideTime = SwitchTime + (i * 0.03) + (SpinTime * PauseTime)
	local ParticleTimer = ParticleHideTime - (ParticleHideTime/PauseTime)

	local ParticleHolder = not isLowQuality and (self.ParticleHolder or Maid:GiveTask(
		Instance.new("Part", workspace.Terrain)
	));

	if ParticleHolder then
		ParticleHolder.Name = "ParticleHolder"
		ParticleHolder.Transparency = 1
		ParticleHolder.Anchored = true
		ParticleHolder.CanCollide = false

		ParticleHolder.Size = Vector3.new(8.74 * 2, 1 * 2, 2 * 2)
	end

	if not HatchInfo.ParticleActive and ParticleHolder then
		self:ApplyParticles(
			ParticleHolder,
			PetRarity,
			nil,
			ParticleTimer
		)
	end

	self.ParticleHolder = ParticleHolder
	
	TweenService:Create(
		Positioner,
		TweenInfo.new(
			SpinTime,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Value = Origin
		}
	):Play()
	
	if (PetRarity == "Secret") or (PetRarity == "Legendary") or (PetRarity == "Mystic") then
		SoundService:PlaySound(
			PetRarity,
			.2
		)
		
		if PetRarity == "Mystic" then
			SoundService:PlaySound(
				"Magic",
				.5
			)
		end
	end
		
	SoundService:PlaySound(
		"Sparkle",
		.2
	)
	
	SoundService:PlaySound(
		"Reveal",
		.1
	)
	
	VFXService:EmitVFX("Reveal", workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -1))
	
	local PetScale = PetModel:GetScale()
	local AnimationStart = tick()
	local AnimationSpeed = 3.5
	
	Maid:GiveTask(RunService.RenderStepped:Connect(function()
		local Update = (tick() - AnimationStart) * AnimationSpeed

		if Update >= 1 then
			return
		end

		PetModel:ScaleTo(
			math.Lerp(
				PetScale,
				PetScale + .1,
				math.sin(Update * math.pi)
			)
		)
	end))
	
	task.wait(ParticleHideTime)
	task.wait(((PetRarity == "Secret") or (PetRarity == "Mystic")) and .5 or 0)
	
	if Shake then
		Shake:StartFadeOut(FadeTime)
		
		task.delay(FadeTime, function()
			if not ShakeInstance then
				return
			end
			
			ShakeInstance:Destroy()
		end)
	end
	
	TweenService:Create(
		Positioner,
		TweenInfo.new(
			SwitchTime,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.In
		),
		{
			Value = CFrame.new(0, -12, 0)
		}
	):Play()
	
	task.wait(SwitchTime)
	
	PetModel:Destroy()
	
	self:FinishHatchAnimation()
end

function EggService:CleanThread()
	if not self.Maid then
		return
	end
	
	self.Maid:Clean()
	
	table.clear(self.Threads)
	table.clear(self.HatchInfo)
	table.clear(self.Maid)
	
	self.HatchInfo = nil
	self.Threads = nil
	self.AnimationIndex = nil
	self.Maid = nil
	self.ParticleHolder = nil
	
	Hatching = false
end

function EggService:RunThread(i)
	local Thread = coroutine.wrap(function()
		self:PlayHatchAnimation(i)
	end)
	
	return Thread, table.insert(self.Threads, Thread)
end

function EggService:HatchEgg(HatchInfo)
	self:CleanThread()
	
	Hatching = true
	
	self.HatchInfo = HatchInfo
	self.Threads = {}
	self.AnimationIndex = 0
	self.Maid = MaidClass.new()

	local Pets = HatchInfo.Pets or {}
	
	for _, Pet in Pets do
		if HatchInfo.ContainsSecret then
			break
		end
		
		local Rarity = PetModule[Pet.Name].Rarity
		
		if (Rarity ~= "Secret") and (Rarity ~= "Mystic") then
			continue
		end
		
		HatchInfo.ContainsSecret = true
		HatchInfo.Speed = 1
	end

	for i = 1, #Pets do
		self:RunThread(i)()
	end
end

function EggService:IsHatching()
	return Hatching
end

function EggService:DisplayHatch(PlayerName, PetName, PetMutation, PetChance, Global)
	local PetData = PetModule[PetName]
	local PetRarity = PetData.Rarity
	
	local RarityColors = {
		["Legendary"] = "Cyan",
		["Exclusive"] = "Blue",
		["Secret"] = "Red",
		["Mystic"] = "Purple"
	}
	
	local Color = RarityColors[PetRarity] or "Cyan"
	
	local RichText = RichTextService.new {
		StringTransformer = ApplyWordColor,
		DefaultColor = "White"
	}
	
	if Global then
		RichText:AddSection("[Global]: ")
	else
		RichText:AddSection("[Server]: ")
	end
	
	if (PetRarity == "Mystic") then
		RichText:AddSection("WOAH! ", "Purple")
	end
	
	RichText:AddSection(("%s "):format(PlayerName), "Light Blue")
	RichText:AddSection("just hatched a")
	
	local isMutated = (PetMutation ~= 0)
	local RarityColor = isMutated and Color3.fromRGB(0, 255, 140) or Color
	
	local MutationMulti = (PetMutation == 1) and 500 or 1000
	
	PetChance = isMutated and (PetChance / MutationMulti) or PetChance
	
	PetChance = "1 in " .. Short:Format(
		(1 / PetChance) * 100
	);

	RichText:AddSection(("%s%s '%s' (%s)"):format(
		isMutated and " " .. ((PetMutation == 1) and ("Mutated I") or ("Mutated II")) .. " " or " ", 
		PetRarity, 
		PetName, 
		PetChance), RarityColor
	)
	
	RichText:AddSection("!")

	TextChatService.TextChannels:FindFirstChild("RBXGeneral"):DisplaySystemMessage(RichText.Message)
	
	RichText:Destroy()
end

function EggService:Initialize()
	if RunService:IsServer() then
		return self
	end
	
	Network:Bind("DisplayHatch", function(...)
		self:DisplayHatch(...)
	end)
	
	Network:Bind("HatchEggClient", function(...)
		self:HatchEgg(...)
	end)
	
	return self
end

return EggService:Initialize()
