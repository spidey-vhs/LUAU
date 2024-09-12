local Players = game:GetService("Players")

local InputManager = {
	Functions = {},
	States = {},
	
	LatencyEnabled = false,
	Latency = 0,
}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

function InputManager:SetLatency(Latency)
	self.LatencyEnabled = Latency and true or false
	self.Latency = Latency or 0
end

function InputManager:DisconnectState(Tag)
	self.States[Tag] = nil
end

function InputManager.new(Tag, Keybind, InputType, gpe, Callback)
	local self = InputManager

	if not Keybind then
		self.Functions[Tag] = nil
		self.States[Tag] = nil

		return
	end

	self.States[Tag] = nil

	self.Functions[Tag] = {
		Keybind = Keybind,
		Callback = Callback,
		InputType = InputType,
		gpe = gpe
	}
end

function InputManager:GetKeybinds(Keybind)
	local Keys = {}
	
	for i, v in pairs(self.Functions) do
		
		if Keybind.KeyCode == v.Keybind or Keybind.UserInputType == v.Keybind then
			Keys[i] = v
		end

	end
	
	return Keys
end

function InputManager:CreateInputs()
	
	if not RunService:IsClient() then
		return
	end
	
	if self.Initialized then
		return
	end
	
	self.Initialized = true
	
	UserInputService.InputBegan:Connect(function(Input, gpe)	

		for i, v in self:GetKeybinds(Input) do
			
			if v.gpe and gpe then
				continue
			end
			
			if self.LatencyEnabled then
				task.wait(self.Latency)
			end

			if v.InputType == "Hold" then
				self.States[i] = true
			end
			
			if v.InputType == "Connect" then
				v.Callback()
			end
		end
		
	end)
	
	UserInputService.InputEnded:Connect(function(Input, gpe)
		for i, v in self:GetKeybinds(Input) do
			
			if v.gpe and gpe then
				continue
			end
			
			if self.LatencyEnabled then
				task.wait(self.Latency)
			end
			
			if v.InputType == "Hold" then
				self.States[i] = nil
			end
			
			if v.InputType == "Disconnect" then
				v.Callback()
			end
		end
	end)
	
	RunService.RenderStepped:Connect(function()
		for i, v in self.Functions do
			if not self.States[i] then
				continue
			end

			v.Callback()
		end
	end)

end

InputManager:CreateInputs()

return InputManager
