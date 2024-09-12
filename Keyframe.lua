-------------------------- Framework --------------------------

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Camera = workspace.CurrentCamera
local Terrain = workspace.Terrain

-------------------------- Framework --------------------------

---------------------- Services ----------------------
local TweenService = game:GetService("TweenService")

local Network = Services:GetService("Network")
local MaidClass = Services:GetService("MaidClass")
local math = Services:GetService("MathUtility")
local GuiService = Services:GetService("GuiService")

local MainGui = GuiService.MainGui

---------------------- Services ----------------------

local KeyframeService = {}
KeyframeService.__index = KeyframeService

function KeyframeService:Destroy()
	if self.RenderFrames then
		self.RenderFrames:Disconnect()
	end

	if self.Placeholder then
		self.Placeholder:Destroy()
	end
	
	table.clear(self)
end

function KeyframeService:GetTimeFrame()
	return tick() - self.Start
end

function KeyframeService:GetOrigins(iteration)
	local Timeframe = self:GetTimeFrame()
	local Keyframes = self.Keyframes
	local Keyframe = Keyframes[iteration]

	local kTimeframes = Keyframe.Timeframes
		
	for i = 1, #kTimeframes do
		local Key1 = kTimeframes[i]
		local Key2 = kTimeframes[i + 1]

		if not Key2 then
			return
		end

		if Key1.Timeframe <= Timeframe and Key2.Timeframe >= Timeframe then
			return Key1, Key2
		end
	end
end

function KeyframeService:Render(iteration)
	local Timeframe = self:GetTimeFrame()
	local Key1, Key2 = self:GetOrigins(iteration)
	local Keyframe = self.Keyframes[iteration]
	
	if not Key1 or not Key2 then
		return self:Destroy()
	end
	
	local Object = Keyframe.Object
	
	local Targets = {
		
	}
	
	for Property, Value in Key1.Properties do
		Targets[Property] = {Value}
	end
	
	for Property, Value in Key2.Properties do
		if not Targets[Property] then
			continue
		end
		
		table.insert(
			Targets[Property],
			Value
		)
	end
	
	for Property, Values in Targets do
		local Time = (Timeframe - Key1.Timeframe) / (Key2.Timeframe - Key1.Timeframe)
		
		local Value = TweenService:GetValue(
			math.min(Time, 1), 
			Enum.EasingStyle.Sine, 
			Enum.EasingDirection.Out
		)
		
		if typeof(Values[1]) == "UDim2" then
			local X = math.Lerp(
				Values[1].X.Scale,
				Values[2].X.Scale,
				Value
			)
			
			local Y = math.Lerp(
				Values[1].Y.Scale,
				Values[2].Y.Scale,
				Value
			)
			
			Object[Property] = UDim2.new(
				X,
				0,
				Y,
				0
			)	
			
			continue
		elseif typeof(Values[1]) == "number" then
			Object[Property] = math.Lerp(
				Values[1],
				Values[2],
				Value
			)
			
			continue
		end
		
		Object[Property] = math.Lerp(
			Values[1],
			Values[2],
			Time
		)
	end
	
	table.clear(Targets)
end

function KeyframeService.new(Pos, ...)
	local self = setmetatable({}, KeyframeService)
	
	self.Start = tick()
	self.Keyframes = {...}
	
	local Placeholder = Instance.new("Frame", MainGui)
	Placeholder.Name = "Keyframe_Placeholder"
	Placeholder.BackgroundTransparency = 1
	Placeholder.AnchorPoint = Vector2.one / 2
	Placeholder.Position = UDim2.fromScale(.5, .5)
	Placeholder.Size = UDim2.fromScale(1, 1)
	
	self.Placeholder = Placeholder
	
	for _, Keyframe in self.Keyframes do
		local Object = Keyframe.Object
		
		if not Object then
			continue
		end
		
		Object.Parent = Placeholder
	end
	
	self.RenderFrames = RunService.RenderStepped:Connect(function()
		if typeof(Pos) == "Instance" then
			local Location = Camera:WorldToScreenPoint(Pos.Position)
			
			Placeholder.Position = UDim2.fromOffset(
				Location.X,
				Location.Y
			)
		else
			Placeholder.Position = Pos or UDim2.fromScale(.5, .5)
		end
		
		for i, Keyframe in self.Keyframes do
			self:Render(i)
		end
	end)
	
	return self
end

return KeyframeService
